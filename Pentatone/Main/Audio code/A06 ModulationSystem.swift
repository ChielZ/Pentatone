//
//  ModulationSystem.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit

// MARK: - Modulation Destinations

/// Defines where modulation can be routed
enum ModulationDestination: String, Codable, CaseIterable {
    // Oscillator destinations
    case oscillatorAmplitude         // Amplitude of both oscillators
    case oscillatorBaseFrequency     // Base frequency (pitch modulation)
    case modulationIndex             // FM modulation depth (timbral)
    case modulatingMultiplier        // FM modulator frequency ratio
    
    // Filter destinations
    case filterCutoff                // Low-pass filter cutoff frequency
    
    // Stereo/Voice destinations
    case stereoSpreadAmount          // Detune/spread between left and right oscillators
    
    // Voice LFO destinations (for envelope/tracking to modulate LFO itself)
    case voiceLFOFrequency           // Rate of the per-voice LFO
    case voiceLFOAmount              // Depth of the per-voice LFO
    
    // Global/FX destinations (only global sources can target these)
    case delayTime                   // Delay time in seconds
    case delayMix                    // Delay wet/dry mix
    
    /// Returns true if this destination can be modulated by per-voice sources
    var isVoiceLevel: Bool {
        switch self {
        case .oscillatorAmplitude, .oscillatorBaseFrequency, .modulationIndex, .modulatingMultiplier,
             .filterCutoff, .stereoSpreadAmount, .voiceLFOFrequency, .voiceLFOAmount:
            return true
        case .delayTime, .delayMix:
            return false
        }
    }
    
    /// Returns true if this destination can be modulated by global sources
    var isGlobalLevel: Bool {
        return true  // Global sources can target anything
    }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .oscillatorAmplitude: return "Oscillator Amplitude"
        case .oscillatorBaseFrequency: return "Oscillator Frequency"
        case .modulationIndex: return "Modulation Index"
        case .modulatingMultiplier: return "Modulator Multiplier"
        case .filterCutoff: return "Filter Cutoff"
        case .stereoSpreadAmount: return "Stereo Spread"
        case .voiceLFOFrequency: return "Voice LFO Rate"
        case .voiceLFOAmount: return "Voice LFO Depth"
        case .delayTime: return "Delay Time"
        case .delayMix: return "Delay Mix"
        }
    }
}

// MARK: - LFO Waveforms

/// Waveform shapes available for LFO modulation
enum LFOWaveform: String, Codable, CaseIterable {
    case sine
    case triangle
    case square
    case sawtooth
    case reverseSawtooth
    
    var displayName: String {
        switch self {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .sawtooth: return "Sawtooth"
        case .reverseSawtooth: return "Reverse Saw"
        }
    }
}

// MARK: - LFO Reset Mode

/// Determines how LFO phase is reset when a voice is triggered
enum LFOResetMode: String, Codable, CaseIterable {
    case free       // LFO runs continuously, ignores note triggers
    case trigger    // LFO resets to phase 0 on each note trigger
    case sync       // LFO syncs to tempo (global timing)
    
    var displayName: String {
        switch self {
        case .free: return "Free Running"
        case .trigger: return "Trigger Reset"
        case .sync: return "Tempo Sync"
        }
    }
}

// MARK: - LFO Frequency Mode

/// Determines whether LFO frequency is in Hz or tempo-synced
enum LFOFrequencyMode: String, Codable, CaseIterable {
    case hertz          // Direct Hz value (0-10 Hz)
    case tempoSync      // Tempo multiplier (1/4, 1/2, 1, 2, 4, etc.)
    
    var displayName: String {
        switch self {
        case .hertz: return "Hz"
        case .tempoSync: return "Tempo Sync"
        }
    }
}

// MARK: - LFO Parameters

/// Represents a low-frequency oscillator for modulation
/// This is a data structure for Phase 5 implementation
struct LFOParameters: Codable, Equatable {
    var waveform: LFOWaveform
    var resetMode: LFOResetMode
    var frequencyMode: LFOFrequencyMode
    var frequency: Double               // Hz (0.01 - 10 Hz) or tempo multiplier depending on mode
    var destination: ModulationDestination
    var amount: Double                  // Bipolar modulation amount (0.0 - 1.0, always positive)
    var isEnabled: Bool
    
    static let `default` = LFOParameters(
        waveform: .sine,
        resetMode: .free,
        frequencyMode: .hertz,
        frequency: 2.0,
        destination: .oscillatorBaseFrequency,
        amount: 0.0,
        isEnabled: false
    )
    
    // Phase 5B/5C: Will implement actual LFO value generation
    // For now, this is just a placeholder structure
    func currentValue(phase: Double) -> Double {
        // TODO: Phase 5C - Implement actual LFO oscillation
        // Will use manual waveform calculation based on phase
        return 0.0
    }
}

// MARK: - Modulation Envelope

/// Represents an ADSR envelope generator for modulation (not amplitude)
/// This is separate from the amplitude envelope and can modulate parameters over time
struct ModulationEnvelopeParameters: Codable, Equatable {
    var attack: Double                    // Attack time in seconds
    var decay: Double                     // Decay time in seconds
    var sustain: Double                   // Sustain level (0.0 - 1.0)
    var release: Double                   // Release time in seconds
    var destination: ModulationDestination
    var amount: Double                    // Unipolar modulation amount (-1.0 to +1.0)
    var isEnabled: Bool
    
    static let `default` = ModulationEnvelopeParameters(
        attack: 0.1,
        decay: 0.2,
        sustain: 0.5,
        release: 0.3,
        destination: .filterCutoff,
        amount: 0.0,
        isEnabled: false
    )
    
    /// Calculate the current envelope value based on time and gate state
    /// Returns a value from 0.0 to 1.0 representing the envelope stage
    func currentValue(timeInEnvelope: Double, isGateOpen: Bool) -> Double {
        guard isEnabled else { return 0.0 }
        
        if isGateOpen {
            // Gate is open - process attack, decay, sustain stages
            if timeInEnvelope < attack {
                // Attack stage: linear rise from 0 to 1
                return timeInEnvelope / attack
            } else if timeInEnvelope < (attack + decay) {
                // Decay stage: linear fall from 1 to sustain level
                let decayTime = timeInEnvelope - attack
                let decayProgress = decayTime / decay
                return 1.0 - (decayProgress * (1.0 - sustain))
            } else {
                // Sustain stage: hold at sustain level
                return sustain
            }
        } else {
            // Gate is closed - process release stage
            // timeInEnvelope is time since gate closed
            // NOTE: We should release from the captured sustain level, not the configured one
            // The captured level is passed via the ModulationState.modulatorSustainLevel
            // This is handled in PolyphonicVoice.release() when closeGate is called
            
            // For now, return the sustain level as placeholder
            // The actual release calculation will use the captured level
            return sustain
        }
    }
    
    /// Calculate release value from a captured level
    /// - Parameters:
    ///   - timeInRelease: Time since gate closed
    ///   - capturedLevel: The envelope level when gate closed
    /// - Returns: Current envelope value during release
    func releaseValue(timeInRelease: Double, fromLevel capturedLevel: Double) -> Double {
        guard isEnabled else { return 0.0 }
        
        if timeInRelease < release {
            // Release stage: linear fall from captured level to 0
            let releaseProgress = timeInRelease / release
            return capturedLevel * (1.0 - releaseProgress)
        } else {
            // Release complete
            return 0.0
        }
    }
    
    /// Returns true if the envelope has completed (reached 0 in release)
    func isComplete(timeInEnvelope: Double, isGateOpen: Bool) -> Bool {
        return !isGateOpen && timeInEnvelope >= release
    }
}

// MARK: - Key Tracking

/// Key tracking provides modulation based on the pitch of the triggered note
/// Higher notes produce higher modulation values
struct KeyTrackingParameters: Codable, Equatable {
    var destination: ModulationDestination
    var amount: Double                    // Unipolar modulation amount (-1.0 to +1.0)
    var isEnabled: Bool
    
    static let `default` = KeyTrackingParameters(
        destination: .filterCutoff,
        amount: 0.0,
        isEnabled: false
    )
    
    /// Calculate key tracking value based on frequency
    /// Returns a value from 0.0 (low note) to 1.0 (high note)
    /// Reference: 440 Hz (A4) maps to 0.5
    func trackingValue(forFrequency frequency: Double) -> Double {
        // Logarithmic mapping: each octave adds a fixed amount
        // Reference point: 440 Hz = 0.5
        // Range: ~55 Hz (A1) = 0.0 to ~3520 Hz (A7) = 1.0
        let referenceFreq = 440.0  // A4
        let octavesFromReference = log2(frequency / referenceFreq)
        let normalizedValue = 0.5 + (octavesFromReference / 6.0)  // 6 octaves = full range
        return max(0.0, min(1.0, normalizedValue))
    }
}

// MARK: - Touch Modulation

/// Touch modulation from initial touch X position
/// The X coordinate where the key was first touched
struct TouchInitialParameters: Codable, Equatable {
    var destination: ModulationDestination
    var amount: Double                    // Unipolar modulation amount (-1.0 to +1.0)
    var isEnabled: Bool
    
    static let `default` = TouchInitialParameters(
        destination: .filterCutoff,
        amount: 0.0,
        isEnabled: false
    )
}

/// Aftertouch modulation from change in X position while holding
/// Tracks movement of the finger while the key is held
struct TouchAftertouchParameters: Codable, Equatable {
    var destination: ModulationDestination
    var amount: Double                    // Bipolar modulation amount (0.0 - 1.0, always positive)
    var isEnabled: Bool
    // TODO: Consider adding mode (relative/absolute) in future
    
    static let `default` = TouchAftertouchParameters(
        destination: .oscillatorAmplitude,
        amount: 0.0,
        isEnabled: false
    )
}

// MARK: - Complete Modulation System Parameters

/// Container for all modulation sources and routings for a single voice
/// This will be integrated into VoiceParameters in Phase 5B+
struct VoiceModulationParameters: Codable, Equatable {
    // Envelopes
    var modulatorEnvelope: ModulationEnvelopeParameters    // Hardwired to modulationIndex (5B)
    var auxiliaryEnvelope: ModulationEnvelopeParameters    // Routable (5B)
    
    // LFO
    var voiceLFO: LFOParameters                            // Per-voice LFO (5C)
    
    // Touch/Key tracking
    var keyTracking: KeyTrackingParameters                 // Frequency-based modulation (5D)
    var touchInitial: TouchInitialParameters               // Initial touch X position (5D)
    var touchAftertouch: TouchAftertouchParameters         // Aftertouch X movement (5D)
    
    static let `default` = VoiceModulationParameters(
        modulatorEnvelope: ModulationEnvelopeParameters(
            attack: 0.01,
            decay: 0.2,
            sustain: 0.3,
            release: 0.1,
            destination: .modulationIndex,  // Hardwired
            amount: 0.0,
            isEnabled: false
        ),
        auxiliaryEnvelope: ModulationEnvelopeParameters(
            attack: 0.1,
            decay: 0.2,
            sustain: 0.5,
            release: 0.3,
            destination: .filterCutoff,     // Default, but routable
            amount: 0.0,
            isEnabled: false
        ),
        voiceLFO: .default,
        keyTracking: .default,
        touchInitial: .default,
        touchAftertouch: .default
    )
}

/// Global LFO that affects all voices (or global parameters)
/// Lives in VoicePool or AudioEngine, not in individual voices
struct GlobalLFOParameters: Codable, Equatable {
    var waveform: LFOWaveform
    var resetMode: LFOResetMode             // Free or Sync (no trigger for global)
    var frequencyMode: LFOFrequencyMode
    var frequency: Double                   // Hz (0.01 - 10 Hz) or tempo multiplier
    var destination: ModulationDestination
    var amount: Double                      // Bipolar modulation amount (0.0 - 1.0)
    var isEnabled: Bool
    
    static let `default` = GlobalLFOParameters(
        waveform: .sine,
        resetMode: .free,
        frequencyMode: .hertz,
        frequency: 1.0,
        destination: .oscillatorAmplitude,
        amount: 0.0,
        isEnabled: false
    )
    
    // Phase 5C: Will implement actual LFO value generation
    func currentValue(phase: Double) -> Double {
        // TODO: Phase 5C - Implement actual LFO oscillation
        return 0.0
    }
}

// MARK: - Modulation State (Runtime)

/// Runtime state for modulation calculation
/// This tracks the current state of modulation sources during voice playback
/// Not part of presets (ephemeral state)
struct ModulationState {
    // Envelope timing
    var modulatorEnvelopeTime: Double = 0.0
    var auxiliaryEnvelopeTime: Double = 0.0
    var isGateOpen: Bool = false
    
    // Track sustain level at gate close for proper release
    var modulatorSustainLevel: Double = 0.0
    var auxiliarySustainLevel: Double = 0.0
    
    // LFO phase tracking
    var voiceLFOPhase: Double = 0.0        // 0.0 - 1.0 (one full cycle)
    
    // Touch state
    var initialTouchX: Double = 0.0        // Normalized 0.0 - 1.0
    var currentTouchX: Double = 0.0        // Normalized 0.0 - 1.0
    
    // Key tracking
    var currentFrequency: Double = 440.0   // Current note frequency
    
    /// Reset state when voice is triggered
    mutating func reset(frequency: Double, touchX: Double) {
        modulatorEnvelopeTime = 0.0
        auxiliaryEnvelopeTime = 0.0
        isGateOpen = true
        modulatorSustainLevel = 0.0
        auxiliarySustainLevel = 0.0
        voiceLFOPhase = 0.0
        initialTouchX = touchX
        currentTouchX = touchX
        currentFrequency = frequency
    }
    
    /// Update state when gate closes (note released)
    /// Captures current envelope values for smooth release
    mutating func closeGate(modulatorValue: Double, auxiliaryValue: Double) {
        isGateOpen = false
        modulatorSustainLevel = modulatorValue
        auxiliarySustainLevel = auxiliaryValue
        // Reset envelope times to 0 for release stage
        modulatorEnvelopeTime = 0.0
        auxiliaryEnvelopeTime = 0.0
    }
}

// MARK: - Global Modulation State (Runtime)

/// Runtime state for global modulation
struct GlobalModulationState {
    var globalLFOPhase: Double = 0.0       // 0.0 - 1.0 (one full cycle)
    var currentTempo: Double = 120.0       // BPM for tempo sync
}

// MARK: - Modulation Router

/// Helper for calculating and applying modulation to destinations
/// This will be used in Phase 5B+ to route modulation values to parameters
struct ModulationRouter {
    
    /// Apply modulation amount to a base value
    /// - Parameters:
    ///   - baseValue: The unmodulated parameter value
    ///   - envelopeValue: The envelope value (0.0 - 1.0)
    ///   - amount: The modulation amount (-1.0 to +1.0 for unipolar)
    ///   - destination: The destination being modulated
    /// - Returns: The modulated value
    static func applyEnvelopeModulation(
        baseValue: Double,
        envelopeValue: Double,
        amount: Double,
        destination: ModulationDestination
    ) -> Double {
        // Calculate the modulation offset
        let modOffset = envelopeValue * amount
        
        // Apply destination-specific scaling
        switch destination {
        case .modulationIndex:
            // FM modulation index: clamp to 0-10 range (typical FM range)
            return max(0.0, min(10.0, baseValue + modOffset))
            
        case .filterCutoff:
            // Filter cutoff: exponential scaling (octaves)
            // amount = 1.0 means +1 octave at envelope peak
            let octaves = modOffset  // amount controls octave range
            let multiplier = pow(2.0, octaves)
            return max(20.0, min(22050.0, baseValue * multiplier))
            
        case .oscillatorAmplitude:
            // Amplitude: linear scaling, clamp to 0-1
            return max(0.0, min(1.0, baseValue + modOffset))
            
        case .oscillatorBaseFrequency:
            // Frequency: exponential scaling (semitones)
            // amount = 1.0 means +12 semitones (1 octave) at envelope peak
            let semitones = modOffset * 12.0  // amount controls semitone range
            let multiplier = pow(2.0, semitones / 12.0)
            return baseValue * multiplier
            
        case .modulatingMultiplier:
            // FM modulator ratio: linear scaling
            return max(0.1, min(20.0, baseValue + modOffset))
            
        case .stereoSpreadAmount:
            // Stereo spread: depends on detune mode
            // For now, treat as linear offset
            return max(0.0, baseValue + modOffset)
            
        case .voiceLFOFrequency, .voiceLFOAmount:
            // LFO parameters: linear scaling
            return max(0.0, baseValue + modOffset)
            
        case .delayTime, .delayMix:
            // These shouldn't be modulated by voice envelopes
            return baseValue
        }
    }
    
    /// Calculate the scaling factor for a destination
    /// Used to determine the effective range of modulation
    static func getModulationRange(for destination: ModulationDestination) -> Double {
        switch destination {
        case .modulationIndex:
            return 10.0  // 0-10 is typical FM range
        case .filterCutoff:
            return 2.0   // ±2 octaves
        case .oscillatorAmplitude:
            return 1.0   // 0-1
        case .oscillatorBaseFrequency:
            return 12.0  // ±1 octave in semitones
        case .modulatingMultiplier:
            return 20.0  // Wide range for FM ratios
        case .stereoSpreadAmount:
            return 2.0   // Reasonable spread range
        case .voiceLFOFrequency:
            return 10.0  // LFO rate range
        case .voiceLFOAmount:
            return 1.0   // LFO depth 0-1
        case .delayTime:
            return 2.0   // ±2 seconds
        case .delayMix:
            return 1.0   // 0-1
        }
    }
}

// MARK: - Control Rate Timer Configuration

/// Configuration for the modulation control-rate update loop
/// Phase 5B will implement the actual timer
struct ControlRateConfig {
    /// Update rate for modulation calculations in Hz
    /// 200 Hz = 5ms updates = smooth LFOs and snappy envelopes
    static let updateRate: Double = 200.0
    
    /// Update interval in seconds
    static let updateInterval: Double = 1.0 / updateRate
    
    /// Update interval in nanoseconds (for Timer use)
    static let updateIntervalNanoseconds: UInt64 = UInt64(updateInterval * 1_000_000_000)
}
