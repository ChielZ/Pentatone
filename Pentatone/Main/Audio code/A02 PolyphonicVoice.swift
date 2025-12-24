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
    var detuneMode: DetuneMode = .constant {
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
    var frequencyOffsetRatio: Double = 1.004 {
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
    var frequencyOffsetHz: Double = 1.5 {
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
    
    /// Modulation parameters for this voice (Phase 5)
    var voiceModulation: VoiceModulationParameters = .default
    
    /// Modulation runtime state (Phase 5)
    var modulationState: ModulationState = ModulationState()
    
    // DEPRECATED: Use voiceModulation.voiceLFO
    @available(*, deprecated, renamed: "voiceModulation")
    var voiceLFO: LFOParameters {
        get { voiceModulation.voiceLFO }
        set { voiceModulation.voiceLFO = newValue }
    }
    
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
            resonance: AUValue(parameters.filter.clampedResonance),
            saturation: AUValue(parameters.filter.clampedSaturation)
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
        
        // Phase 5: Initialize modulation state
        modulationState.reset(frequency: currentFrequency, touchX: 0.5)
    }
    
    /// Releases this voice (starts envelope release)
    /// The voice will be marked available after the release duration
    func release() {
        envelope.closeGate()
        
        // Phase 5B: Capture current envelope values for smooth release
        let modulatorValue = voiceModulation.modulatorEnvelope.currentValue(
            timeInEnvelope: modulationState.modulatorEnvelopeTime,
            isGateOpen: true
        )
        let auxiliaryValue = voiceModulation.auxiliaryEnvelope.currentValue(
            timeInEnvelope: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: true
        )
        modulationState.closeGate(modulatorValue: modulatorValue, auxiliaryValue: auxiliaryValue)
        
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
        filter.resonance = AUValue(parameters.clampedResonance)
        filter.saturation = AUValue(parameters.clampedSaturation)
    }
    
    /// Updates envelope parameters
    func updateEnvelopeParameters(_ parameters: EnvelopeParameters) {
        envelope.attackDuration = AUValue(parameters.attackDuration)
        envelope.decayDuration = AUValue(parameters.decayDuration)
        envelope.sustainLevel = AUValue(parameters.sustainLevel)
        envelope.releaseDuration = AUValue(parameters.releaseDuration)
    }
    
    /// Updates modulation parameters (Phase 5)
    func updateModulationParameters(_ parameters: VoiceModulationParameters) {
        voiceModulation = parameters
        // Note: Runtime state (modulationState) is not reset here
        // It continues tracking from current position
    }
    
    // MARK: - Modulation Application (Phase 5B)
    
    /// Applies modulation from envelopes (Phase 5B)
    /// This method is called from the control-rate timer (200 Hz)
    /// - Parameters:
    ///   - globalLFOValue: Current value from global LFO (Phase 5C)
    ///   - deltaTime: Time since last update (typically 0.005 seconds at 200 Hz)
    func applyModulation(globalLFOValue: Double, deltaTime: Double) {
        // Update envelope times
        modulationState.modulatorEnvelopeTime += deltaTime
        modulationState.auxiliaryEnvelopeTime += deltaTime
        
        // Calculate envelope values
        let modulatorValue: Double
        let auxiliaryValue: Double
        
        if modulationState.isGateOpen {
            // Gate open: use normal envelope calculation
            modulatorValue = voiceModulation.modulatorEnvelope.currentValue(
                timeInEnvelope: modulationState.modulatorEnvelopeTime,
                isGateOpen: true
            )
            
            auxiliaryValue = voiceModulation.auxiliaryEnvelope.currentValue(
                timeInEnvelope: modulationState.auxiliaryEnvelopeTime,
                isGateOpen: true
            )
        } else {
            // Gate closed: use release calculation from captured level
            modulatorValue = voiceModulation.modulatorEnvelope.releaseValue(
                timeInRelease: modulationState.modulatorEnvelopeTime,
                fromLevel: modulationState.modulatorSustainLevel
            )
            
            auxiliaryValue = voiceModulation.auxiliaryEnvelope.releaseValue(
                timeInRelease: modulationState.auxiliaryEnvelopeTime,
                fromLevel: modulationState.auxiliarySustainLevel
            )
        }
        
        // Apply modulator envelope to modulationIndex (hardwired)
        if voiceModulation.modulatorEnvelope.isEnabled {
            let baseModIndex = 0.0  // Always start from 0 for modulator envelope
            
            let modulatedIndex = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseModIndex,
                envelopeValue: modulatorValue,
                amount: voiceModulation.modulatorEnvelope.amount,
                destination: .modulationIndex
            )
            
            // Apply to both oscillators (stereo voice)
            oscLeft.modulationIndex = AUValue(modulatedIndex)
            oscRight.modulationIndex = AUValue(modulatedIndex)
        }
        
        // Apply auxiliary envelope to its routed destination
        if voiceModulation.auxiliaryEnvelope.isEnabled {
            applyAuxiliaryEnvelope(value: auxiliaryValue)
        }
        
        // Phase 5C: LFO modulation will be added here
        // Phase 5D: Touch/key tracking will be added here
    }
    
    /// Applies the auxiliary envelope to its routed destination
    private func applyAuxiliaryEnvelope(value: Double) {
        let destination = voiceModulation.auxiliaryEnvelope.destination
        let amount = voiceModulation.auxiliaryEnvelope.amount
        
        // Only apply to voice-level destinations
        guard destination.isVoiceLevel else { return }
        
        switch destination {
        case .modulationIndex:
            // If user routes auxiliary envelope to modIndex too
            let baseValue = Double(oscLeft.modulationIndex)
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            oscLeft.modulationIndex = AUValue(modulated)
            oscRight.modulationIndex = AUValue(modulated)
            
        case .filterCutoff:
            // Get current filter cutoff as base
            let baseValue = Double(filter.cutoffFrequency)
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            filter.cutoffFrequency = AUValue(modulated)
            
        case .oscillatorAmplitude:
            // Modulate amplitude
            let baseValue = Double(oscLeft.amplitude)
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            oscLeft.amplitude = AUValue(modulated)
            oscRight.amplitude = AUValue(modulated)
            
        case .oscillatorBaseFrequency:
            // Modulate frequency (vibrato/pitch envelope)
            let baseValue = modulationState.currentFrequency
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            // Update frequencies with modulation
            currentFrequency = modulated
            updateOscillatorFrequencies()
            
        case .modulatingMultiplier:
            // Modulate FM modulator ratio
            let baseValue = Double(oscLeft.modulatingMultiplier)
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            oscLeft.modulatingMultiplier = AUValue(modulated)
            oscRight.modulatingMultiplier = AUValue(modulated)
            
        case .stereoSpreadAmount:
            // Modulate stereo spread
            // This requires updating the frequency offset
            let baseValue = detuneMode == .proportional ? frequencyOffsetRatio : frequencyOffsetHz
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: value,
                amount: amount,
                destination: destination
            )
            if detuneMode == .proportional {
                frequencyOffsetRatio = modulated
            } else {
                frequencyOffsetHz = modulated
            }
            
        case .voiceLFOFrequency, .voiceLFOAmount:
            // Phase 5C: Will implement LFO meta-modulation
            break
            
        case .delayTime, .delayMix:
            // These are global-level, shouldn't be routed from voice envelope
            break
        }
    }
}
