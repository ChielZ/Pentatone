//
//  PolyphonicVoice.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AVFAudio
import DunneAudioKit

// MARK: - Detune Mode

/// Defines how stereo spread is calculated
enum DetuneMode: String, CaseIterable {
    case proportional  // Constant cents (natural, more beating at higher pitches)
    case constant      // Constant Hz (uniform beating across all pitches)
    
    var displayName: String {
        switch self {
        case .proportional: return "Proportional (Cents)"
        case .constant: return "Constant (Hz)"
        }
    }
    
    var description: String {
        switch self {
        case .proportional: return "More beating at higher notes (natural)"
        case .constant: return "Same beat rate for all notes (uniform)"
        }
    }
}

/// A single voice in the polyphonic synthesizer with stereo dual-oscillator architecture
/// Signal path: [Osc Left (hard L) + Osc Right (hard R)] → Stereo Mixer → Filter → Envelope
final class PolyphonicVoice {
    
    // MARK: - Audio Nodes
    
    /// Left oscillator (will be panned hard left)
    let oscLeft: FMOscillator
    
    /// Right oscillator (will be panned hard right)
    let oscRight: FMOscillator
    
    /// Panner for left oscillator (hard left)
    private let panLeft: Panner
    
    /// Panner for right oscillator (hard right)
    private let panRight: Panner
    
    /// Stereo mixer to combine panned oscillators
    private let stereoMixer: Mixer
    
    /// Low-pass filter processing the stereo signal
    let filter: KorgLowPassFilter
    
    /// Amplitude envelope shaping the stereo signal
    let envelope: AmplitudeEnvelope
    
    // MARK: - Voice State
    
    /// Whether this voice is available for allocation
    var isAvailable: Bool = true
    
    /// The current base frequency (center frequency between left and right oscillators)
    private(set) var currentFrequency: Double = 400.0
    
    /// Timestamp when this voice was last triggered (for voice stealing)
    private(set) var triggerTime: Date = Date()
    
    /// Whether the voice has been initialized (oscillators started)
    private var isInitialized: Bool = false
    
    // MARK: - Parameters
    
    /// Detune mode determines how stereo spread is calculated
    var detuneMode: DetuneMode = .proportional {
        didSet {
            if isInitialized {
                updateOscillatorFrequencies()
            }
        }
    }
    
    /// Frequency offset for PROPORTIONAL mode (multiplier)
    /// 1.0 = no offset (both oscillators at same frequency)
    /// 1.01 = ±17 cents (34 cents total spread)
    /// Left oscillator multiplies by this value, right divides by it
    var frequencyOffsetRatio: Double = 1.0 {
        didSet {
            if isInitialized && detuneMode == .proportional {
                updateOscillatorFrequencies()
            }
        }
    }
    
    /// Frequency offset for CONSTANT mode (Hz)
    /// 0 Hz = no offset (mono)
    /// 2 Hz = 4 Hz beat rate (2 Hz each side)
    /// 5 Hz = 10 Hz beat rate (5 Hz each side)
    /// Left oscillator adds this value, right subtracts it
    var frequencyOffsetHz: Double = 0.0 {
        didSet {
            if isInitialized && detuneMode == .constant {
                updateOscillatorFrequencies()
            }
        }
    }
    
    // DEPRECATED: Use frequencyOffsetRatio or frequencyOffsetHz depending on mode
    @available(*, deprecated, renamed: "frequencyOffsetRatio")
    var frequencyOffset: Double {
        get { frequencyOffsetRatio }
        set { frequencyOffsetRatio = newValue }
    }
    
    // MARK: - Modulation (Phase 5 - placeholder)
    
    /// Per-voice LFO (will be implemented in Phase 5)
    var voiceLFO: LFOModulator = .default
    
    // MARK: - Initialization
    
    init(parameters: VoiceParameters = .default) {
        // Create left oscillator
        self.oscLeft = FMOscillator(
            waveform: parameters.oscillator.waveform.makeTable(),
            baseFrequency: AUValue(currentFrequency),
            carrierMultiplier: AUValue(parameters.oscillator.carrierMultiplier),
            modulatingMultiplier: AUValue(parameters.oscillator.modulatingMultiplier),
            modulationIndex: AUValue(parameters.oscillator.modulationIndex),
            amplitude: AUValue(parameters.oscillator.amplitude)
        )
        
        // Create right oscillator (identical parameters, different frequency offset)
        self.oscRight = FMOscillator(
            waveform: parameters.oscillator.waveform.makeTable(),
            baseFrequency: AUValue(currentFrequency),
            carrierMultiplier: AUValue(parameters.oscillator.carrierMultiplier),
            modulatingMultiplier: AUValue(parameters.oscillator.modulatingMultiplier),
            modulationIndex: AUValue(parameters.oscillator.modulationIndex),
            amplitude: AUValue(parameters.oscillator.amplitude)
        )
        
        // Pan oscillators hard left and right
        self.panLeft = Panner(oscLeft, pan: -1.0)  // Hard left
        self.panRight = Panner(oscRight, pan: 1.0)  // Hard right
        
        // Create stereo mixer to combine panned oscillators
        self.stereoMixer = Mixer(panLeft, panRight)
        
        // Create filter processing the stereo signal
        self.filter = KorgLowPassFilter(
            stereoMixer,
            cutoffFrequency: AUValue(parameters.filter.clampedCutoff),
            resonance: AUValue(parameters.filter.resonance)
        )
        
        // Create envelope shaping the stereo signal
        self.envelope = AmplitudeEnvelope(
            filter,
            attackDuration: AUValue(parameters.envelope.attackDuration),
            decayDuration: AUValue(parameters.envelope.decayDuration),
            sustainLevel: AUValue(parameters.envelope.sustainLevel),
            releaseDuration: AUValue(parameters.envelope.releaseDuration)
        )
    }
    
    // MARK: - Initialization
    
    /// Initializes the voice (starts oscillators)
    /// Must be called after audio engine is started but before first use
    func initialize() {
        guard !isInitialized else { return }
        
        // Set ramp duration to 0 for instant frequency changes (no pitch sliding)
        oscLeft.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
        oscRight.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
        
        // Also disable ramping for other parameters to ensure instant response
        oscLeft.$amplitude.ramp(to: oscLeft.amplitude, duration: 0)
        oscRight.$amplitude.ramp(to: oscRight.amplitude, duration: 0)
        
        oscLeft.start()
        oscRight.start()
        isInitialized = true
        
        // Apply initial frequency with offset
        updateOscillatorFrequencies()
    }
    
    // MARK: - Frequency Control
    
    /// Sets the base frequency for this voice
    /// Automatically applies stereo offset (left higher, right lower)
    func setFrequency(_ baseFrequency: Double) {
        currentFrequency = baseFrequency
        
        if isInitialized {
            updateOscillatorFrequencies()
        }
    }
    
    /// Updates oscillator frequencies with symmetric offset
    /// Supports both proportional (cents) and constant (Hz) detune modes
    private func updateOscillatorFrequencies() {
        let leftFreq: Double
        let rightFreq: Double
        
        switch detuneMode {
        case .proportional:
            // Constant cents: higher notes beat faster (natural)
            // Formula: left = freq × ratio, right = freq ÷ ratio
            leftFreq = currentFrequency * frequencyOffsetRatio
            rightFreq = currentFrequency / frequencyOffsetRatio
            
        case .constant:
            // Constant Hz: all notes beat at same rate (uniform)
            // Formula: left = freq + Hz, right = freq - Hz
            leftFreq = currentFrequency + frequencyOffsetHz
            rightFreq = currentFrequency - frequencyOffsetHz
        }
        
        // Apply frequencies with 0 ramp duration for instant pitch changes
        oscLeft.$baseFrequency.ramp(to: Float(leftFreq), duration: 0)
        oscRight.$baseFrequency.ramp(to: Float(rightFreq), duration: 0)
    }
    
    // MARK: - Triggering
    
    /// Triggers this voice (starts envelope attack)
    func trigger() {
        guard isInitialized else {
            assertionFailure("Voice must be initialized before triggering")
            return
        }
        
        envelope.reset()
        envelope.openGate()
        isAvailable = false
        triggerTime = Date()
    }
    
    /// Releases this voice (starts envelope release)
    /// The voice will be marked available after the release duration
    func release() {
        envelope.closeGate()
        
        // Mark voice available after release completes
        let releaseTime = envelope.releaseDuration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
            await MainActor.run {
                self.isAvailable = true
            }
        }
    }
    
    // MARK: - Parameter Updates
    
    /// Updates oscillator parameters
    func updateOscillatorParameters(_ parameters: OscillatorParameters) {
        oscLeft.carrierMultiplier = AUValue(parameters.carrierMultiplier)
        oscLeft.modulatingMultiplier = AUValue(parameters.modulatingMultiplier)
        oscLeft.modulationIndex = AUValue(parameters.modulationIndex)
        oscLeft.amplitude = AUValue(parameters.amplitude)
        
        oscRight.carrierMultiplier = AUValue(parameters.carrierMultiplier)
        oscRight.modulatingMultiplier = AUValue(parameters.modulatingMultiplier)
        oscRight.modulationIndex = AUValue(parameters.modulationIndex)
        oscRight.amplitude = AUValue(parameters.amplitude)
        
        // Note: Waveform changes require recreation (not supported dynamically)
    }
    
    /// Updates filter parameters
    func updateFilterParameters(_ parameters: FilterParameters) {
        filter.cutoffFrequency = AUValue(parameters.clampedCutoff)
        filter.resonance = AUValue(parameters.resonance)
    }
    
    /// Updates envelope parameters
    func updateEnvelopeParameters(_ parameters: EnvelopeParameters) {
        envelope.attackDuration = AUValue(parameters.attackDuration)
        envelope.decayDuration = AUValue(parameters.decayDuration)
        envelope.sustainLevel = AUValue(parameters.sustainLevel)
        envelope.releaseDuration = AUValue(parameters.releaseDuration)
    }
    
    // MARK: - Modulation Application (Phase 5)
    
    /// Applies modulation from LFOs and envelopes
    /// Will be implemented in Phase 5
    func applyModulation(globalLFOValue: Double) {
        // TODO: Phase 5 - Implement modulation application
        // Will read voiceLFO.currentValue() and combine with globalLFOValue
        // Then apply to appropriate destinations (filter cutoff, etc.)
    }
}
