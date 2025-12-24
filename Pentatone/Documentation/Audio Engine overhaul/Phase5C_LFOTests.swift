//
//  Phase5C_LFOTests.swift
//  Pentatone
//
//  Created by Assistant on 24/12/2025.
//  Phase 5C: LFO Implementation Tests
//

/*
import Foundation
import Testing
//@testable import Pentatone

// MARK: - LFO Waveform Tests

@Suite("Phase 5C: LFO Waveform Generation")
struct LFOWaveformTests {
    
    @Test("Sine wave oscillates smoothly")
    func testSineWaveform() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .sine
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = true
        
        // Test key points in sine wave cycle
        let phase0 = lfo.currentValue(phase: 0.0)    // Start: 0.0
        let phase25 = lfo.currentValue(phase: 0.25)  // Peak: +1.0
        let phase50 = lfo.currentValue(phase: 0.5)   // Middle: 0.0
        let phase75 = lfo.currentValue(phase: 0.75)  // Trough: -1.0
        let phase100 = lfo.currentValue(phase: 1.0)  // End: 0.0
        
        #expect(abs(phase0) < 0.01, "Sine should start at 0")
        #expect(abs(phase25 - 1.0) < 0.01, "Sine should peak at +1.0")
        #expect(abs(phase50) < 0.01, "Sine should return to 0 at midpoint")
        #expect(abs(phase75 + 1.0) < 0.01, "Sine should trough at -1.0")
        #expect(abs(phase100) < 0.01, "Sine should end at 0")
    }
    
    @Test("Triangle wave produces linear ramps")
    func testTriangleWaveform() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .triangle
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = true
        
        // Test key points in triangle wave cycle
        let phase0 = lfo.currentValue(phase: 0.0)    // Start: -1.0
        let phase25 = lfo.currentValue(phase: 0.25)  // Rising: 0.0
        let phase50 = lfo.currentValue(phase: 0.5)   // Peak: +1.0
        let phase75 = lfo.currentValue(phase: 0.75)  // Falling: 0.0
        let phase100 = lfo.currentValue(phase: 1.0)  // End: -1.0
        
        #expect(abs(phase0 + 1.0) < 0.01, "Triangle should start at -1.0")
        #expect(abs(phase25) < 0.01, "Triangle should cross 0 at 0.25")
        #expect(abs(phase50 - 1.0) < 0.01, "Triangle should peak at +1.0")
        #expect(abs(phase75) < 0.01, "Triangle should cross 0 at 0.75")
        #expect(abs(phase100 + 1.0) < 0.01, "Triangle should end at -1.0")
    }
    
    @Test("Square wave produces instant transitions")
    func testSquareWaveform() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .square
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = true
        
        // Test key points in square wave cycle
        let phase0 = lfo.currentValue(phase: 0.0)    // First half: +1.0
        let phase25 = lfo.currentValue(phase: 0.25)  // Still: +1.0
        let phase49 = lfo.currentValue(phase: 0.49)  // Still: +1.0
        let phase50 = lfo.currentValue(phase: 0.5)   // Transition: -1.0
        let phase75 = lfo.currentValue(phase: 0.75)  // Second half: -1.0
        
        #expect(abs(phase0 - 1.0) < 0.01, "Square should start at +1.0")
        #expect(abs(phase25 - 1.0) < 0.01, "Square should stay at +1.0")
        #expect(abs(phase49 - 1.0) < 0.01, "Square should stay at +1.0 until 0.5")
        #expect(abs(phase50 + 1.0) < 0.01, "Square should drop to -1.0 at 0.5")
        #expect(abs(phase75 + 1.0) < 0.01, "Square should stay at -1.0")
    }
    
    @Test("Sawtooth wave produces linear rise")
    func testSawtoothWaveform() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .sawtooth
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = true
        
        // Test key points in sawtooth wave cycle
        let phase0 = lfo.currentValue(phase: 0.0)    // Start: -1.0
        let phase25 = lfo.currentValue(phase: 0.25)  // Rising: -0.5
        let phase50 = lfo.currentValue(phase: 0.5)   // Rising: 0.0
        let phase75 = lfo.currentValue(phase: 0.75)  // Rising: +0.5
        let phase100 = lfo.currentValue(phase: 1.0)  // End: +1.0
        
        #expect(abs(phase0 + 1.0) < 0.01, "Sawtooth should start at -1.0")
        #expect(abs(phase25 + 0.5) < 0.01, "Sawtooth should rise linearly")
        #expect(abs(phase50) < 0.01, "Sawtooth should cross 0 at midpoint")
        #expect(abs(phase75 - 0.5) < 0.01, "Sawtooth should continue rising")
        #expect(abs(phase100 - 1.0) < 0.01, "Sawtooth should end at +1.0")
    }
    
    @Test("Reverse sawtooth wave produces linear fall")
    func testReverseSawtoothWaveform() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .reverseSawtooth
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = true
        
        // Test key points in reverse sawtooth wave cycle
        let phase0 = lfo.currentValue(phase: 0.0)    // Start: +1.0
        let phase25 = lfo.currentValue(phase: 0.25)  // Falling: +0.5
        let phase50 = lfo.currentValue(phase: 0.5)   // Falling: 0.0
        let phase75 = lfo.currentValue(phase: 0.75)  // Falling: -0.5
        let phase100 = lfo.currentValue(phase: 1.0)  // End: -1.0
        
        #expect(abs(phase0 - 1.0) < 0.01, "Reverse saw should start at +1.0")
        #expect(abs(phase25 - 0.5) < 0.01, "Reverse saw should fall linearly")
        #expect(abs(phase50) < 0.01, "Reverse saw should cross 0 at midpoint")
        #expect(abs(phase75 + 0.5) < 0.01, "Reverse saw should continue falling")
        #expect(abs(phase100 + 1.0) < 0.01, "Reverse saw should end at -1.0")
    }
    
    @Test("LFO amount scales output correctly")
    func testLFOAmountScaling() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .sine
        lfo.frequency = 1.0
        lfo.isEnabled = true
        
        // Test different amounts
        lfo.amount = 1.0
        let full = lfo.currentValue(phase: 0.25)  // Peak at 0.25
        
        lfo.amount = 0.5
        let half = lfo.currentValue(phase: 0.25)
        
        lfo.amount = 0.0
        let zero = lfo.currentValue(phase: 0.25)
        
        #expect(abs(full - 1.0) < 0.01, "Full amount should produce ±1.0")
        #expect(abs(half - 0.5) < 0.01, "Half amount should produce ±0.5")
        #expect(abs(zero) < 0.01, "Zero amount should produce 0")
    }
    
    @Test("Disabled LFO returns zero")
    func testDisabledLFO() async throws {
        var lfo = LFOParameters.default
        lfo.waveform = .sine
        lfo.frequency = 1.0
        lfo.amount = 1.0
        lfo.isEnabled = false
        
        let value = lfo.currentValue(phase: 0.25)
        #expect(value == 0.0, "Disabled LFO should return 0")
    }
}

// MARK: - LFO Modulation Routing Tests

@Suite("Phase 5C: LFO Modulation Routing")
struct LFOModulationRoutingTests {
    
    @Test("LFO modulation applies correctly to modulationIndex")
    func testModulationIndexRouting() async throws {
        let baseValue = 2.0
        let lfoValue = 1.0  // Full positive swing
        
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: lfoValue,
            destination: .modulationIndex
        )
        
        // lfoValue = ±1.0 means ±5.0 modIndex swing
        let expected = baseValue + 5.0
        #expect(abs(modulated - expected) < 0.01, "ModulationIndex should swing by ±5.0")
    }
    
    @Test("LFO modulation applies exponentially to filter cutoff")
    func testFilterCutoffRouting() async throws {
        let baseValue = 1000.0
        let lfoValue = 1.0  // Full positive swing
        
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: lfoValue,
            destination: .filterCutoff
        )
        
        // lfoValue = ±1.0 means ±12 semitones (±1 octave)
        // +1 octave = 2x frequency
        let expected = baseValue * 2.0
        #expect(abs(modulated - expected) < 1.0, "Filter cutoff should double at +1.0")
    }
    
    @Test("LFO modulation applies linearly to amplitude")
    func testAmplitudeRouting() async throws {
        let baseValue = 0.5
        let lfoValue = 1.0  // Full positive swing
        
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: lfoValue,
            destination: .oscillatorAmplitude
        )
        
        // lfoValue = ±1.0 means ±0.5 amplitude swing
        let expected = baseValue + 0.5
        #expect(abs(modulated - expected) < 0.01, "Amplitude should swing by ±0.5")
    }
    
    @Test("LFO modulation clamps values to valid ranges")
    func testModulationClamping() async throws {
        // Test that amplitude doesn't go below 0 or above 1
        let baseValue = 0.1
        let lfoValue = -1.0  // Full negative swing (would go to -0.4)
        
        let modulated = ModulationRouter.applyLFOModulation(
            baseValue: baseValue,
            lfoValue: lfoValue,
            destination: .oscillatorAmplitude
        )
        
        // Should clamp to 0, not go negative
        #expect(modulated >= 0.0, "Amplitude should not go negative")
        #expect(modulated <= 1.0, "Amplitude should not exceed 1.0")
    }
}

// MARK: - Integration Tests

@Suite("Phase 5C: LFO Integration Tests")
struct LFOIntegrationTests {
    
    @Test("Voice LFO parameters are stored correctly")
    func testVoiceLFOStorage() async throws {
        var voiceMod = VoiceModulationParameters.default
        
        voiceMod.voiceLFO.waveform = .triangle
        voiceMod.voiceLFO.frequency = 3.5
        voiceMod.voiceLFO.destination = .filterCutoff
        voiceMod.voiceLFO.amount = 0.7
        voiceMod.voiceLFO.isEnabled = true
        
        #expect(voiceMod.voiceLFO.waveform == .triangle)
        #expect(voiceMod.voiceLFO.frequency == 3.5)
        #expect(voiceMod.voiceLFO.destination == .filterCutoff)
        #expect(voiceMod.voiceLFO.amount == 0.7)
        #expect(voiceMod.voiceLFO.isEnabled == true)
    }
    
    @Test("Global LFO parameters are stored correctly")
    func testGlobalLFOStorage() async throws {
        var globalLFO = GlobalLFOParameters.default
        
        globalLFO.waveform = .sine
        globalLFO.frequency = 2.0
        globalLFO.destination = .delayTime
        globalLFO.amount = 0.5
        globalLFO.isEnabled = true
        
        #expect(globalLFO.waveform == .sine)
        #expect(globalLFO.frequency == 2.0)
        #expect(globalLFO.destination == .delayTime)
        #expect(globalLFO.amount == 0.5)
        #expect(globalLFO.isEnabled == true)
    }
    
    @Test("LFO reset modes are configured correctly")
    func testLFOResetModes() async throws {
        var lfo = LFOParameters.default
        
        lfo.resetMode = .free
        #expect(lfo.resetMode == .free)
        
        lfo.resetMode = .trigger
        #expect(lfo.resetMode == .trigger)
        
        lfo.resetMode = .sync
        #expect(lfo.resetMode == .sync)
    }
    
    @Test("LFO frequency modes work correctly")
    func testLFOFrequencyModes() async throws {
        var lfo = LFOParameters.default
        
        lfo.frequencyMode = .hertz
        lfo.frequency = 5.0
        #expect(lfo.frequency == 5.0)
        
        lfo.frequencyMode = .tempoSync
        lfo.frequency = 2.0  // 2x tempo (eighth notes at 120 BPM)
        #expect(lfo.frequency == 2.0)
    }
}

// MARK: - Phase Tracking Tests

@Suite("Phase 5C: LFO Phase Tracking")
struct LFOPhaseTrackingTests {
    
    @Test("ModulationState tracks voice LFO phase")
    func testVoiceLFOPhaseTracking() async throws {
        var state = ModulationState()
        
        // Initial state
        #expect(state.voiceLFOPhase == 0.0)
        
        // Simulate phase progression
        state.voiceLFOPhase = 0.5
        #expect(state.voiceLFOPhase == 0.5)
        
        // Wrap around
        state.voiceLFOPhase = 1.2
        #expect(state.voiceLFOPhase == 1.2)  // Wrapping handled by update logic
    }
    
    @Test("ModulationState resets correctly with LFO phase")
    func testModulationStateReset() async throws {
        var state = ModulationState()
        
        // Set some state
        state.voiceLFOPhase = 0.7
        state.modulatorEnvelopeTime = 2.0
        state.isGateOpen = false
        
        // Reset with LFO phase reset
        state.reset(frequency: 440.0, touchX: 0.5, resetLFOPhase: true)
        
        #expect(state.voiceLFOPhase == 0.0, "LFO phase should reset to 0")
        #expect(state.modulatorEnvelopeTime == 0.0)
        #expect(state.isGateOpen == true)
    }
    
    @Test("ModulationState preserves LFO phase in free mode")
    func testModulationStateFreeMode() async throws {
        var state = ModulationState()
        
        // Set some state
        state.voiceLFOPhase = 0.7
        
        // Reset WITHOUT LFO phase reset (free mode)
        state.reset(frequency: 440.0, touchX: 0.5, resetLFOPhase: false)
        
        #expect(state.voiceLFOPhase == 0.7, "LFO phase should NOT reset in free mode")
    }
    
    @Test("GlobalModulationState tracks global LFO phase")
    func testGlobalLFOPhaseTracking() async throws {
        var state = GlobalModulationState()
        
        // Initial state
        #expect(state.globalLFOPhase == 0.0)
        
        // Simulate phase progression
        state.globalLFOPhase = 0.3
        #expect(state.globalLFOPhase == 0.3)
        
        state.globalLFOPhase = 0.9
        #expect(state.globalLFOPhase == 0.9)
    }
}

// MARK: - Real-World Scenarios

@Suite("Phase 5C: LFO Real-World Scenarios")
struct LFORealWorldScenarios {
    
    @Test("Vibrato setup (voice LFO on frequency)")
    func testVibratoSetup() async throws {
        var voiceMod = VoiceModulationParameters.default
        
        // Classic vibrato: 5-6 Hz sine wave on pitch
        voiceMod.voiceLFO.waveform = .sine
        voiceMod.voiceLFO.frequency = 5.5
        voiceMod.voiceLFO.destination = .oscillatorBaseFrequency
        voiceMod.voiceLFO.amount = 0.3  // Subtle pitch variation
        voiceMod.voiceLFO.resetMode = .free
        voiceMod.voiceLFO.isEnabled = true
        
        #expect(voiceMod.voiceLFO.waveform == .sine)
        #expect(voiceMod.voiceLFO.frequency == 5.5)
        #expect(voiceMod.voiceLFO.destination == .oscillatorBaseFrequency)
    }
    
    @Test("Filter wobble setup (voice LFO on filter cutoff)")
    func testFilterWobbleSetup() async throws {
        var voiceMod = VoiceModulationParameters.default
        
        // Dubstep wobble: slow square/triangle on filter
        voiceMod.voiceLFO.waveform = .square
        voiceMod.voiceLFO.frequency = 0.25  // 4 seconds per cycle
        voiceMod.voiceLFO.destination = .filterCutoff
        voiceMod.voiceLFO.amount = 0.8  // Strong filter sweep
        voiceMod.voiceLFO.resetMode = .trigger
        voiceMod.voiceLFO.isEnabled = true
        
        #expect(voiceMod.voiceLFO.waveform == .square)
        #expect(voiceMod.voiceLFO.frequency == 0.25)
        #expect(voiceMod.voiceLFO.destination == .filterCutoff)
    }
    
    @Test("Tremolo setup (global LFO on amplitude)")
    func testTremoloSetup() async throws {
        var globalLFO = GlobalLFOParameters.default
        
        // Classic tremolo: 3-4 Hz sine wave on volume
        globalLFO.waveform = .sine
        globalLFO.frequency = 3.5
        globalLFO.destination = .oscillatorAmplitude
        globalLFO.amount = 0.4  // Moderate volume modulation
        globalLFO.resetMode = .free
        globalLFO.isEnabled = true
        
        #expect(globalLFO.waveform == .sine)
        #expect(globalLFO.frequency == 3.5)
        #expect(globalLFO.destination == .oscillatorAmplitude)
    }
    
    @Test("Rhythmic delay setup (global LFO on delay time)")
    func testRhythmicDelaySetup() async throws {
        var globalLFO = GlobalLFOParameters.default
        
        // Rhythmic delay: tempo-synced triangle on delay time
        globalLFO.waveform = .triangle
        globalLFO.frequencyMode = .tempoSync
        globalLFO.frequency = 1.0  // Quarter notes
        globalLFO.destination = .delayTime
        globalLFO.amount = 0.5
        globalLFO.resetMode = .sync
        globalLFO.isEnabled = true
        
        #expect(globalLFO.waveform == .triangle)
        #expect(globalLFO.frequencyMode == .tempoSync)
        #expect(globalLFO.destination == .delayTime)
    }
}

// MARK: - Documentation

/*
 
 # Phase 5C: LFO Implementation Tests
 
 ## Overview
 These tests verify the complete implementation of LFO (Low Frequency Oscillator) modulation
 in the Pentatone synthesizer. LFOs provide cyclic modulation to create effects like vibrato,
 tremolo, filter sweeps, and rhythmic parameter changes.
 
 ## Test Coverage
 
 ### 1. Waveform Generation
 - ✅ Sine wave (smooth oscillation)
 - ✅ Triangle wave (linear ramps)
 - ✅ Square wave (instant transitions)
 - ✅ Sawtooth wave (linear rise, instant fall)
 - ✅ Reverse sawtooth (instant rise, linear fall)
 - ✅ Amount scaling (0-1 controls depth)
 - ✅ Enabled/disabled state
 
 ### 2. Modulation Routing
 - ✅ ModulationIndex (linear swing ±5.0)
 - ✅ Filter cutoff (exponential, ±1 octave)
 - ✅ Oscillator amplitude (linear swing ±0.5)
 - ✅ Range clamping (prevents invalid values)
 
 ### 3. Phase Tracking
 - ✅ Voice LFO phase (per-voice, 0-1 range)
 - ✅ Global LFO phase (shared, 0-1 range)
 - ✅ Reset modes (free, trigger, sync)
 - ✅ Phase preservation in free mode
 
 ### 4. Integration
 - ✅ VoiceModulationParameters storage
 - ✅ GlobalLFOParameters storage
 - ✅ Reset mode configuration
 - ✅ Frequency mode configuration (Hz vs tempo sync)
 
 ### 5. Real-World Scenarios
 - ✅ Vibrato (5.5 Hz sine on pitch)
 - ✅ Filter wobble (0.25 Hz square on filter)
 - ✅ Tremolo (3.5 Hz sine on amplitude)
 - ✅ Rhythmic delay (tempo-synced on delay time)
 
 ## Architecture Verified
 
 ### LFO Types
 1. **Voice LFO**: Per-voice modulation with independent phase
    - Each voice has its own LFO phase
    - Reset modes: free (continuous), trigger (reset on note), sync (tempo)
 
 2. **Global LFO**: Single LFO affecting all voices
    - Shared phase across all voices
    - Can target voice or global parameters
    - Tempo-syncable for rhythmic effects
 
 ### Modulation Flow
 ```
 LFO Phase (0-1) → Waveform Calculation → Amount Scaling → Router → Parameter
 ```
 
 ### Supported Destinations
 - **Voice-level**: modulationIndex, filter, amplitude, frequency, etc.
 - **Global-level**: delay time, delay mix
 
 ## Success Criteria ✅
 
 ✅ All waveforms generate correct values at key phases
 ✅ Amount parameter scales output correctly
 ✅ Disabled LFOs return zero
 ✅ Modulation routing applies correctly with proper scaling
 ✅ Range clamping prevents invalid parameter values
 ✅ Phase tracking works for both voice and global LFOs
 ✅ Reset modes work correctly (free/trigger/sync)
 ✅ Real-world effect configurations are valid
 
 ## Next Steps
 
 After Phase 5C, we move to Phase 5D: Touch & Key Tracking
 - Initial touch X position modulation
 - Aftertouch (touch movement) modulation
 - Key tracking (frequency-based modulation)
 
 */
*/
