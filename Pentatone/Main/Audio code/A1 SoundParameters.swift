//
//  A1 SoundParameters.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 16/12/2025.
//

import Foundation
import Combine
import AudioKit
import DunneAudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - Parameter Models

/// Voice mode determining polyphony behavior
enum VoiceMode: String, Codable, Equatable, CaseIterable {
    case monophonic
    case polyphonic
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .monophonic: return "Monophonic"
        case .polyphonic: return "Polyphonic"
        }
    }
}

/// Waveform types available for the FM oscillator
enum OscillatorWaveform: String, Codable, Equatable, CaseIterable {
    case sine
    case triangle
    case square
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        case .square: return "Square"
        }
    }
    
    /// Convert to AudioKit Table
    func makeTable() -> Table {
        switch self {
        case .sine: return Table(.sine)
        case .triangle: return Table(.triangle)
        case .square: return Table(.square)
        }
    }
}

/// Parameters for the FM oscillator
struct OscillatorParameters: Codable, Equatable {
    var carrierMultiplier: Double
    var modulatingMultiplier: Double          // Combined coarse + fine (e.g., 2.50 = coarse:2, fine:0.50)
    var modulationIndex: Double
    var amplitude: Double
    var waveform: OscillatorWaveform
    var detuneMode: DetuneMode                // How stereo spread is calculated
    var stereoOffsetProportional: Double      // For proportional mode (ratio, e.g., 1.003)
    var stereoOffsetConstant: Double          // For constant mode (Hz, e.g., 2.0)
    
    static let `default` = OscillatorParameters(
        carrierMultiplier: 1.0,
        modulatingMultiplier: 2.00,
        modulationIndex: 1.0,
        amplitude: 0.5,
        waveform: .triangle,
        detuneMode: .proportional,
        stereoOffsetProportional: 1.003,
        stereoOffsetConstant: 2.0
    )
    
    /// Helper: Get the coarse part of modulatingMultiplier (integer part)
    var modulatingMultiplierCoarse: Int {
        Int(floor(modulatingMultiplier))
    }
    
    /// Helper: Get the fine part of modulatingMultiplier (fractional part)
    var modulatingMultiplierFine: Double {
        modulatingMultiplier - floor(modulatingMultiplier)
    }
    
    /// Helper: Set modulatingMultiplier from separate coarse and fine values
    mutating func setModulatingMultiplier(coarse: Int, fine: Double) {
        modulatingMultiplier = Double(coarse) + fine
    }
}

/// Parameters for the low-pass filter
struct FilterParameters: Codable, Equatable {
    var cutoffFrequency: Double
    var resonance: Double
    var saturation: Double
    
    static let `default` = FilterParameters(
        cutoffFrequency: 1200,
        resonance: 0.5,
        saturation: 2.0
    )
    
    /// Clamps cutoff to valid range (0 Hz - 22.05 kHz)
    var clampedCutoff: Double {
        min(max(cutoffFrequency, 0), 22_050)
    }
    
    /// Clamps resonance to valid range (0 - 2)
    var clampedResonance: Double {
        min(max(resonance, 0), 2.0)
    }
    
    /// Clamps saturation to valid range (0 - 10)
    var clampedSaturation: Double {
        min(max(saturation, 0), 10.0)
    }
}

/// Parameters for the amplitude envelope
struct EnvelopeParameters: Codable, Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    
    static let `default` = EnvelopeParameters(
        attackDuration: 0.001,
        decayDuration: 0.1,
        sustainLevel: 1.0,
        releaseDuration: 0.1
    )
}

/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters
    var envelope: EnvelopeParameters
    var modulation: VoiceModulationParameters  // Phase 5: Modulation system
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        envelope: .default,
        modulation: .default  // Uses VoiceModulationParameters.default
    )
}

/// Musical note divisions for tempo-synced delay
enum DelayTimeValue: Double, Codable, Equatable, CaseIterable {
    case thirtySecond = 0.03125    // 1/32 note
    case twentyFourth = 0.04166666 // 1/24 note (triplet sixteenth)
    case sixteenth = 0.0625        // 1/16 note
    case dottedSixteenth = 0.09375 // 3/32 note
    case eighth = 0.125            // 1/8 note
    case dottedEighth = 0.1875     // 3/16 note
    case quarter = 0.25            // 1/4 note
    
    var displayName: String {
        switch self {
        case .thirtySecond: return "1/32"
        case .twentyFourth: return "1/24"
        case .sixteenth: return "1/16"
        case .dottedSixteenth: return "3/32"
        case .eighth: return "1/8"
        case .dottedEighth: return "3/16"
        case .quarter: return "1/4"
        }
    }
    
    /// Convert to delay time in seconds based on tempo
    /// Formula: rawValue × (240/tempo)
    /// This gives: 1/4 note at 120 BPM = 0.25 × 2.0 = 0.5 seconds
    func timeInSeconds(tempo: Double) -> Double {
        return self.rawValue * (240.0 / tempo)
    }
}

/// Parameters for the stereo delay effect
struct DelayParameters: Codable, Equatable {
    var timeValue: DelayTimeValue  // Musical note division (always tempo-synced)
    var feedback: Double
    var dryWetMix: Double
    var pingPong: Bool
    
    static let `default` = DelayParameters(
        timeValue: .quarter,  // 1/4 note
        feedback: 0.5,
        dryWetMix: 0.5,
        pingPong: true
    )
    
    /// Calculate actual delay time in seconds based on current tempo
    func timeInSeconds(tempo: Double) -> Double {
        return timeValue.timeInSeconds(tempo: tempo)
    }
}

/// Parameters for the reverb effect
struct ReverbParameters: Codable, Equatable {
    var feedback: Double
    var cutoffFrequency: Double
    var balance: Double  // 0 = all dry, 1 = all wet
    
    static let `default` = ReverbParameters(
        feedback: 0.5,
        cutoffFrequency: 10_000,
        balance: 0.5
    )
}

/// Parameter for the output mixer
struct OutputParameters: Codable, Equatable {
    var preVolume: Double   // Voice mixer volume (before FX)
    var volume: Double      // Output mixer volume (after FX)
    
    static let `default` = OutputParameters(
        preVolume: 0.5,
        volume: 0.5
    )
}

/// Global pitch modifiers applied to all triggered notes
/// All parameters are multiplication factors applied to the base frequency
struct GlobalPitchParameters: Codable, Equatable {
    var transpose: Double   // Semitone transposition (1.0 = no change, 1.059463 ≈ +1 semitone)
    var octave: Double      // Octave shift (1.0 = no change, 2.0 = +1 octave, 0.5 = -1 octave)
    var fineTune: Double    // Fine tuning adjustment (1.0 = no change, subtle variations)
    
    static let `default` = GlobalPitchParameters(
        transpose: 1.0,
        octave: 1.0,
        fineTune: 1.0
    )
    
    /// Combined multiplication factor for all pitch modifiers
    var combinedFactor: Double {
        transpose * octave * fineTune
    }
    
    /// Helper: Set octave from an integer offset (e.g., -1, 0, +1, +2)
    mutating func setOctaveOffset(_ offset: Int) {
        // Each octave offset doubles or halves the frequency
        // offset = 0 -> 2^0 = 1.0
        // offset = 1 -> 2^1 = 2.0
        // offset = -1 -> 2^-1 = 0.5
        octave = pow(2.0, Double(offset))
    }
    
    /// Helper: Get the current octave as an integer offset
    var octaveOffset: Int {
        // Reverse the calculation: offset = log2(octave)
        Int(round(log2(octave)))
    }
    
    /// Helper: Set transpose from semitones (e.g., -12, 0, +7)
    mutating func setTransposeSemitones(_ semitones: Int) {
        // Equal temperament: each semitone is 2^(1/12) ≈ 1.059463
        transpose = pow(2.0, Double(semitones) / 12.0)
    }
    
    /// Helper: Get the current transpose as semitones
    var transposeSemitones: Int {
        // Reverse: semitones = 12 * log2(transpose)
        Int(round(12.0 * log2(transpose)))
    }
    
    /// Helper: Set fine tune from cents (e.g., -50, 0, +50)
    /// Cents are 1/100th of a semitone
    mutating func setFineTuneCents(_ cents: Double) {
        // 100 cents = 1 semitone = 2^(1/12)
        // 1 cent = 2^(1/1200)
        fineTune = pow(2.0, cents / 1200.0)
    }
    
    /// Helper: Get the current fine tune as cents
    var fineTuneCents: Double {
        // Reverse: cents = 1200 * log2(fineTune)
        1200.0 * log2(fineTune)
    }
}

/// Parameters defining how macro controls affect underlying parameters
struct MacroControlParameters: Codable, Equatable {
    // Tone macro -> affects modulation index, filter cutoff, and filter saturation
    var toneToModulationIndexRange: Double      // +/- range (0-5)
    var toneToFilterCutoffOctaves: Double       // +/- range in octaves (0-4)
    var toneToFilterSaturationRange: Double     // +/- range (0-2)
    
    // Ambience macro -> affects delay and reverb
    var ambienceToDelayFeedbackRange: Double    // +/- range (0-1)
    var ambienceToDelayMixRange: Double         // +/- range (0-1)
    var ambienceToReverbFeedbackRange: Double   // +/- range (0-1)
    var ambienceToReverbMixRange: Double        // +/- range (0-1)
    
    static let `default` = MacroControlParameters(
        toneToModulationIndexRange: 2.5,
        toneToFilterCutoffOctaves: 2.0,
        toneToFilterSaturationRange: 1.0,
        ambienceToDelayFeedbackRange: 0.5,
        ambienceToDelayMixRange: 0.5,
        ambienceToReverbFeedbackRange: 0.5,
        ambienceToReverbMixRange: 0.5
    )
}

/// Current state of macro controls and their base values
struct MacroControlState: Codable, Equatable {
    // Base values - set when preset is loaded or edited
    var baseModulationIndex: Double
    var baseFilterCutoff: Double
    var baseFilterSaturation: Double
    var baseDelayFeedback: Double
    var baseDelayMix: Double
    var baseReverbFeedback: Double
    var baseReverbMix: Double
    var basePreVolume: Double
    
    // Macro positions (-1.0 to +1.0, where 0 is center/neutral)
    // Volume is absolute (0-1), tone and ambience are relative (-1 to +1)
    var volumePosition: Double
    var tonePosition: Double
    var ambiencePosition: Double
    
    /// Initialize macro state from current parameters
    /// This ensures base values always match the actual parameter state
    init(from voiceParams: VoiceParameters, masterParams: MasterParameters) {
        // Capture base values from parameters
        self.baseModulationIndex = voiceParams.oscillator.modulationIndex
        self.baseFilterCutoff = voiceParams.filter.cutoffFrequency
        self.baseFilterSaturation = voiceParams.filter.saturation
        self.baseDelayFeedback = masterParams.delay.feedback
        self.baseDelayMix = masterParams.delay.dryWetMix
        self.baseReverbFeedback = masterParams.reverb.feedback
        self.baseReverbMix = masterParams.reverb.balance
        self.basePreVolume = masterParams.output.preVolume
        
        // Initialize positions
        // Volume matches preVolume (absolute), others start at neutral
        self.volumePosition = masterParams.output.preVolume
        self.tonePosition = 0.0
        self.ambiencePosition = 0.0
    }
    
    /// Convenience initializer for Codable (required for preset loading)
    init(baseModulationIndex: Double, baseFilterCutoff: Double, baseFilterSaturation: Double,
         baseDelayFeedback: Double, baseDelayMix: Double, baseReverbFeedback: Double, baseReverbMix: Double,
         basePreVolume: Double, volumePosition: Double, tonePosition: Double, ambiencePosition: Double) {
        self.baseModulationIndex = baseModulationIndex
        self.baseFilterCutoff = baseFilterCutoff
        self.baseFilterSaturation = baseFilterSaturation
        self.baseDelayFeedback = baseDelayFeedback
        self.baseDelayMix = baseDelayMix
        self.baseReverbFeedback = baseReverbFeedback
        self.baseReverbMix = baseReverbMix
        self.basePreVolume = basePreVolume
        self.volumePosition = volumePosition
        self.tonePosition = tonePosition
        self.ambiencePosition = ambiencePosition
    }
    
    /// Default macro state derived from default parameters
    static let `default` = MacroControlState(
        from: VoiceParameters.default,
        masterParams: MasterParameters.default
    )
}

/// Master parameters affecting the entire audio engine
struct MasterParameters: Codable, Equatable {
    var delay: DelayParameters
    var reverb: ReverbParameters
    var output: OutputParameters
    var globalPitch: GlobalPitchParameters // Global pitch modifiers (transpose, octave, fine tune)
    var globalLFO: GlobalLFOParameters     // Phase 5C: Global modulation
    var tempo: Double                      // BPM for tempo-synced modulation
    var voiceMode: VoiceMode               // Monophonic or polyphonic
    var macroControl: MacroControlParameters // Macro control ranges
    
    static let `default` = MasterParameters(
        delay: .default,
        reverb: .default,
        output: .default,
        globalPitch: .default,
        globalLFO: .default,  // Uses GlobalLFOParameters.default
        tempo: 120.0,
        voiceMode: .polyphonic,
        macroControl: .default
    )
}

// MARK: - Complete Parameter Set (for Presets)

/// A complete snapshot of all audio parameters - used for presets
struct AudioParameterSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters  // Template applied to all voices
    var master: MasterParameters
    var macroState: MacroControlState   // Current macro positions and base values
    var createdAt: Date
    
    static let `default` = AudioParameterSet(
        id: UUID(),
        name: "Default",
        voiceTemplate: .default,
        master: .default,
        macroState: .default,
        createdAt: Date()
    )
}

// MARK: - Parameter Manager

/// Central manager for all audio parameters
/// This provides the interface between UI and the AudioKit engine
@MainActor
final class AudioParameterManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AudioParameterManager()
    
    // MARK: - Current Parameters
    
    /// Current master parameters (delay, reverb)
    @Published private(set) var master: MasterParameters = .default
    
    /// Current voice template - used as base for all voices
    @Published private(set) var voiceTemplate: VoiceParameters = .default
    
    /// Current macro control state
    @Published private(set) var macroState: MacroControlState = .default
    
    // MARK: - Initialization
    
    private init() {
        // Private to enforce singleton
    }
    
    // MARK: - Master Parameter Updates
    
    func updateDelay(_ parameters: DelayParameters) {
        master.delay = parameters
        applyDelayParameters()
    }
    
    func updateDelayMix(_ mix: Double) {
        master.delay.dryWetMix = mix
        fxDelay?.dryWetMix = AUValue(1-mix)
    }
    
    func updateDelayTimeValue(_ timeValue: DelayTimeValue) {
        master.delay.timeValue = timeValue
        // Calculate actual time in seconds and apply to engine
        let timeInSeconds = timeValue.timeInSeconds(tempo: master.tempo)
        fxDelay?.time = AUValue(timeInSeconds)
    }
    
    func updateDelayFeedback(_ feedback: Double) {
        master.delay.feedback = feedback
        fxDelay?.feedback = AUValue(feedback)
    }
    
    func updateDelayPingPong(_ pingPong: Bool) {
        master.delay.pingPong = pingPong
        // Note: PingPong mode may need to be handled in the audio engine setup
        // depending on your delay implementation
    }
    
    func updateReverb(_ parameters: ReverbParameters) {
        master.reverb = parameters
        applyReverbParameters()
    }
    
    func updateReverbMix(_ balance: Double) {
        master.reverb.balance = balance
        fxReverb?.balance = AUValue(balance)
    }
    
    func updateReverbFeedback(_ feedback: Double) {
        master.reverb.feedback = feedback
        fxReverb?.feedback = AUValue(feedback)
    }
    
    func updateReverbCutoff(_ cutoff: Double) {
        master.reverb.cutoffFrequency = cutoff
        fxReverb?.cutoffFrequency = AUValue(cutoff)
    }
    
    func updateOutputVolume(_ volume: Double) {
        master.output.volume = volume
        outputMixer?.volume = AUValue(volume)
    }
    
    func updatePreVolume(_ preVolume: Double) {
        master.output.preVolume = preVolume
        voicePool?.voiceMixer.volume = AUValue(preVolume)
    }
    
    func updateTempo(_ tempo: Double) {
        master.tempo = tempo
        // Recalculate and apply delay time with new tempo
        let timeInSeconds = master.delay.timeInSeconds(tempo: tempo)
        fxDelay?.time = AUValue(timeInSeconds)
    }
    
    // MARK: - Voice Mode Updates
    
    /// Update voice mode (monophonic/polyphonic)
    /// This requires recreating the voice pool with the new voice count
    func updateVoiceMode(_ mode: VoiceMode, completion: @escaping () -> Void = {}) {
        // Update the parameter
        master.voiceMode = mode
        
        // Calculate new voice count
        let newVoiceCount: Int
        switch mode {
        case .monophonic:
            newVoiceCount = 1
        case .polyphonic:
            newVoiceCount = nominalPolyphony
        }
        
        // Update the voice pool
        voicePool?.setPolyphony(newVoiceCount) {
            print("🎵 Voice mode switched to \(mode.displayName)")
            completion()
        }
    }
    
    // MARK: - Global Pitch Updates
    
    func updateGlobalPitch(_ parameters: GlobalPitchParameters) {
        master.globalPitch = parameters
    }
    
    func updateTranspose(_ transpose: Double) {
        master.globalPitch.transpose = transpose
    }
    
    func updateTransposeSemitones(_ semitones: Int) {
        var pitch = master.globalPitch
        pitch.setTransposeSemitones(semitones)
        master.globalPitch = pitch
    }
    
    func updateOctave(_ octave: Double) {
        master.globalPitch.octave = octave
    }
    
    func updateOctaveOffset(_ offset: Int) {
        var pitch = master.globalPitch
        pitch.setOctaveOffset(offset)
        master.globalPitch = pitch
    }
    
    func updateFineTune(_ fineTune: Double) {
        master.globalPitch.fineTune = fineTune
    }
    
    func updateFineTuneCents(_ cents: Double) {
         var pitch = master.globalPitch
        pitch.setFineTuneCents(cents)
        master.globalPitch = pitch
     }
    
    // MARK: - Voice Template Updates
    
    /// Update the voice template (new voices will use these parameters)
    /// Note: Does not affect currently playing voices - only new voice allocations
    func updateVoiceTemplate(_ parameters: VoiceParameters) {
        voiceTemplate = parameters
    }
    
    func updateTemplateFilter(_ parameters: FilterParameters) {
        voiceTemplate.filter = parameters
    }
    
    func updateTemplateOscillator(_ parameters: OscillatorParameters) {
        voiceTemplate.oscillator = parameters
    }
    
    func updateTemplateEnvelope(_ parameters: EnvelopeParameters) {
        voiceTemplate.envelope = parameters
    }
    
    // MARK: - Individual Oscillator Parameter Updates
    
    /// Update oscillator waveform
    func updateOscillatorWaveform(_ waveform: OscillatorWaveform) {
        voiceTemplate.oscillator.waveform = waveform
    }
    
    /// Update carrier multiplier
    func updateCarrierMultiplier(_ value: Double) {
        voiceTemplate.oscillator.carrierMultiplier = value
    }
    
    /// Update modulating multiplier
    func updateModulatingMultiplier(_ value: Double) {
        voiceTemplate.oscillator.modulatingMultiplier = value
    }
    
    /// Update modulation index (base level)
    func updateModulationIndex(_ value: Double) {
        voiceTemplate.oscillator.modulationIndex = value
    }
    
    /// Update detune mode
    func updateDetuneMode(_ mode: DetuneMode) {
        voiceTemplate.oscillator.detuneMode = mode
    }
    
    /// Update stereo offset (proportional)
    func updateStereoOffsetProportional(_ value: Double) {
        voiceTemplate.oscillator.stereoOffsetProportional = value
    }
    
    /// Update stereo offset (constant)
    func updateStereoOffsetConstant(_ value: Double) {
        voiceTemplate.oscillator.stereoOffsetConstant = value
    }
    
    // MARK: - Individual Envelope Parameter Updates
    
    /// Update envelope attack duration
    func updateEnvelopeAttack(_ value: Double) {
        voiceTemplate.envelope.attackDuration = value
    }
    
    /// Update envelope decay duration
    func updateEnvelopeDecay(_ value: Double) {
        voiceTemplate.envelope.decayDuration = value
    }
    
    /// Update envelope sustain level
    func updateEnvelopeSustain(_ value: Double) {
        voiceTemplate.envelope.sustainLevel = value
    }
    
    /// Update envelope release duration
    func updateEnvelopeRelease(_ value: Double) {
        voiceTemplate.envelope.releaseDuration = value
    }
    
    // MARK: - Individual Filter Parameter Updates
    
    /// Update filter cutoff frequency
    func updateFilterCutoff(_ value: Double) {
        voiceTemplate.filter.cutoffFrequency = value
    }
    
    /// Update filter resonance
    func updateFilterResonance(_ value: Double) {
        voiceTemplate.filter.resonance = value
    }
    
    /// Update filter saturation
    func updateFilterSaturation(_ value: Double) {
        voiceTemplate.filter.saturation = value
    }
    
    // MARK: - Individual Modulation Parameter Updates
    
    /// Update modulator envelope attack
    func updateModulatorEnvelopeAttack(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.attack = value
    }
    
    /// Update modulator envelope decay
    func updateModulatorEnvelopeDecay(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.decay = value
    }
    
    /// Update modulator envelope sustain
    func updateModulatorEnvelopeSustain(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.sustain = value
    }
    
    /// Update modulator envelope release
    func updateModulatorEnvelopeRelease(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.release = value
    }
    
    /// Update modulator envelope amount to modulation index
    func updateModulatorEnvelopeAmountToModulationIndex(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.amountToModulationIndex = value
    }
    
    /// Update modulator envelope destination (deprecated - destination is now fixed)
    @available(*, deprecated, message: "Modulator envelope destination is now fixed to modulation index")
    func updateModulatorEnvelopeDestination(_ destination: ModulationDestination) {
        // No-op: destination is now fixed
    }
    
    /// Update key tracking amount to filter frequency
    func updateKeyTrackingAmountToFilterFrequency(_ value: Double) {
        voiceTemplate.modulation.keyTracking.amountToFilterFrequency = value
    }
    
    /// Update key tracking amount to voice LFO frequency
    func updateKeyTrackingAmountToVoiceLFOFrequency(_ value: Double) {
        voiceTemplate.modulation.keyTracking.amountToVoiceLFOFrequency = value
    }
    
    /// Update key tracking destination (deprecated - destinations are now fixed)
    @available(*, deprecated, message: "Key tracking destinations are now fixed")
    func updateKeyTrackingDestination(_ destination: ModulationDestination) {
        // No-op: destinations are now fixed
    }
    
    /// Update key tracking amount (deprecated - use specific amount methods)
    @available(*, deprecated, message: "Use updateKeyTrackingAmountToFilterFrequency or updateKeyTrackingAmountToVoiceLFOFrequency")
    func updateKeyTrackingAmount(_ value: Double) {
        // Default to filter frequency for backward compatibility
        voiceTemplate.modulation.keyTracking.amountToFilterFrequency = value
    }
    
    /// Update key tracking enabled state
    func updateKeyTrackingEnabled(_ enabled: Bool) {
        voiceTemplate.modulation.keyTracking.isEnabled = enabled
    }
    
    /// Update auxiliary envelope attack
    func updateAuxiliaryEnvelopeAttack(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.attack = value
    }
    
    /// Update auxiliary envelope decay
    func updateAuxiliaryEnvelopeDecay(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.decay = value
    }
    
    /// Update auxiliary envelope sustain
    func updateAuxiliaryEnvelopeSustain(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.sustain = value
    }
    
    /// Update auxiliary envelope release
    func updateAuxiliaryEnvelopeRelease(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.release = value
    }
    
    /// Update auxiliary envelope amount to oscillator pitch
    func updateAuxiliaryEnvelopeAmountToPitch(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToOscillatorPitch = value
    }
    
    /// Update auxiliary envelope amount to filter frequency
    func updateAuxiliaryEnvelopeAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToFilterFrequency = value
    }
    
    /// Update auxiliary envelope amount to vibrato (voice LFO pitch amount)
    func updateAuxiliaryEnvelopeAmountToVibrato(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToVibrato = value
    }
    
    /// Update auxiliary envelope destination (deprecated - destinations are now fixed)
    @available(*, deprecated, message: "Auxiliary envelope destinations are now fixed")
    func updateAuxiliaryEnvelopeDestination(_ destination: ModulationDestination) {
        // No-op: destinations are now fixed
    }
    
    /// Update auxiliary envelope amount (deprecated - use specific amount methods)
    @available(*, deprecated, message: "Use updateAuxiliaryEnvelopeAmountToPitch, AmountToFilter, or AmountToVibrato")
    func updateAuxiliaryEnvelopeAmount(_ value: Double) {
        // Default to filter for backward compatibility
        voiceTemplate.modulation.auxiliaryEnvelope.amountToFilterFrequency = value
    }
    
    /// Update voice LFO waveform
    func updateVoiceLFOWaveform(_ waveform: LFOWaveform) {
        voiceTemplate.modulation.voiceLFO.waveform = waveform
    }
    
    /// Update voice LFO reset mode
    func updateVoiceLFOResetMode(_ mode: LFOResetMode) {
        voiceTemplate.modulation.voiceLFO.resetMode = mode
    }
    
    /// Update voice LFO frequency mode
    func updateVoiceLFOFrequencyMode(_ mode: LFOFrequencyMode) {
        voiceTemplate.modulation.voiceLFO.frequencyMode = mode
    }
    
    /// Update voice LFO frequency
    func updateVoiceLFOFrequency(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.frequency = value
    }
    
    /// Update voice LFO delay time (ramp time)
    func updateVoiceLFODelayTime(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.delayTime = value
    }
    
    /// Update voice LFO amount to oscillator pitch
    func updateVoiceLFOAmountToPitch(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.amountToOscillatorPitch = value
    }
    
    /// Update voice LFO amount to filter frequency
    func updateVoiceLFOAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.amountToFilterFrequency = value
    }
    
    /// Update voice LFO amount to modulator level
    func updateVoiceLFOAmountToModulatorLevel(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.amountToModulatorLevel = value
    }
    
    /// Update voice LFO destination (deprecated - destinations are now fixed)
    @available(*, deprecated, message: "Voice LFO destinations are now fixed")
    func updateVoiceLFODestination(_ destination: ModulationDestination) {
        // No-op: destinations are now fixed
    }
    
    /// Update voice LFO amount (deprecated - use specific amount methods)
    @available(*, deprecated, message: "Use updateVoiceLFOAmountToPitch, AmountToFilter, or AmountToModulatorLevel")
    func updateVoiceLFOAmount(_ value: Double) {
        // Default to pitch for backward compatibility
        voiceTemplate.modulation.voiceLFO.amountToOscillatorPitch = value
    }
    
    /// Update voice LFO enabled state
    func updateVoiceLFOEnabled(_ enabled: Bool) {
        voiceTemplate.modulation.voiceLFO.isEnabled = enabled
    }
    
    // MARK: - Global LFO Parameter Updates
    
    /// Update global LFO waveform
    func updateGlobalLFOWaveform(_ waveform: LFOWaveform) {
        master.globalLFO.waveform = waveform
    }
    
    /// Update global LFO reset mode
    func updateGlobalLFOResetMode(_ mode: LFOResetMode) {
        master.globalLFO.resetMode = mode
    }
    
    /// Update global LFO frequency mode
    func updateGlobalLFOFrequencyMode(_ mode: LFOFrequencyMode) {
        master.globalLFO.frequencyMode = mode
    }
    
    /// Update global LFO frequency
    func updateGlobalLFOFrequency(_ value: Double) {
        master.globalLFO.frequency = value
    }
    
    /// Update global LFO amount to oscillator amplitude
    func updateGlobalLFOAmountToAmplitude(_ value: Double) {
        master.globalLFO.amountToOscillatorAmplitude = value
    }
    
    /// Update global LFO amount to modulator multiplier
    func updateGlobalLFOAmountToModulatorMultiplier(_ value: Double) {
        master.globalLFO.amountToModulatorMultiplier = value
    }
    
    /// Update global LFO amount to filter frequency
    func updateGlobalLFOAmountToFilter(_ value: Double) {
        master.globalLFO.amountToFilterFrequency = value
    }
    
    /// Update global LFO amount to delay time
    func updateGlobalLFOAmountToDelayTime(_ value: Double) {
        master.globalLFO.amountToDelayTime = value
    }
    
    /// Update global LFO destination (deprecated - destinations are now fixed)
    @available(*, deprecated, message: "Global LFO destinations are now fixed")
    func updateGlobalLFODestination(_ destination: ModulationDestination) {
        // No-op: destinations are now fixed
    }
    
    /// Update global LFO amount (deprecated - use specific amount methods)
    @available(*, deprecated, message: "Use updateGlobalLFOAmountToAmplitude, AmountToModulatorMultiplier, AmountToFilter, or AmountToDelayTime")
    func updateGlobalLFOAmount(_ value: Double) {
        // Default to amplitude for backward compatibility
        master.globalLFO.amountToOscillatorAmplitude = value
    }
    
    /// Update global LFO enabled state
    func updateGlobalLFOEnabled(_ enabled: Bool) {
        master.globalLFO.isEnabled = enabled
    }
    
    // MARK: - Touch Response Parameter Updates
    
    /// Update initial touch amount to oscillator amplitude
    func updateInitialTouchAmountToAmplitude(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToOscillatorAmplitude = value
    }
    
    /// Update initial touch amount to mod envelope
    func updateInitialTouchAmountToModEnvelope(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToModEnvelope = value
    }
    
    /// Update initial touch amount to aux envelope pitch
    func updateInitialTouchAmountToAuxEnvPitch(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToAuxEnvPitch = value
    }
    
    /// Update initial touch amount to aux envelope cutoff
    func updateInitialTouchAmountToAuxEnvCutoff(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToAuxEnvCutoff = value
    }
    
    /// Update aftertouch amount to filter frequency
    func updateAftertouchAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToFilterFrequency = value
    }
    
    /// Update aftertouch amount to modulator level
    func updateAftertouchAmountToModulatorLevel(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToModulatorLevel = value
    }
    
    /// Update aftertouch amount to vibrato
    func updateAftertouchAmountToVibrato(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToVibrato = value
    }

    // MARK: - Macro Control Updates
    
    /// Update macro control parameter ranges
    func updateMacroControlParameters(_ parameters: MacroControlParameters) {
        master.macroControl = parameters
    }
    
    /// Update tone to modulation index range
    func updateToneToModulationIndexRange(_ value: Double) {
        master.macroControl.toneToModulationIndexRange = value
    }
    
    /// Update tone to filter cutoff octaves
    func updateToneToFilterCutoffOctaves(_ value: Double) {
        master.macroControl.toneToFilterCutoffOctaves = value
    }
    
    /// Update tone to filter saturation range
    func updateToneToFilterSaturationRange(_ value: Double) {
        master.macroControl.toneToFilterSaturationRange = value
    }
    
    /// Update ambience to delay feedback range
    func updateAmbienceToDelayFeedbackRange(_ value: Double) {
        master.macroControl.ambienceToDelayFeedbackRange = value
    }
    
    /// Update ambience to delay mix range
    func updateAmbienceToDelayMixRange(_ value: Double) {
        master.macroControl.ambienceToDelayMixRange = value
    }
    
    /// Update ambience to reverb feedback range
    func updateAmbienceToReverbFeedbackRange(_ value: Double) {
        master.macroControl.ambienceToReverbFeedbackRange = value
    }
    
    /// Update ambience to reverb mix range
    func updateAmbienceToReverbMixRange(_ value: Double) {
        master.macroControl.ambienceToReverbMixRange = value
    }
    
    // MARK: - Macro Control Position Updates
    
    /// Update volume macro position and apply to parameters
    /// Position is absolute (0.0 to 1.0)
    func updateVolumeMacro(_ position: Double) {
        // Volume is straightforward - directly maps to preVolume
        let clampedPosition = min(max(position, 0.0), 1.0)
        macroState.volumePosition = clampedPosition
        
        // Apply directly to preVolume and update master parameter
        master.output.preVolume = clampedPosition
        voicePool?.voiceMixer.volume = AUValue(clampedPosition)
    }
    
    /// Update tone macro position and apply to parameters
    /// Position is relative (-1.0 to +1.0, where 0 is neutral)
    func updateToneMacro(_ position: Double) {
        let clampedPosition = min(max(position, -1.0), 1.0)
        macroState.tonePosition = clampedPosition
        
        // Apply tone adjustments
        applyToneMacro()
    }
    
    /// Update ambience macro position and apply to parameters
    /// Position is relative (-1.0 to +1.0, where 0 is neutral)
    func updateAmbienceMacro(_ position: Double) {
        let clampedPosition = min(max(position, -1.0), 1.0)
        macroState.ambiencePosition = clampedPosition
        
        // Apply ambience adjustments
        applyAmbienceMacro()
    }
    
    /// Capture current parameter values as base values for macro controls
    /// Should be called when loading a preset or when user edits parameters directly
    /// This resets macro positions and uses current parameters as the new baseline
    func captureBaseValues() {
        // Create a fresh macro state from current parameters
        macroState = MacroControlState(from: voiceTemplate, masterParams: master)
    }
    
    /// Update macro state to match current parameters without resetting positions
    /// Use this when you want to sync base values but keep the current macro positions
    func syncMacroBaseValues() {
        macroState.baseModulationIndex = voiceTemplate.oscillator.modulationIndex
        macroState.baseFilterCutoff = voiceTemplate.filter.cutoffFrequency
        macroState.baseFilterSaturation = voiceTemplate.filter.saturation
        macroState.baseDelayFeedback = master.delay.feedback
        macroState.baseDelayMix = master.delay.dryWetMix
        macroState.baseReverbFeedback = master.reverb.feedback
        macroState.baseReverbMix = master.reverb.balance
        macroState.basePreVolume = master.output.preVolume
        // Note: positions are NOT reset
    }
    
    // MARK: - Private Macro Application Methods
    
    /// Apply tone macro to modulation index, filter cutoff, and saturation
    private func applyToneMacro() {
        let position = macroState.tonePosition
        let ranges = master.macroControl
        
        // Modulation Index: base +/- range
        let newModIndex = macroState.baseModulationIndex + (position * ranges.toneToModulationIndexRange)
        let clampedModIndex = min(max(newModIndex, 0.0), 10.0)
        updateModulationIndex(clampedModIndex)
        
        // Filter Cutoff: base * 2^(position * octaves)
        // Moving up increases frequency, moving down decreases
        let octaveMultiplier = pow(2.0, position * ranges.toneToFilterCutoffOctaves)
        let newCutoff = macroState.baseFilterCutoff * octaveMultiplier
        let clampedCutoff = min(max(newCutoff, 20.0), 20000.0)
        updateFilterCutoff(clampedCutoff)
        
        // Filter Saturation: base +/- range
        let newSaturation = macroState.baseFilterSaturation + (position * ranges.toneToFilterSaturationRange)
        let clampedSaturation = min(max(newSaturation, 0.0), 10.0)
        updateFilterSaturation(clampedSaturation)
        
        // Apply to all voices
        applyOscillatorToAllVoices()
        applyFilterToAllVoices()
    }
    
    /// Apply ambience macro to delay and reverb parameters
    private func applyAmbienceMacro() {
        let position = macroState.ambiencePosition
        let ranges = master.macroControl
        
        // Delay Feedback: base +/- range
        let newDelayFeedback = macroState.baseDelayFeedback + (position * ranges.ambienceToDelayFeedbackRange)
        let clampedDelayFeedback = min(max(newDelayFeedback, 0.0), 1.0)
        updateDelayFeedback(clampedDelayFeedback)
        
        // Delay Mix: base +/- range
        let newDelayMix = macroState.baseDelayMix + (position * ranges.ambienceToDelayMixRange)
        let clampedDelayMix = min(max(newDelayMix, 0.0), 1.0)
        updateDelayMix(clampedDelayMix)
        
        // Reverb Feedback: base +/- range
        let newReverbFeedback = macroState.baseReverbFeedback + (position * ranges.ambienceToReverbFeedbackRange)
        let clampedReverbFeedback = min(max(newReverbFeedback, 0.0), 1.0)
        updateReverbFeedback(clampedReverbFeedback)
        
        // Reverb Mix: base +/- range
        let newReverbMix = macroState.baseReverbMix + (position * ranges.ambienceToReverbMixRange)
        let clampedReverbMix = min(max(newReverbMix, 0.0), 1.0)
        updateReverbMix(clampedReverbMix)
    }
    
    /// Apply oscillator parameters to all voices
    private func applyOscillatorToAllVoices() {
        let params = voiceTemplate.oscillator
        voicePool?.updateAllVoiceOscillators(params)
    }
    
    /// Apply filter parameters to all voices
    private func applyFilterToAllVoices() {
        let params = voiceTemplate.filter
        for voice in voicePool?.voices ?? [] {
            voice.updateFilterParameters(params)
        }
    }

    
    // MARK: - Preset Management
    
    /// Load a complete parameter set (preset)
    func loadPreset(_ preset: AudioParameterSet) {
        voiceTemplate = preset.voiceTemplate
        master = preset.master
        macroState = preset.macroState
        
        applyAllParameters()
    }
    
    /// Create a preset from current parameters
    func createPreset(named name: String) -> AudioParameterSet {
        AudioParameterSet(
            id: UUID(),
            name: name,
            voiceTemplate: voiceTemplate,
            master: master,
            macroState: macroState,
            createdAt: Date()
        )
    }
    
    // MARK: - Application to AudioKit
    
    /// Apply all parameters to the audio engine
    private func applyAllParameters() {
        applyDelayParameters()
        applyReverbParameters()
    }
    
    private func applyDelayParameters() {
        guard let delay = fxDelay else { return }
        // Calculate time in seconds based on current tempo
        let timeInSeconds = master.delay.timeInSeconds(tempo: master.tempo)
        delay.time = AUValue(timeInSeconds)
        delay.feedback = AUValue(master.delay.feedback)
        delay.dryWetMix = AUValue(master.delay.dryWetMix)
    }
    
    private func applyReverbParameters() {
        guard let reverb = fxReverb else { return }
        reverb.feedback = AUValue(master.reverb.feedback)
        reverb.cutoffFrequency = AUValue(master.reverb.cutoffFrequency)
        reverb.balance = AUValue(master.reverb.balance)
    }
}
