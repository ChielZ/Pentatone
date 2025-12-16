//
//  AudioParameters.swift
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
    var modulatingMultiplier: Double
    var modulationIndex: Double
    var amplitude: Double
    var waveform: OscillatorWaveform
    
    static let `default` = OscillatorParameters(
        carrierMultiplier: 1.0,
        modulatingMultiplier: 2.0,
        modulationIndex: 0.95,
        amplitude: 0.15,
        waveform: .sine
    )
}

/// Parameters for the low-pass filter
struct FilterParameters: Codable, Equatable {
    var cutoffFrequency: Double
    var resonance: Double
    
    static let `default` = FilterParameters(
        cutoffFrequency: 8800,
        resonance: 0.0
    )
    
    /// Clamps cutoff to valid range (20 Hz - 20 kHz)
    var clampedCutoff: Double {
        min(max(cutoffFrequency, 20), 20_000)
    }
}

/// Parameters for the amplitude envelope
struct EnvelopeParameters: Codable, Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    
    static let `default` = EnvelopeParameters(
        attackDuration: 0.02,
        decayDuration: 0.5,
        sustainLevel: 0.0,
        releaseDuration: 0.02
    )
}

/// Parameters for stereo panning (-1 = left, 0 = center, +1 = right)
struct PanParameters: Codable, Equatable {
    var pan: Double
    
    static let `default` = PanParameters(pan: 0.0)
    
    /// Clamps pan to valid range
    var clampedPan: Double {
        min(max(pan, -1.0), 1.0)
    }
}

/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters
    var envelope: EnvelopeParameters
    var pan: PanParameters
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        envelope: .default,
        pan: .default
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
        dryWetMix: 0.5,
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
        dryWetBalance: 0.3
    )
}

/// Master parameters affecting the entire audio engine
struct MasterParameters: Codable, Equatable {
    var delay: DelayParameters
    var reverb: ReverbParameters
    
    static let `default` = MasterParameters(
        delay: .default,
        reverb: .default
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
    
    /// Per-voice parameter overrides (indexed 0-17 for 18 voices)
    /// These are temporary overrides that don't affect the template
    private var voiceOverrides: [Int: VoiceParameters] = [:]
    
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
        fxDelay?.dryWetMix = AUValue(mix)
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
    
    /// Update the voice template (affects all voices unless individually overridden)
    func updateVoiceTemplate(_ parameters: VoiceParameters) {
        voiceTemplate = parameters
        applyTemplateToAllVoices()
    }
    
    func updateTemplateFilter(_ parameters: FilterParameters) {
        voiceTemplate.filter = parameters
        applyTemplateToAllVoices()
    }
    
    func updateTemplateOscillator(_ parameters: OscillatorParameters) {
        voiceTemplate.oscillator = parameters
        applyTemplateToAllVoices()
    }
    
    func updateTemplateEnvelope(_ parameters: EnvelopeParameters) {
        voiceTemplate.envelope = parameters
        applyTemplateToAllVoices()
    }
    
    // MARK: - Per-Voice Parameter Updates
    
    /// Update parameters for a specific voice (temporary override)
    /// - Parameters:
    ///   - voiceIndex: Voice index (0-17)
    ///   - parameters: Complete voice parameters
    func updateVoice(at voiceIndex: Int, parameters: VoiceParameters) {
        guard (0..<18).contains(voiceIndex) else { return }
        voiceOverrides[voiceIndex] = parameters
        applyParametersToVoice(at: voiceIndex, parameters: parameters)
    }
    
    /// Update just the filter for a specific voice
    /// Useful for touch position → filter cutoff mapping
    func updateVoiceFilter(at voiceIndex: Int, parameters: FilterParameters) {
        guard (0..<18).contains(voiceIndex) else { return }
        
        var voiceParams = voiceOverrides[voiceIndex] ?? voiceTemplate
        voiceParams.filter = parameters
        voiceOverrides[voiceIndex] = voiceParams
        
        if let voice = getVoice(at: voiceIndex) {
            voice.filter.cutoffFrequency = AUValue(parameters.clampedCutoff)
            voice.filter.resonance = AUValue(parameters.resonance)
        }
    }
    
    /// Update filter cutoff for a specific voice based on normalized position (0-1)
    /// Example: map horizontal touch position to filter frequency
    func updateVoiceFilterCutoff(at voiceIndex: Int, normalizedValue: Double) {
        guard (0..<18).contains(voiceIndex) else { return }
        
        // Map 0-1 to reasonable filter range (200 Hz - 12 kHz)
        let minFreq = 200.0
        let maxFreq = 12_000.0
        let cutoff = minFreq + (normalizedValue * (maxFreq - minFreq))
        
        var voiceParams = voiceOverrides[voiceIndex] ?? voiceTemplate
        voiceParams.filter.cutoffFrequency = cutoff
        voiceOverrides[voiceIndex] = voiceParams
        
        if let voice = getVoice(at: voiceIndex) {
            voice.filter.cutoffFrequency = AUValue(cutoff)
        }
    }
    
    /// Update pan for a specific voice
    func updateVoicePan(at voiceIndex: Int, pan: Double) {
        guard (0..<18).contains(voiceIndex) else { return }
        
        var voiceParams = voiceOverrides[voiceIndex] ?? voiceTemplate
        voiceParams.pan.pan = pan
        voiceOverrides[voiceIndex] = voiceParams
        
        if let voice = getVoice(at: voiceIndex) {
            voice.pan.pan = AUValue(voiceParams.pan.clampedPan)
        }
    }
    
    /// Clear all per-voice overrides (revert to template)
    func clearVoiceOverrides() {
        voiceOverrides.removeAll()
        applyTemplateToAllVoices()
    }
    
    /// Clear override for a specific voice
    func clearVoiceOverride(at voiceIndex: Int) {
        guard (0..<18).contains(voiceIndex) else { return }
        voiceOverrides.removeValue(forKey: voiceIndex)
        applyParametersToVoice(at: voiceIndex, parameters: voiceTemplate)
    }
    
    // MARK: - Preset Management
    
    /// Load a complete parameter set (preset)
    func loadPreset(_ preset: AudioParameterSet) {
        voiceTemplate = preset.voiceTemplate
        master = preset.master
        
        // Clear overrides and apply template
        voiceOverrides.removeAll()
        
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
        applyTemplateToAllVoices()
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
    
    private func applyTemplateToAllVoices() {
        for i in 0..<18 {
            // Only apply template if no override exists
            if voiceOverrides[i] == nil {
                applyParametersToVoice(at: i, parameters: voiceTemplate)
            }
        }
    }
    
    private func applyParametersToVoice(at index: Int, parameters: VoiceParameters) {
        guard let voice = getVoice(at: index) else { return }
        
        // Apply oscillator parameters
        voice.osc.carrierMultiplier = AUValue(parameters.oscillator.carrierMultiplier)
        voice.osc.modulatingMultiplier = AUValue(parameters.oscillator.modulatingMultiplier)
        voice.osc.modulationIndex = AUValue(parameters.oscillator.modulationIndex)
        voice.osc.amplitude = AUValue(parameters.oscillator.amplitude)
        
        // Note: Waveform changes require voice recreation (handled by OscVoice.updateWaveform)
        voice.updateWaveformIfNeeded(parameters.oscillator.waveform)
        
        // Apply filter parameters
        voice.filter.cutoffFrequency = AUValue(parameters.filter.clampedCutoff)
        voice.filter.resonance = AUValue(parameters.filter.resonance)
        
        // Apply envelope parameters
        voice.voiceEnv.attackDuration = AUValue(parameters.envelope.attackDuration)
        voice.voiceEnv.decayDuration = AUValue(parameters.envelope.decayDuration)
        voice.voiceEnv.sustainLevel = AUValue(parameters.envelope.sustainLevel)
        voice.voiceEnv.releaseDuration = AUValue(parameters.envelope.releaseDuration)
        
        // Apply pan
        voice.pan.pan = AUValue(parameters.pan.clampedPan)
    }
    
    // MARK: - Voice Access Helper
    
    private func getVoice(at index: Int) -> OscVoice? {
        switch index {
        case 0: return oscillator01
        case 1: return oscillator02
        case 2: return oscillator03
        case 3: return oscillator04
        case 4: return oscillator05
        case 5: return oscillator06
        case 6: return oscillator07
        case 7: return oscillator08
        case 8: return oscillator09
        case 9: return oscillator10
        case 10: return oscillator11
        case 11: return oscillator12
        case 12: return oscillator13
        case 13: return oscillator14
        case 14: return oscillator15
        case 15: return oscillator16
        case 16: return oscillator17
        case 17: return oscillator18
        default: return nil
        }
    }
}

// MARK: - Convenience Extensions

extension AudioParameterManager {
    
    /// Get the effective parameters for a voice (considering overrides)
    func effectiveParameters(for voiceIndex: Int) -> VoiceParameters {
        voiceOverrides[voiceIndex] ?? voiceTemplate
    }
    
    /// Check if a voice has an override
    func hasOverride(for voiceIndex: Int) -> Bool {
        voiceOverrides[voiceIndex] != nil
    }
}

// MARK: - Touch Position Mapping Helpers

extension AudioParameterManager {
    
    /// Maps a touch location to filter cutoff frequency for a voice
    /// - Parameters:
    ///   - voiceIndex: The voice to modify (0-17)
    ///   - touchX: The x position of the touch in the view's coordinate space
    ///   - viewWidth: The total width of the touchable area
    ///   - range: Optional custom frequency range (default: 200-12000 Hz)
    func mapTouchToFilterCutoff(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat,
        range: ClosedRange<Double> = 200...12_000
    ) {
        guard viewWidth > 0 else { return }
        let normalized = max(0, min(1, touchX / viewWidth))
        let cutoff = range.lowerBound + (normalized * (range.upperBound - range.lowerBound))
        updateVoiceFilterCutoff(at: voiceIndex, normalizedValue: (cutoff - range.lowerBound) / (range.upperBound - range.lowerBound))
    }
    
    /// Maps a touch location to pan position for a voice
    /// - Parameters:
    ///   - voiceIndex: The voice to modify (0-17)
    ///   - touchX: The x position of the touch in the view's coordinate space
    ///   - viewWidth: The total width of the touchable area
    func mapTouchToPan(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat
    ) {
        guard viewWidth > 0 else { return }
        let normalized = max(0, min(1, touchX / viewWidth))
        // Map 0...1 to -1...1 (left to right)
        let pan = (normalized * 2.0) - 1.0
        updateVoicePan(at: voiceIndex, pan: pan)
    }
    
    /// Maps touch Y position to resonance (experimental - useful for 2D touch control)
    /// - Parameters:
    ///   - voiceIndex: The voice to modify (0-17)
    ///   - touchY: The y position of the touch in the view's coordinate space
    ///   - viewHeight: The total height of the touchable area
    ///   - range: Optional custom resonance range (default: 0-0.9)
    func mapTouchToResonance(
        voiceIndex: Int,
        touchY: CGFloat,
        viewHeight: CGFloat,
        range: ClosedRange<Double> = 0...0.9
    ) {
        guard viewHeight > 0 else { return }
        // Invert Y so bottom = low, top = high
        let normalized = max(0, min(1, 1.0 - (touchY / viewHeight)))
        let resonance = range.lowerBound + (normalized * (range.upperBound - range.lowerBound))
        
        var voiceParams = voiceOverrides[voiceIndex] ?? voiceTemplate
        voiceParams.filter.resonance = resonance
        voiceOverrides[voiceIndex] = voiceParams
        
        if let voice = getVoice(at: voiceIndex) {
            voice.filter.resonance = AUValue(resonance)
        }
    }
}

