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
enum DetuneMode: String, CaseIterable, Codable {
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
    var oscLeft: FMOscillator
    
    /// Right oscillator (will be panned hard right)
    var oscRight: FMOscillator
    
    /// Panner for left oscillator (hard left)
    private var panLeft: Panner
    
    /// Panner for right oscillator (hard right)
    private var panRight: Panner
    
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
    var detuneMode: DetuneMode {
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
    var frequencyOffsetRatio: Double {
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
    var frequencyOffsetHz: Double {
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
        // Initialize stereo detune parameters from template
        self.detuneMode = parameters.oscillator.detuneMode
        self.frequencyOffsetRatio = parameters.oscillator.stereoOffsetProportional
        self.frequencyOffsetHz = parameters.oscillator.stereoOffsetConstant
        
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
        
        // Initialize base values in modulation state
        modulationState.baseAmplitude = parameters.oscillator.amplitude
        modulationState.baseFilterCutoff = parameters.filter.clampedCutoff
        modulationState.baseModulationIndex = parameters.oscillator.modulationIndex
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
    
    /// Cleanup method to safely stop and disconnect this voice
    /// Should be called before destroying the voice
    func cleanup() {
        if isInitialized {
            oscLeft.stop()
            oscRight.stop()
            isInitialized = false
        }
        isAvailable = true
    }
    
    // MARK: - Oscillator Recreation
    
    /// Recreates the oscillators with a new waveform while keeping the rest of the voice intact
    /// This allows waveform changes without recreating the entire voice
    /// - Parameter waveform: The new waveform to use
    func recreateOscillators(waveform: OscillatorWaveform) {
        print("🎵 Recreating oscillators for voice with new waveform: \(waveform)")
        
        // Store current state before recreation
        let wasInitialized = isInitialized
        let currentBaseFreq = currentFrequency
        let currentAmplitude = oscLeft.amplitude
        let currentCarrierMult = oscLeft.carrierMultiplier
        let currentModulatingMult = oscLeft.modulatingMultiplier
        let currentModIndex = oscLeft.modulationIndex
        
        // Stop and disconnect old oscillators
        if isInitialized {
            oscLeft.stop()
            oscRight.stop()
        }
        
        // Disconnect old panners from stereo mixer
        stereoMixer.removeInput(panLeft)
        stereoMixer.removeInput(panRight)
        
        // Explicitly detach old panners and oscillators to ensure proper cleanup
        // This helps AudioKit release internal references and prevents memory buildup
        panLeft.detach()
        panRight.detach()
        oscLeft.detach()
        oscRight.detach()
        
        // Create new oscillators with the new waveform
        let newOscLeft = FMOscillator(
            waveform: waveform.makeTable(),
            baseFrequency: AUValue(currentBaseFreq),
            carrierMultiplier: currentCarrierMult,
            modulatingMultiplier: currentModulatingMult,
            modulationIndex: currentModIndex,
            amplitude: currentAmplitude
        )
        
        let newOscRight = FMOscillator(
            waveform: waveform.makeTable(),
            baseFrequency: AUValue(currentBaseFreq),
            carrierMultiplier: currentCarrierMult,
            modulatingMultiplier: currentModulatingMult,
            modulationIndex: currentModIndex,
            amplitude: currentAmplitude
        )
        
        // Create new panners with the new oscillators
        let newPanLeft = Panner(newOscLeft, pan: -1.0)  // Hard left
        let newPanRight = Panner(newOscRight, pan: 1.0)  // Hard right
        
        // Connect new panners to stereo mixer
        stereoMixer.addInput(newPanLeft)
        stereoMixer.addInput(newPanRight)
        
        // Update references (old nodes will now be deallocated by ARC)
        self.oscLeft = newOscLeft
        self.oscRight = newOscRight
        self.panLeft = newPanLeft
        self.panRight = newPanRight
        
        // Reinitialize if the voice was previously initialized
        if wasInitialized {
            // Set ramp duration to 0 for instant parameter changes
            oscLeft.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
            oscRight.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
            oscLeft.$amplitude.ramp(to: currentAmplitude, duration: 0)
            oscRight.$amplitude.ramp(to: currentAmplitude, duration: 0)
            
            // Start new oscillators
            oscLeft.start()
            oscRight.start()
            
            // Restore initialized state
            isInitialized = true
            
            // Apply frequency offsets
            updateOscillatorFrequencies()
            
            print("🎵   Oscillators recreated and restarted")
        } else {
            print("🎵   Oscillators recreated (not yet initialized)")
        }
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
        // Use zero-duration ramps to avoid AudioKit parameter ramping artifacts
        oscLeft.$carrierMultiplier.ramp(to: AUValue(parameters.carrierMultiplier), duration: 0)
        oscLeft.$modulatingMultiplier.ramp(to: AUValue(parameters.modulatingMultiplier), duration: 0)
        oscLeft.$modulationIndex.ramp(to: AUValue(parameters.modulationIndex), duration: 0)
        oscLeft.$amplitude.ramp(to: AUValue(parameters.amplitude), duration: 0)
        
        oscRight.$carrierMultiplier.ramp(to: AUValue(parameters.carrierMultiplier), duration: 0)
        oscRight.$modulatingMultiplier.ramp(to: AUValue(parameters.modulatingMultiplier), duration: 0)
        oscRight.$modulationIndex.ramp(to: AUValue(parameters.modulationIndex), duration: 0)
        oscRight.$amplitude.ramp(to: AUValue(parameters.amplitude), duration: 0)
        
        // Update the base modulation index in modulation state
        // This ensures the modulation system uses the new value as the base
        modulationState.baseModulationIndex = parameters.modulationIndex
        
        // Update stereo spread parameters
        detuneMode = parameters.detuneMode
        frequencyOffsetRatio = parameters.stereoOffsetProportional
        frequencyOffsetHz = parameters.stereoOffsetConstant
        
        // Note: Waveform cannot be changed dynamically in AudioKit's FMOscillator
        // Waveform changes require voice recreation (handled by VoicePool.recreateVoices)
    }
    
   
    /// Updates filter parameters
    func updateFilterParameters(_ parameters: FilterParameters) {
        // Use zero-duration ramps to avoid AudioKit parameter ramping artifacts
        filter.$cutoffFrequency.ramp(to: AUValue(parameters.clampedCutoff), duration: 0)
        filter.$resonance.ramp(to: AUValue(parameters.clampedResonance), duration: 0)
        filter.$saturation.ramp(to: AUValue(parameters.clampedSaturation), duration: 0)
        
        // Update the base filter cutoff in modulation state
        // This ensures the modulation system uses the new value as the base
        modulationState.baseFilterCutoff = parameters.clampedCutoff
    }
    
    /// Updates envelope parameters
    func updateEnvelopeParameters(_ parameters: EnvelopeParameters) {
        // Use zero-duration ramps to avoid AudioKit parameter ramping artifacts
        envelope.$attackDuration.ramp(to: AUValue(parameters.attackDuration), duration: 0)
        envelope.$decayDuration.ramp(to: AUValue(parameters.decayDuration), duration: 0)
        envelope.$sustainLevel.ramp(to: AUValue(parameters.sustainLevel), duration: 0)
        envelope.$releaseDuration.ramp(to: AUValue(parameters.releaseDuration), duration: 0)
    }
    
    /// Updates modulation parameters (Phase 5)
    func updateModulationParameters(_ parameters: VoiceModulationParameters) {
        voiceModulation = parameters
        // Note: Runtime state (modulationState) is not reset here
        // It continues tracking from current position
    }
    
    // MARK: - Modulation Application (Refactored - Fixed Destinations)
    
    /// Applies modulation from all sources with fixed destinations
    /// This method is called from the control-rate timer (200 Hz)
    /// - Parameters:
    ///   - globalLFO: Global LFO parameters with raw value
    ///   - deltaTime: Time since last update (typically 0.005 seconds at 200 Hz)
    ///   - currentTempo: Current tempo in BPM for tempo sync
    func applyModulation(
        globalLFO: (rawValue: Double, parameters: GlobalLFOParameters),
        deltaTime: Double,
        currentTempo: Double = 120.0
    ) {
        // Update envelope times
        modulationState.modulatorEnvelopeTime += deltaTime
        modulationState.auxiliaryEnvelopeTime += deltaTime
        
        // Update voice LFO phase and delay ramp
        updateVoiceLFOPhase(deltaTime: deltaTime, tempo: currentTempo)
        modulationState.updateVoiceLFODelayRamp(
            deltaTime: deltaTime,
            delayTime: voiceModulation.voiceLFO.delayTime
        )
        
        // Calculate envelope values using ModulationRouter
        let modulatorEnvValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: modulationState.isGateOpen,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release,
            capturedLevel: modulationState.modulatorSustainLevel
        )
        
        let auxiliaryEnvValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: modulationState.isGateOpen,
            attack: voiceModulation.auxiliaryEnvelope.attack,
            decay: voiceModulation.auxiliaryEnvelope.decay,
            sustain: voiceModulation.auxiliaryEnvelope.sustain,
            release: voiceModulation.auxiliaryEnvelope.release,
            capturedLevel: modulationState.auxiliarySustainLevel
        )
        
        // Get raw voice LFO value
        let voiceLFORawValue = voiceModulation.voiceLFO.rawValue(at: modulationState.voiceLFOPhase)
        
        // Get key tracking value
        let keyTrackValue = voiceModulation.keyTracking.trackingValue(
            forFrequency: modulationState.currentFrequency
        )
        
        // Get aftertouch delta (bipolar: -1 to +1)
        let aftertouchDelta = modulationState.currentTouchX - modulationState.initialTouchX
        
        // Apply all modulations to their destinations
        applyModulatorEnvelope(envValue: modulatorEnvValue)
        applyAuxiliaryEnvelope(envValue: auxiliaryEnvValue)
        applyVoiceLFO(rawValue: voiceLFORawValue)
        applyGlobalLFO(rawValue: globalLFO.rawValue, parameters: globalLFO.parameters)
        applyKeyTracking(trackingValue: keyTrackValue)
        applyTouchAftertouch(aftertouchDelta: aftertouchDelta)
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
    
    // MARK: - Individual Modulation Application Methods
    
    /// Applies modulator envelope (fixed destination: modulation index)
    private func applyModulatorEnvelope(envValue: Double) {
        // Early exit if no modulation
        guard voiceModulation.modulatorEnvelope.hasActiveDestinations else { return }
        
        let finalModIndex = ModulationRouter.calculateModulationIndex(
            baseModIndex: modulationState.baseModulationIndex,
            modEnvValue: envValue,
            modEnvAmount: voiceModulation.modulatorEnvelope.amountToModulationIndex,
            voiceLFOValue: 0.0,  // Applied separately
            voiceLFOAmount: 0.0,
            voiceLFORampFactor: 0.0,
            aftertouchDelta: 0.0,  // Applied separately
            aftertouchAmount: 0.0
        )
        
        oscLeft.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0)
        oscRight.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0)
    }
    
    /// Applies auxiliary envelope (3 fixed destinations: pitch, filter, vibrato)
    private func applyAuxiliaryEnvelope(envValue: Double) {
        // Early exit if no modulation
        guard voiceModulation.auxiliaryEnvelope.hasActiveDestinations else { return }
        
        let params = voiceModulation.auxiliaryEnvelope
        
        // Destination 1: Oscillator pitch
        if params.amountToOscillatorPitch != 0.0 {
            let finalFreq = ModulationRouter.calculateOscillatorPitch(
                baseFrequency: modulationState.baseFrequency,
                auxEnvValue: envValue,
                auxEnvAmount: params.amountToOscillatorPitch,
                voiceLFOValue: 0.0,  // Applied separately
                voiceLFOAmount: 0.0,
                voiceLFORampFactor: 0.0
            )
            currentFrequency = finalFreq
            updateOscillatorFrequencies()
        }
        
        // Destination 2: Filter frequency
        if params.amountToFilterFrequency != 0.0 {
            // Note: Full filter calculation happens in a combined method
            // This is a simplified version for aux env only
            let auxEnvOctaves = envValue * params.amountToFilterFrequency
            let finalCutoff = modulationState.baseFilterCutoff * pow(2.0, auxEnvOctaves)
            let clamped = max(20.0, min(22050.0, finalCutoff))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 3: Vibrato (meta-modulation of voice LFO pitch amount)
        // This is handled by modifying the voice LFO amount in real-time
        // Will be applied when voice LFO is calculated
    }
    
    /// Applies voice LFO (3 fixed destinations + delay ramp: pitch, filter, modulator level)
    private func applyVoiceLFO(rawValue: Double) {
        // Early exit if no modulation
        guard voiceModulation.voiceLFO.hasActiveDestinations else { return }
        
        let params = voiceModulation.voiceLFO
        let rampFactor = modulationState.voiceLFORampFactor
        
        // Destination 1: Oscillator pitch (vibrato)
        if params.amountToOscillatorPitch != 0.0 {
            // Calculate effective amount (may be modulated by aux env or aftertouch)
            var effectiveAmount = params.amountToOscillatorPitch
            
            // Meta-modulation from aux envelope
            if voiceModulation.auxiliaryEnvelope.amountToVibrato != 0.0 {
                let auxEnvValue = ModulationRouter.calculateEnvelopeValue(
                    time: modulationState.auxiliaryEnvelopeTime,
                    isGateOpen: modulationState.isGateOpen,
                    attack: voiceModulation.auxiliaryEnvelope.attack,
                    decay: voiceModulation.auxiliaryEnvelope.decay,
                    sustain: voiceModulation.auxiliaryEnvelope.sustain,
                    release: voiceModulation.auxiliaryEnvelope.release,
                    capturedLevel: modulationState.auxiliarySustainLevel
                )
                effectiveAmount = ModulationRouter.calculateVoiceLFOPitchAmount(
                    baseAmount: effectiveAmount,
                    auxEnvValue: auxEnvValue,
                    auxEnvAmount: voiceModulation.auxiliaryEnvelope.amountToVibrato,
                    aftertouchDelta: 0.0,  // Applied separately below
                    aftertouchAmount: 0.0
                )
            }
            
            // Meta-modulation from aftertouch
            if voiceModulation.touchAftertouch.amountToVibrato != 0.0 {
                let aftertouchDelta = modulationState.currentTouchX - modulationState.initialTouchX
                effectiveAmount = ModulationRouter.calculateVoiceLFOPitchAmount(
                    baseAmount: effectiveAmount,
                    auxEnvValue: 0.0,
                    auxEnvAmount: 0.0,
                    aftertouchDelta: aftertouchDelta,
                    aftertouchAmount: voiceModulation.touchAftertouch.amountToVibrato
                )
            }
            
            let finalFreq = ModulationRouter.calculateOscillatorPitch(
                baseFrequency: modulationState.baseFrequency,
                auxEnvValue: 0.0,  // Applied separately
                auxEnvAmount: 0.0,
                voiceLFOValue: rawValue,
                voiceLFOAmount: effectiveAmount,
                voiceLFORampFactor: rampFactor
            )
            currentFrequency = finalFreq
            updateOscillatorFrequencies()
        }
        
        // Destination 2: Filter frequency
        if params.amountToFilterFrequency != 0.0 {
            let lfoOctaves = (rawValue * rampFactor) * params.amountToFilterFrequency
            let finalCutoff = modulationState.baseFilterCutoff * pow(2.0, lfoOctaves)
            let clamped = max(20.0, min(22050.0, finalCutoff))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 3: Modulation index
        if params.amountToModulatorLevel != 0.0 {
            let lfoOffset = (rawValue * rampFactor) * params.amountToModulatorLevel
            let finalModIndex = modulationState.baseModulationIndex + lfoOffset
            let clamped = max(0.0, min(10.0, finalModIndex))
            oscLeft.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
            oscRight.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
        }
    }
    
    /// Applies global LFO (4 fixed destinations: amplitude, modulator multiplier, filter, delay time)
    private func applyGlobalLFO(rawValue: Double, parameters: GlobalLFOParameters) {
        // Early exit if no modulation
        guard parameters.hasActiveDestinations else { return }
        
        // Destination 1: Oscillator amplitude (tremolo)
        if parameters.amountToOscillatorAmplitude != 0.0 {
            let finalAmp = ModulationRouter.calculateOscillatorAmplitude(
                baseAmplitude: modulationState.baseAmplitude,
                initialTouchValue: 1.0,  // Already applied at trigger
                initialTouchAmount: 0.0,
                globalLFOValue: rawValue,
                globalLFOAmount: parameters.amountToOscillatorAmplitude
            )
            oscLeft.$amplitude.ramp(to: AUValue(finalAmp), duration: 0)
            oscRight.$amplitude.ramp(to: AUValue(finalAmp), duration: 0)
        }
        
        // Destination 2: Modulator multiplier (FM ratio modulation)
        if parameters.amountToModulatorMultiplier != 0.0 {
            let baseMultiplier = Double(oscLeft.modulatingMultiplier)
            let finalMultiplier = ModulationRouter.calculateModulatorMultiplier(
                baseMultiplier: baseMultiplier,
                globalLFOValue: rawValue,
                globalLFOAmount: parameters.amountToModulatorMultiplier
            )
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0)
        }
        
        // Destination 3: Filter frequency
        if parameters.amountToFilterFrequency != 0.0 {
            let globalLFOOctaves = rawValue * parameters.amountToFilterFrequency
            let finalCutoff = modulationState.baseFilterCutoff * pow(2.0, globalLFOOctaves)
            let clamped = max(20.0, min(22050.0, finalCutoff))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 4: Delay time (handled by VoicePool, not voice-level)
        // This is included here for completeness but won't execute at voice level
    }
    
    /// Applies key tracking (2 fixed destinations: filter frequency, voice LFO frequency)
    private func applyKeyTracking(trackingValue: Double) {
        // Early exit if no modulation
        guard voiceModulation.keyTracking.hasActiveDestinations else { return }
        
        let params = voiceModulation.keyTracking
        
        // Destination 1: Filter frequency (scales envelope/aftertouch modulation)
        if params.amountToFilterFrequency != 0.0 {
            // This is part of the complex filter frequency calculation
            // The full calculation is done in a combined method
            // For now, apply a simple scaling
            let keyTrackFactor = 1.0 + (trackingValue * params.amountToFilterFrequency)
            let finalCutoff = modulationState.baseFilterCutoff * keyTrackFactor
            let clamped = max(20.0, min(22050.0, finalCutoff))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 2: Voice LFO frequency
        if params.amountToVoiceLFOFrequency != 0.0 {
            let finalFreq = ModulationRouter.calculateVoiceLFOFrequency(
                baseFrequency: voiceModulation.voiceLFO.frequency,
                keyTrackValue: trackingValue,
                keyTrackAmount: params.amountToVoiceLFOFrequency
            )
            // Update the voice LFO frequency for next cycle
            voiceModulation.voiceLFO.frequency = finalFreq
        }
    }
    
    /// Applies touch aftertouch (3 fixed destinations: filter, modulator level, vibrato)
    private func applyTouchAftertouch(aftertouchDelta: Double) {
        // Early exit if no modulation
        guard voiceModulation.touchAftertouch.hasActiveDestinations else { return }
        
        let params = voiceModulation.touchAftertouch
        
        // Destination 1: Filter frequency
        if params.amountToFilterFrequency != 0.0 {
            let aftertouchOctaves = aftertouchDelta * params.amountToFilterFrequency
            let targetCutoff = modulationState.baseFilterCutoff * pow(2.0, aftertouchOctaves)
            
            // Apply smoothing
            let currentValue = modulationState.lastSmoothedFilterCutoff ?? targetCutoff
            let smoothingFactor = modulationState.filterSmoothingFactor
            let interpolationAmount = 1.0 - smoothingFactor
            let finalCutoff = currentValue + (targetCutoff - currentValue) * interpolationAmount
            modulationState.lastSmoothedFilterCutoff = finalCutoff
            
            let clamped = max(20.0, min(22050.0, finalCutoff))
            filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 2: Modulation index
        if params.amountToModulatorLevel != 0.0 {
            let aftertouchOffset = aftertouchDelta * params.amountToModulatorLevel
            let finalModIndex = modulationState.baseModulationIndex + aftertouchOffset
            let clamped = max(0.0, min(10.0, finalModIndex))
            oscLeft.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
            oscRight.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
        }
        
        // Destination 3: Vibrato (meta-modulation - handled in voice LFO application)
        // This modulates the voice LFO pitch amount and is applied in applyVoiceLFO()
    }
}
