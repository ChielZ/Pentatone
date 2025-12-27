//
//  A2 PolyphonicVoice.swift
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
    var frequencyOffsetRatio: Double = 1.003 {
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
    
    // MARK: - Modulation (Phase 5 - placeholder)
    
    /// Modulation parameters for this voice (Phase 5)
    var voiceModulation: VoiceModulationParameters = .default
    
    /// Modulation runtime state (Phase 5)
    var modulationState: ModulationState = ModulationState()
    
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
        
        // Apply base values that were set by initial touch in MainKeyboardView
        // These were already applied at zero-latency in handleTouchBegan()
        // Apply them again here with zero-duration ramps to ensure no ramping artifacts
        oscLeft.$amplitude.ramp(to: AUValue(modulationState.baseAmplitude), duration: 0)
        oscRight.$amplitude.ramp(to: AUValue(modulationState.baseAmplitude), duration: 0)
        filter.$cutoffFrequency.ramp(to: AUValue(modulationState.baseFilterCutoff), duration: 0)
        
        envelope.reset()
        envelope.openGate()
        isAvailable = false
        triggerTime = Date()
        
        // Phase 5: Initialize modulation state
        // Note: voiceLFOPhase is only reset if LFO reset mode is .trigger or .sync
        let shouldResetLFO = voiceModulation.voiceLFO.resetMode != .free
        modulationState.reset(frequency: currentFrequency, touchX: 0.5, resetLFOPhase: shouldResetLFO)
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
    
    /// Applies modulation from envelopes and LFOs (Phase 5B + 5C)
    /// This method is called from the control-rate timer (200 Hz)
    /// - Parameters:
    ///   - globalLFOValue: Current value from global LFO (Phase 5C)
    ///   - globalLFODestination: Destination for global LFO modulation
    ///   - deltaTime: Time since last update (typically 0.005 seconds at 200 Hz)
    ///   - currentTempo: Current tempo in BPM for tempo sync (Phase 5C)
    func applyModulation(
        globalLFOValue: Double,
        globalLFODestination: ModulationDestination,
        deltaTime: Double,
        currentTempo: Double = 120.0
    ) {
        // FIRST: Apply base values from touch control (always, even if no modulation)
        // This ensures touch gestures update smoothly at 200 Hz
        // Use zero-duration ramps to avoid AudioKit parameter ramping artifacts
        // NOTE: Only apply base values if touch modulation is NOT handling them
        if !voiceModulation.touchInitial.isEnabled || voiceModulation.touchInitial.destination != .oscillatorAmplitude {
            // Touch modulation not controlling amplitude - apply base value
            oscLeft.$amplitude.ramp(to: AUValue(modulationState.baseAmplitude), duration: 0)
            oscRight.$amplitude.ramp(to: AUValue(modulationState.baseAmplitude), duration: 0)
        }
        
        if !voiceModulation.touchAftertouch.isEnabled || voiceModulation.touchAftertouch.destination != .filterCutoff {
            // Touch modulation not controlling filter - apply base value
            filter.$cutoffFrequency.ramp(to: AUValue(modulationState.baseFilterCutoff), duration: 0)
        }
        
        // Update envelope times
        modulationState.modulatorEnvelopeTime += deltaTime
        modulationState.auxiliaryEnvelopeTime += deltaTime
        
        // Update voice LFO phase (Phase 5C)
        updateVoiceLFOPhase(deltaTime: deltaTime, tempo: currentTempo)
        
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
        
        // Calculate voice LFO value (Phase 5C)
        let voiceLFOValue = voiceModulation.voiceLFO.currentValue(phase: modulationState.voiceLFOPhase)
        
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
        
        // Phase 5C: Apply voice LFO modulation
        if voiceModulation.voiceLFO.isEnabled {
            applyVoiceLFO(value: voiceLFOValue)
        }
        
        // Phase 5C: Apply global LFO modulation (passed from VoicePool)
        if globalLFOValue != 0.0 {
            applyGlobalLFO(value: globalLFOValue, destination: globalLFODestination)
        }
        
        // Phase 5D: Touch modulation
        // NOTE: Initial touch is now applied at trigger time in MainKeyboardView
        // Only aftertouch runs here at control rate
        
        // Apply aftertouch on every frame (it changes continuously)
        if voiceModulation.touchAftertouch.isEnabled {
            applyTouchAftertouch()
        }
        
        // Phase 5D: Key tracking modulation
        if voiceModulation.keyTracking.isEnabled {
            applyKeyTracking()
        }
    }
    
    // MARK: - Voice LFO Phase Update (Phase 5C)
    
    /// Updates the voice LFO phase based on time and tempo
    private func updateVoiceLFOPhase(deltaTime: Double, tempo: Double) {
        guard voiceModulation.voiceLFO.isEnabled else { return }
        
        let lfo = voiceModulation.voiceLFO
        
        // Calculate phase increment based on frequency mode
        let phaseIncrement: Double
        
        switch lfo.frequencyMode {
        case .hertz:
            // Direct Hz: phase increment = frequency * deltaTime
            phaseIncrement = lfo.frequency * deltaTime
            
        case .tempoSync:
            // Tempo sync: lfo.frequency is a tempo multiplier
            // e.g., 1.0 = quarter note, 2.0 = eighth note, 0.5 = half note
            let beatsPerSecond = tempo / 60.0
            let cyclesPerSecond = beatsPerSecond * lfo.frequency
            phaseIncrement = cyclesPerSecond * deltaTime
        }
        
        // Update phase based on reset mode
        switch lfo.resetMode {
        case .free:
            // Free running: just increment and wrap
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
            
        case .trigger:
            // Trigger reset: phase was reset to 0 in trigger(), now just increment
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
            
        case .sync:
            // Tempo sync: same as trigger but could be reset by external clock
            // For now, just increment (external sync will be added later if needed)
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
        }
    }
    
    /// Applies the auxiliary envelope to its routed destination
    private func applyAuxiliaryEnvelope(value: Double) {
        let destination = voiceModulation.auxiliaryEnvelope.destination
        let amount = voiceModulation.auxiliaryEnvelope.amount
        
        // Only apply to voice-level destinations
        guard destination.isVoiceLevel else { return }
        
        // Get base value
        let baseValue = getBaseValue(for: destination)
        
        // Calculate modulated value
        let modulated = ModulationRouter.applyEnvelopeModulation(
            baseValue: baseValue,
            envelopeValue: value,
            amount: amount,
            destination: destination
        )
        
        // Apply using centralized method (with zero-duration ramps)
        applyModulatedValue(modulated, to: destination)
    }
    
    // MARK: - Voice LFO Application (Phase 5C)
    
    /// Applies the voice LFO to its routed destination
    /// Voice LFO provides per-voice modulation (each voice has independent phase)
    private func applyVoiceLFO(value: Double) {
        let destination = voiceModulation.voiceLFO.destination
        
        // Only apply to voice-level destinations
        guard destination.isVoiceLevel else { return }
        
        // Get base value
        let baseValue = getBaseValue(for: destination)
        
        // Apply LFO modulation
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: value,
            destination: destination
        )
        
        // Apply using centralized method (with zero-duration ramps)
        applyModulatedValue(modulated, to: destination)
    }
    
    // MARK: - Global LFO Application (Phase 5C)
    
    /// Applies the global LFO to its routed destination
    /// Global LFO is calculated in VoicePool and passed to all voices
    /// This enables synchronized modulation across all voices
    /// - Parameters:
    ///   - value: The current global LFO value (-1.0 to +1.0, scaled by amount)
    ///   - destination: The destination parameter to modulate
    private func applyGlobalLFO(value: Double, destination: ModulationDestination) {
        // Only apply to voice-level destinations
        // (Global-level destinations are handled by VoicePool directly)
        guard destination.isVoiceLevel else { return }
        
        // Get base value
        let baseValue = getBaseValue(for: destination)
        
        // Apply LFO modulation
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: value,
            destination: destination
        )
        
        // Apply using centralized method (with zero-duration ramps)
        applyModulatedValue(modulated, to: destination)
    }
    
    // MARK: - Touch Modulation (Phase 5D)
    
    // NOTE: Initial touch is now applied at trigger time in MainKeyboardView
    // This provides zero-latency response for note-on attributes
    
    /// Applies aftertouch X movement as a modulation source
    /// Aftertouch tracks the change in X position while key is held
    /// This provides bipolar modulation (oscillates around center)
    private func applyTouchAftertouch() {
        let params = voiceModulation.touchAftertouch
        let destination = params.destination
        
        // Only apply to voice-level destinations
        guard destination.isVoiceLevel else { return }
        
        // Calculate aftertouch delta from initial position
        // This gives us a bipolar value: negative = moved left, positive = moved right
        let initialX = modulationState.initialTouchX
        let currentX = modulationState.currentTouchX
        let aftertouchDelta = currentX - initialX  // Range: -1.0 to +1.0
        
        // Scale the delta by the amount parameter
        let scaledValue = aftertouchDelta * params.amount
        
        // Get the base value for the destination
        let baseValue = getBaseValue(for: destination)
        
        // Apply aftertouch modulation using LFO logic (bipolar)
        let targetValue = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: scaledValue,
            destination: destination
        )
        
        // Apply smoothing for filter cutoff destination
        let finalValue: Double
        if destination == .filterCutoff {
            // Get current smoothed value
            let currentValue = modulationState.lastSmoothedFilterCutoff ?? targetValue
            
            // Apply linear interpolation (lerp)
            let smoothingFactor = modulationState.filterSmoothingFactor
            let interpolationAmount = 1.0 - smoothingFactor
            finalValue = currentValue + (targetValue - currentValue) * interpolationAmount
            
            // Store for next iteration
            modulationState.lastSmoothedFilterCutoff = finalValue
        } else {
            // No smoothing for other destinations
            finalValue = targetValue
        }
        
        // Apply the modulated value
        applyModulatedValue(finalValue, to: destination)
    }
    
    /// Applies key tracking (frequency-based modulation)
    /// Higher notes produce higher modulation values
    private func applyKeyTracking() {
        let params = voiceModulation.keyTracking
        let destination = params.destination
        
        // Only apply to voice-level destinations
        guard destination.isVoiceLevel else { return }
        
        // Calculate tracking value from current frequency
        let trackingValue = params.trackingValue(forFrequency: modulationState.currentFrequency)
        
        // Get the base value for the destination
        let baseValue = getBaseValue(for: destination)
        
        // Apply key tracking using envelope modulation logic (unipolar)
        let modulated = ModulationRouter.applyEnvelopeModulation(
            baseValue: baseValue,
            envelopeValue: trackingValue,
            amount: params.amount,
            destination: destination
        )
        
        // Apply the modulated value
        applyModulatedValue(modulated, to: destination)
    }
    
    // MARK: - Touch Modulation Helpers
    
    /// Gets the base value for a modulation destination
    /// Uses user-controlled values for amplitude/filter, current values for others
    private func getBaseValue(for destination: ModulationDestination) -> Double {
        switch destination {
        case .modulationIndex:
            return Double(oscLeft.modulationIndex)
            
        case .filterCutoff:
            // Use user-controlled base value from modulation state
            return modulationState.baseFilterCutoff
            
        case .oscillatorAmplitude:
            // Use user-controlled base value from modulation state
            return modulationState.baseAmplitude
            
        case .oscillatorBaseFrequency:
            return currentFrequency
            
        case .modulatingMultiplier:
            return Double(oscLeft.modulatingMultiplier)
            
        case .stereoSpreadAmount:
            return detuneMode == .proportional ? frequencyOffsetRatio : frequencyOffsetHz
            
        case .voiceLFOFrequency:
            return voiceModulation.voiceLFO.frequency
            
        case .voiceLFOAmount:
            return voiceModulation.voiceLFO.amount
            
        case .delayTime, .delayMix:
            // These are global-level, shouldn't be reached
            return 0.0
        }
    }
    
    /// Applies a modulated value to a destination parameter
    private func applyModulatedValue(_ value: Double, to destination: ModulationDestination) {
        // Validate value is not NaN or infinite
        guard value.isFinite else {
            print("⚠️ Invalid modulation value: \(value) for destination \(destination)")
            return
        }
        
        switch destination {
        case .modulationIndex:
            let clamped = max(0.0, min(10.0, value))
            oscLeft.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
            oscRight.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
            
        case .filterCutoff:
            // Clamp to safe range for AudioKit (20 Hz - 20 kHz)
            let clamped = max(20.0, min(20000.0, value))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
            
        case .oscillatorAmplitude:
            let clamped = max(0.0, min(1.0, value))
            oscLeft.$amplitude.ramp(to: AUValue(clamped), duration: 0)
            oscRight.$amplitude.ramp(to: AUValue(clamped), duration: 0)
            
        case .oscillatorBaseFrequency:
            currentFrequency = value
            updateOscillatorFrequencies()
            
        case .modulatingMultiplier:
            let clamped = max(0.1, min(20.0, value))
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(clamped), duration: 0)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(clamped), duration: 0)
            
        case .stereoSpreadAmount:
            if detuneMode == .proportional {
                frequencyOffsetRatio = value
            } else {
                frequencyOffsetHz = value
            }
            
        case .voiceLFOFrequency:
            // Modulate the voice LFO frequency
            voiceModulation.voiceLFO.frequency = max(0.01, min(10.0, value))
            
        case .voiceLFOAmount:
            // Modulate the voice LFO amount
            voiceModulation.voiceLFO.amount = max(0.0, min(1.0, value))
            
        case .delayTime, .delayMix:
            // These are global-level, handled elsewhere
            break
        }
    }
}
