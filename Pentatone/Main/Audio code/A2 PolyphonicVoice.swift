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
        
        // Capture current envelope values for smooth release using ModulationRouter
        let modulatorValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release,
            capturedLevel: 0.0  // Not used when gate is open
        )
        
        let auxiliaryValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.auxiliaryEnvelope.attack,
            decay: voiceModulation.auxiliaryEnvelope.decay,
            sustain: voiceModulation.auxiliaryEnvelope.sustain,
            release: voiceModulation.auxiliaryEnvelope.release,
            capturedLevel: 0.0  // Not used when gate is open
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
        
        // Store base modulator multiplier for global LFO modulation
        modulationState.baseModulatorMultiplier = parameters.modulatingMultiplier
        
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
    
    /// Resets modulator multiplier to base (unmodulated) value
    /// Called when global LFO modulation amount is set to zero
    func resetModulatorMultiplierToBase() {
        oscLeft.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.05)
        oscRight.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.05)
    }
    
    /// Resets modulation index to base (unmodulated) value
    /// Called when voice LFO modulation amount is set to zero
    func resetModulationIndexToBase() {
        oscLeft.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.05)
        oscRight.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.05)
    }
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
        // Note: Some destinations (pitch, filter, mod index) receive input from multiple sources
        // and must be calculated in a combined fashion to avoid one source overwriting another
        applyCombinedModulationIndex(
            modulatorEnvValue: modulatorEnvValue,
            voiceLFORawValue: voiceLFORawValue,
            aftertouchDelta: aftertouchDelta
        )
        applyCombinedPitch(
            auxiliaryEnvValue: auxiliaryEnvValue,
            voiceLFORawValue: voiceLFORawValue
        )
        applyCombinedFilterFrequency(
            auxiliaryEnvValue: auxiliaryEnvValue,
            voiceLFORawValue: voiceLFORawValue,
            globalLFORawValue: globalLFO.rawValue,
            globalLFOParameters: globalLFO.parameters,
            keyTrackValue: keyTrackValue,
            aftertouchDelta: aftertouchDelta
        )
        applyAuxiliaryEnvelope(envValue: auxiliaryEnvValue)
        applyGlobalLFO(rawValue: globalLFO.rawValue, parameters: globalLFO.parameters)
        applyTouchAftertouch(aftertouchDelta: aftertouchDelta)
    }
    
    // MARK: - Voice LFO Phase Update (Phase 5C)
    
    /// Updates the voice LFO phase based on time and tempo
    private func updateVoiceLFOPhase(deltaTime: Double, tempo: Double) {
        guard voiceModulation.voiceLFO.isEnabled else { return }
        
        let lfo = voiceModulation.voiceLFO
        
        // Apply key tracking modulation to base frequency
        var effectiveFrequency = lfo.frequency
        if voiceModulation.keyTracking.amountToVoiceLFOFrequency != 0.0 {
            let keyTrackValue = voiceModulation.keyTracking.trackingValue(
                forFrequency: modulationState.currentFrequency
            )
            effectiveFrequency = ModulationRouter.calculateVoiceLFOFrequency(
                baseFrequency: lfo.frequency,
                keyTrackValue: keyTrackValue,
                keyTrackAmount: voiceModulation.keyTracking.amountToVoiceLFOFrequency
            )
        }
        
        // Calculate phase increment based on frequency mode
        let phaseIncrement: Double
        
        switch lfo.frequencyMode {
        case .hertz:
            // Direct Hz: phase increment = frequency * deltaTime
            phaseIncrement = effectiveFrequency * deltaTime
            
        case .tempoSync:
            // Tempo sync: effectiveFrequency is a tempo multiplier
            // e.g., 1.0 = quarter note, 2.0 = eighth note, 0.5 = half note
            let beatsPerSecond = tempo / 60.0
            let cyclesPerSecond = beatsPerSecond * effectiveFrequency
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
    
    // MARK: - Combined Modulation Application Methods
    // These methods handle destinations that receive input from multiple sources
    // and must combine them properly to avoid one source overwriting another
    
    /// Applies combined modulation index from all sources
    /// Sources: Modulator envelope, Voice LFO, Aftertouch
    private func applyCombinedModulationIndex(
        modulatorEnvValue: Double,
        voiceLFORawValue: Double,
        aftertouchDelta: Double
    ) {
        // Check if any source is active
        let hasModEnv = voiceModulation.modulatorEnvelope.hasActiveDestinations
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToModulatorLevel != 0.0
        let hasAftertouch = voiceModulation.touchAftertouch.amountToModulatorLevel != 0.0
        
        guard hasModEnv || hasVoiceLFO || hasAftertouch else { return }
        
        // Use the ModulationRouter to properly combine all sources
        let finalModIndex = ModulationRouter.calculateModulationIndex(
            baseModIndex: modulationState.baseModulationIndex,
            modEnvValue: modulatorEnvValue,
            modEnvAmount: voiceModulation.modulatorEnvelope.amountToModulationIndex,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: voiceModulation.voiceLFO.amountToModulatorLevel,
            voiceLFORampFactor: modulationState.voiceLFORampFactor,
            aftertouchDelta: aftertouchDelta,
            aftertouchAmount: voiceModulation.touchAftertouch.amountToModulatorLevel
        )
        
        oscLeft.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0)
        oscRight.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0)
    }
    
    /// Applies combined pitch modulation from all sources
    /// Sources: Auxiliary envelope, Voice LFO (with meta-modulation from aux env and aftertouch)
    private func applyCombinedPitch(
        auxiliaryEnvValue: Double,
        voiceLFORawValue: Double
    ) {
        // Check if any source is active (including meta-modulation sources)
        let hasAuxEnv = voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch != 0.0
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToOscillatorPitch != 0.0
        let hasVibratoMetaMod = voiceModulation.auxiliaryEnvelope.amountToVibrato != 0.0
            || voiceModulation.touchAftertouch.amountToVibrato != 0.0
        
        guard hasAuxEnv || hasVoiceLFO || hasVibratoMetaMod else { return }
        
        // Calculate effective voice LFO amount (with meta-modulation)
        // Allow aftertouch/aux env to add vibrato even if base amount is 0
        var effectiveVoiceLFOAmount = voiceModulation.voiceLFO.amountToOscillatorPitch
        
        if hasVibratoMetaMod {
            // Meta-modulation: aux envelope and aftertouch can modulate the vibrato amount
            let aftertouchDelta = modulationState.currentTouchX - modulationState.initialTouchX
            effectiveVoiceLFOAmount = ModulationRouter.calculateVoiceLFOPitchAmount(
                baseAmount: effectiveVoiceLFOAmount,
                auxEnvValue: auxiliaryEnvValue,
                auxEnvAmount: voiceModulation.auxiliaryEnvelope.amountToVibrato,
                aftertouchDelta: aftertouchDelta,
                aftertouchAmount: voiceModulation.touchAftertouch.amountToVibrato
            )
        }
        
        // Combine aux envelope and voice LFO for pitch
        let finalFreq = ModulationRouter.calculateOscillatorPitch(
            baseFrequency: modulationState.baseFrequency,
            auxEnvValue: auxiliaryEnvValue,
            auxEnvAmount: voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: effectiveVoiceLFOAmount,
            voiceLFORampFactor: modulationState.voiceLFORampFactor
        )
        
        currentFrequency = finalFreq
        updateOscillatorFrequencies()
    }
    
    /// Applies combined filter frequency modulation from all sources
    /// Sources: Key tracking, Auxiliary envelope, Voice LFO, Global LFO, Aftertouch
    private func applyCombinedFilterFrequency(
        auxiliaryEnvValue: Double,
        voiceLFORawValue: Double,
        globalLFORawValue: Double,
        globalLFOParameters: GlobalLFOParameters,
        keyTrackValue: Double,
        aftertouchDelta: Double
    ) {
        // Check if any source is active
        let hasKeyTrack = voiceModulation.keyTracking.amountToFilterFrequency != 0.0
        let hasAuxEnv = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToFilterFrequency != 0.0
        let hasGlobalLFO = globalLFOParameters.amountToFilterFrequency != 0.0
        let hasAftertouch = voiceModulation.touchAftertouch.amountToFilterFrequency != 0.0
        
        guard hasKeyTrack || hasAuxEnv || hasVoiceLFO || hasGlobalLFO || hasAftertouch else { return }
        
        // Use the ModulationRouter to properly combine all sources
        let finalCutoff = ModulationRouter.calculateFilterFrequency(
            baseCutoff: modulationState.baseFilterCutoff,
            keyTrackValue: keyTrackValue,
            keyTrackAmount: voiceModulation.keyTracking.amountToFilterFrequency,
            auxEnvValue: auxiliaryEnvValue,
            auxEnvAmount: voiceModulation.auxiliaryEnvelope.amountToFilterFrequency,
            aftertouchDelta: aftertouchDelta,
            aftertouchAmount: voiceModulation.touchAftertouch.amountToFilterFrequency,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: voiceModulation.voiceLFO.amountToFilterFrequency,
            voiceLFORampFactor: modulationState.voiceLFORampFactor,
            globalLFOValue: globalLFORawValue,
            globalLFOAmount: globalLFOParameters.amountToFilterFrequency
        )
        
        // Apply smoothing for aftertouch if active
        let smoothedCutoff: Double
        if hasAftertouch && modulationState.lastSmoothedFilterCutoff != nil {
            let currentValue = modulationState.lastSmoothedFilterCutoff ?? finalCutoff
            let smoothingFactor = modulationState.filterSmoothingFactor
            let interpolationAmount = 1.0 - smoothingFactor
            smoothedCutoff = currentValue + (finalCutoff - currentValue) * interpolationAmount
            modulationState.lastSmoothedFilterCutoff = smoothedCutoff
        } else {
            smoothedCutoff = finalCutoff
            if hasAftertouch {
                modulationState.lastSmoothedFilterCutoff = finalCutoff
            }
        }
        
        filter.$cutoffFrequency.ramp(to: AUValue(smoothedCutoff), duration: 0)
    }
    
    // MARK: - Individual Modulation Application Methods
    // These handle destinations that only receive input from a single source
    
    /// Applies modulator envelope (fixed destination: modulation index)
    /// NOTE: This is now handled by applyCombinedModulationIndex()
    @available(*, deprecated, message: "Use applyCombinedModulationIndex() instead")
    private func applyModulatorEnvelope(envValue: Double) {
        // Modulation index is now handled by applyCombinedModulationIndex()
        // This method is kept for backwards compatibility but does nothing
        return
    }
    
    /// Applies auxiliary envelope (3 fixed destinations: pitch, filter, vibrato)
    /// NOTE: Pitch and filter are now handled by combined methods
    private func applyAuxiliaryEnvelope(envValue: Double) {
        // Pitch is now handled by applyCombinedPitch()
        // Filter is now handled by applyCombinedFilterFrequency()
        // Vibrato meta-modulation is handled in applyCombinedPitch()
        // This method is kept for backwards compatibility but does nothing
        return
    }
    
    /// Applies voice LFO (3 fixed destinations + delay ramp: pitch, filter, modulator level)
    /// NOTE: All destinations are now handled by combined methods
    private func applyVoiceLFO(rawValue: Double) {
        // Pitch is now handled by applyCombinedPitch()
        // Filter is now handled by applyCombinedFilterFrequency()
        // Modulation index is now handled by applyCombinedModulationIndex()
        // This method is kept for backwards compatibility but does nothing
        return
    }
    
    /// Applies global LFO (4 fixed destinations: amplitude, modulator multiplier, filter, delay time)
    /// NOTE: Filter is now handled by applyCombinedFilterFrequency()
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
            let finalMultiplier = ModulationRouter.calculateModulatorMultiplier(
                baseMultiplier: modulationState.baseModulatorMultiplier,  // Use stored base value
                globalLFOValue: rawValue,
                globalLFOAmount: parameters.amountToModulatorMultiplier
            )
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0)
        }
        
        // Destination 3: Filter frequency
        // Now handled by applyCombinedFilterFrequency()
        
        // Destination 4: Delay time (handled by VoicePool, not voice-level)
        // This is included here for completeness but won't execute at voice level
    }
    
    /// Applies key tracking (2 fixed destinations: filter frequency, voice LFO frequency)
    /// NOTE: Filter is now handled by applyCombinedFilterFrequency()
    private func applyKeyTracking(trackingValue: Double) {
        // Destination 1: Filter frequency
        // Now handled by applyCombinedFilterFrequency()
        
        // Destination 2: Voice LFO frequency
        // NOTE: This modulation is applied in updateVoiceLFOPhase() to avoid feedback loops
        // Key tracking modulation is read during phase calculation, not written back to parameters
    }
    
    /// Applies touch aftertouch (3 fixed destinations: filter, modulator level, vibrato)
    /// NOTE: Filter and modulation index are now handled by combined methods
    private func applyTouchAftertouch(aftertouchDelta: Double) {
        // Destination 1: Filter frequency
        // Now handled by applyCombinedFilterFrequency()
        
        // Destination 2: Modulation index
        // Now handled by applyCombinedModulationIndex()
        
        // Destination 3: Vibrato (meta-modulation)
        // Handled in applyCombinedPitch()
    }
}
