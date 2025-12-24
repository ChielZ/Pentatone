//
//  Phase5B_EnvelopeTests.swift
//  Pentatone
//
//  Created for testing Phase 5B modulation envelopes
//


import Foundation
import AudioKit

/// Test configurations for Phase 5B envelope modulation
enum EnvelopeTestPresets {
    
    // MARK: - Test 1: Classic FM Bell
    
    /// Bell-like FM sound with bright attack, quick decay to mellow tone
    static var fmBell: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Modulator envelope → modulationIndex (hardwired)
        params.modulatorEnvelope = ModulationEnvelopeParameters(
            attack: 1.5,       // Instant bright attack
            decay: 2.3,          // Fast decay
            sustain: 0.0,        // Low sustain (mellow)
            release: 1.5,        // Medium release
            destination: .modulationIndex,
            amount: 8.0,         // Strong modulation (0 to 8)
            isEnabled: true
        )
        
        // Disable auxiliary envelope for this test
        params.auxiliaryEnvelope.isEnabled = false
        
        return params
    }
    
    // MARK: - Test 2: Filter Sweep
    
    /// Classic analog filter sweep (bright to dark)
    static var filterSweep: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Disable modulator envelope for this test
        params.modulatorEnvelope.isEnabled = false
        
        // Auxiliary envelope → filter cutoff
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 0.05,        // Quick open
            decay: 0.8,          // Slow close
            sustain: 0.2,        // Mostly closed
            release: 1.0,        // Slow release
            destination: .filterCutoff,
            amount: 2.0,         // 2 octaves sweep
            isEnabled: true
        )
        
        return params
    }
    
    // MARK: - Test 3: Combined Evolution
    
    /// Complex timbre with both FM and filter evolution
    static var combinedEvolution: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Modulator: Fast bright attack, quick decay
        params.modulatorEnvelope = ModulationEnvelopeParameters(
            attack: 0.01,
            decay: 0.2,
            sustain: 0.3,
            release: 0.4,
            destination: .modulationIndex,
            amount: 6.0,
            isEnabled: true
        )
        
        // Auxiliary: Slow filter sweep
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 0.1,
            decay: 1.0,
            sustain: 0.5,
            release: 0.8,
            destination: .filterCutoff,
            amount: 1.5,
            isEnabled: true
        )
        
        return params
    }
    
    // MARK: - Test 4: Pitch Drop
    
    /// 808-style pitch drop effect
    static var pitchDrop: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Disable modulator envelope
        params.modulatorEnvelope.isEnabled = false
        
        // Auxiliary: Pitch drop
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 0.01,        // Instant start high
            decay: 0.5,          // Drop over 500ms
            sustain: 0.0,        // End at base pitch
            release: 1.2,
            destination: .oscillatorBaseFrequency,
            amount: 0.5,         // +6 semitones (half octave)
            isEnabled: true
        )
        
        return params
    }
    
    // MARK: - Test 5: Brass-like
    
    /// Brass instrument simulation
    static var brass: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Modulator: Moderate attack, sustained brightness
        params.modulatorEnvelope = ModulationEnvelopeParameters(
            attack: 0.08,        // Slightly slow attack
            decay: 0.2,
            sustain: 0.6,        // Fairly bright sustain
            release: 0.3,
            destination: .modulationIndex,
            amount: 5.0,
            isEnabled: true
        )
        
        // Auxiliary: Filter opens with attack
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 0.08,        // Match modulator attack
            decay: 0.3,
            sustain: 0.7,        // Keep filter fairly open
            release: 0.3,
            destination: .filterCutoff,
            amount: 1.0,         // 1 octave sweep
            isEnabled: true
        )
        
        return params
    }
    
    // MARK: - Test 6: Pluck
    
    /// Plucked string simulation
    static var pluck: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Modulator: Instant attack, very fast decay
        params.modulatorEnvelope = ModulationEnvelopeParameters(
            attack: 0.001,       // Instant
            decay: 0.15,         // Fast decay
            sustain: 0.0,        // No sustain (dies away)
            release: 0.1,
            destination: .modulationIndex,
            amount: 10.0,        // Maximum modulation
            isEnabled: true
        )
        
        // Auxiliary: Filter follows same envelope
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 0.001,
            decay: 0.15,
            sustain: 0.0,
            release: 0.1,
            destination: .filterCutoff,
            amount: 2.5,         // Large sweep
            isEnabled: true
        )
        
        return params
    }
    
    // MARK: - Test 7: Pad
    
    /// Slow, evolving pad sound
    static var pad: VoiceModulationParameters {
        var params = VoiceModulationParameters.default
        
        // Modulator: Very slow attack and release
        params.modulatorEnvelope = ModulationEnvelopeParameters(
            attack: 1.0,         // 1 second attack
            decay: 0.5,
            sustain: 0.4,        // Medium brightness
            release: 2.0,        // Long release
            destination: .modulationIndex,
            amount: 4.0,
            isEnabled: true
        )
        
        // Auxiliary: Even slower filter
        params.auxiliaryEnvelope = ModulationEnvelopeParameters(
            attack: 1.5,         // Very slow open
            decay: 1.0,
            sustain: 0.6,
            release: 2.5,
            destination: .filterCutoff,
            amount: 1.2,
            isEnabled: true
        )
        
        return params
    }
}

// MARK: - Test Helper Functions

extension AudioParameterManager {
    
    /// Apply a test preset to the voice template
    func applyEnvelopeTestPreset(_ preset: VoiceModulationParameters) {
        var template = voiceTemplate
        template.modulation = preset
        updateVoiceTemplate(template)
        
        print("🎵 Applied envelope test preset")
        print("   Modulator: \(preset.modulatorEnvelope.isEnabled ? "enabled" : "disabled")")
        if preset.auxiliaryEnvelope.isEnabled {
            print("   Auxiliary: enabled → \(preset.auxiliaryEnvelope.destination.displayName)")
        } else {
            print("   Auxiliary: disabled")
        }
    }
}

extension VoicePool {
    
    /// Update all voices with test preset
    func applyEnvelopeTestPreset(_ preset: VoiceModulationParameters) {
        updateAllVoiceModulation(preset)
        print("🎵 Updated all \(voiceCount) voices with test preset")
    }
}

// MARK: - Usage Examples

/*
 
 // In your test view or app initialization:
 
 // Test 1: FM Bell
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.fmBell)
 // Play a note - you should hear a bright attack fading to a mellow tone
 
 // Test 2: Filter Sweep
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.filterSweep)
 // Set base filter low: filter.cutoffFrequency = 400
 // Play a note - you should hear a "wow" sweep from bright to dark
 
 // Test 3: Combined
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.combinedEvolution)
 // Play a note - you should hear complex timbral evolution
 
 // Test 4: Pitch Drop
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.pitchDrop)
 // Play a note - you should hear pitch drop like an 808 drum
 
 // Test 5: Brass
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.brass)
 // Play a note - you should hear a brass-like attack and sustain
 
 // Test 6: Pluck
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.pluck)
 // Play a note - you should hear a plucked string sound
 
 // Test 7: Pad
 voicePool.applyEnvelopeTestPreset(EnvelopeTestPresets.pad)
 // Play and hold a note - you should hear a slow, evolving pad
 
 */

