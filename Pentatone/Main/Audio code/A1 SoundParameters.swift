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
        resonance: 1.5,
        saturation: 0.0
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
        modulation: VoiceModulationParameters(
            modulatorEnvelope: ModulationEnvelopeParameters(
                attack: 0.01,
                decay: 0.2,
                sustain: 0.3,
                release: 0.1,
                destination: .modulationIndex,
                amount: 0.0,
                isEnabled: false
            ),
            auxiliaryEnvelope: ModulationEnvelopeParameters(
                attack: 0.1,
                decay: 0.2,
                sustain: 0.5,
                release: 0.3,
                destination: .filterCutoff,
                amount: 0.0,
                isEnabled: false
            ),
            voiceLFO: LFOParameters(
                waveform: .square,
                resetMode: .free,
                frequencyMode: .hertz,
                frequency: 6.0,
                destination: .oscillatorAmplitude,
                amount: 0.0,                         // Disabled by default
                isEnabled: true
            ),
            keyTracking: .default,
            touchInitial: TouchInitialParameters(
                destination: .oscillatorAmplitude,   // Touch X controls amplitude
                amount: 0.0,                         // Full range (0.0 to 1.0)
                isEnabled: true                      // Standard touch control
            ),
            touchAftertouch: TouchAftertouchParameters(
                destination: .filterCutoff,          // Aftertouch controls filter
                amount: 0.0,                         // Moderate sensitivity
                isEnabled: true                      // Standard aftertouch control
            )
        )
    )
}

/// Parameters for the stereo delay effect
struct DelayParameters: Codable, Equatable {
    var time: Double
    var feedback: Double
    var dryWetMix: Double
    var pingPong: Bool
    
    static let `default` = DelayParameters(
        time: 0.5,
        feedback: 0.2,
        dryWetMix: 0.0,
        pingPong: true
    )
}

/// Parameters for the reverb effect
struct ReverbParameters: Codable, Equatable {
    var feedback: Double
    var cutoffFrequency: Double
    var dryWetBalance: Double  // 0 = all dry, 1 = all wet
    
    static let `default` = ReverbParameters(
        feedback: 0.9,
        cutoffFrequency: 10_000,
        dryWetBalance: 0.0
    )
}

/// Master parameters affecting the entire audio engine
struct MasterParameters: Codable, Equatable {
    var delay: DelayParameters
    var reverb: ReverbParameters
    var globalLFO: GlobalLFOParameters     // Phase 5C: Global modulation
    var tempo: Double                      // BPM for tempo-synced modulation
    
    static let `default` = MasterParameters(
        delay: .default,
        reverb: .default,
        globalLFO: GlobalLFOParameters(
            waveform: .sine,
            resetMode: .free,
            frequencyMode: .hertz,
            frequency: 1.5,                    // 1.5 Hz slow wobble
            destination: .delayTime, // ← CHANGE THIS to test different destinations
            amount: 0.0,                       // ← CHANGE THIS (0.0 = off, 1.0 = max)
            isEnabled: false                    // ← SET TO false TO DISABLE
        ),
        tempo: 120.0
    )
}

// MARK: - Complete Parameter Set (for Presets)

/// A complete snapshot of all audio parameters - used for presets
struct AudioParameterSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters  // Template applied to all voices
    var master: MasterParameters
    var createdAt: Date
    
    static let `default` = AudioParameterSet(
        id: UUID(),
        name: "Default",
        voiceTemplate: .default,
        master: .default,
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
    
    func updateDelayTime(_ time: Double) {
        master.delay.time = time
        fxDelay?.time = AUValue(time)
    }
    
    func updateDelayFeedback(_ feedback: Double) {
        master.delay.feedback = feedback
        fxDelay?.feedback = AUValue(feedback)
    }
    
    func updateReverb(_ parameters: ReverbParameters) {
        master.reverb = parameters
        applyReverbParameters()
    }
    
    func updateReverbMix(_ balance: Double) {
        master.reverb.dryWetBalance = balance
        reverbDryWet?.balance = AUValue(balance)
    }
    
    func updateReverbFeedback(_ feedback: Double) {
        master.reverb.feedback = feedback
        fxReverb?.feedback = AUValue(feedback)
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
    
    // MARK: - Preset Management
    
    /// Load a complete parameter set (preset)
    func loadPreset(_ preset: AudioParameterSet) {
        voiceTemplate = preset.voiceTemplate
        master = preset.master
        
        applyAllParameters()
    }
    
    /// Create a preset from current parameters
    func createPreset(named name: String) -> AudioParameterSet {
        AudioParameterSet(
            id: UUID(),
            name: name,
            voiceTemplate: voiceTemplate,
            master: master,
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
        delay.time = AUValue(master.delay.time)
        delay.feedback = AUValue(master.delay.feedback)
        delay.dryWetMix = AUValue(master.delay.dryWetMix)
    }
    
    private func applyReverbParameters() {
        guard let reverb = fxReverb, let dryWet = reverbDryWet else { return }
        reverb.feedback = AUValue(master.reverb.feedback)
        reverb.cutoffFrequency = AUValue(master.reverb.cutoffFrequency)
        dryWet.balance = AUValue(master.reverb.dryWetBalance)
    }
}
