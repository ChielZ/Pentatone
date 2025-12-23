# Audio Engine Overhaul Implementation Plan

## Overview
This document outlines a phased approach to overhauling the audio engine from a 1:1 key-to-voice architecture (18 voices) to a polyphonic voice allocation system with advanced modulation capabilities.

---

## Current Architecture Analysis

### Current Structure:
- **18 OscVoice instances** (oscillator01-18) - one per key
- **Each voice contains:** Single FMOscillator → LowPassFilter → AmplitudeEnvelope → Panner
- **Frequency calculation:** Handled by `makeKeyFrequencies()` in Scales.swift, applied via `EngineManager.applyScale()`
- **Parameter system:** Centralized through `AudioParameterManager` with template and per-voice overrides
- **Touch handling:** Direct mapping in KeyButton gesture handlers (amplitude from initial touch X, filter cutoff from aftertouch)

### Key Dependencies:
1. `MainKeyboardView.swift` - 18 KeyButton instances directly call oscillator01-18 trigger/release
2. `Scales.swift` - `makeKeyFrequencies()` produces 18 frequencies based on scale + key + rotation
3. `AudioKitCode.swift` - 18 global voice instances and `EngineManager.applyScale()`
4. `SoundParameters.swift` - AudioParameterManager with per-voice parameter control

---

## Implementation Phases

### Phase 1: Create New Voice Pool Architecture (FOUNDATION)
**Goal:** Establish the new voice allocation system while keeping old system working

**Files to create:**
- `VoicePool.swift` - New voice allocation manager
- `PolyphonicVoice.swift` - Enhanced voice class with dual oscillators

**Implementation steps:**
1. Create `PolyphonicVoice` class:
   - Two FMOscillators (osc1, osc2) with mixing
   - Same signal chain: oscillators → filter → envelope → pan
   - Add `setFrequency()` method (dynamic, not tied to specific key)
   - Add `isActive` state tracking
   - Keep same parameter structure initially

2. Create `VoicePool` class:
   ```swift
   final class VoicePool {
       private var voices: [PolyphonicVoice]
       private var nextVoiceIndex: Int = 0  // Round-robin pointer
       
       init(voiceCount: Int = 5)
       func allocateVoice(frequency: Double) -> PolyphonicVoice?
       func releaseVoice(_ voice: PolyphonicVoice)
       func stopAll()
   }
   ```

3. Add to AudioKitCode.swift:
   - Create global `voicePool` instance (alongside existing voices)
   - Initialize in `EngineManager.startIfNeeded()`
   - **Keep existing oscillator01-18 untouched** (parallel systems)

**Testing:** Create a simple test view that triggers the new voice pool

---

### Phase 2: Create Key-to-Frequency Mapping System (SEPARATION)
**Goal:** Decouple frequency calculations from voice instances

**Files to modify:**
- `Scales.swift` - Keep `makeKeyFrequencies()` but add new accessors
- Create `KeyboardState.swift` - New state management

**Implementation steps:**
1. Create `KeyboardState` class:
   ```swift
   @MainActor
   final class KeyboardState: ObservableObject {
       @Published var currentScale: Scale
       @Published var currentKey: MusicalKey
       
       // The 18 key frequencies (computed from scale/key/rotation)
       private(set) var keyFrequencies: [Double] = []
       
       func updateScale(_ scale: Scale)
       func updateKey(_ key: MusicalKey)
       func frequencyForKey(at index: Int) -> Double
   }
   ```

2. Modify `makeKeyFrequencies()` to be a pure function
3. Keep scale update logic working with old system

**Testing:** Verify scale/key changes still work correctly with old voice system

---

### Phase 3: Implement Voice Allocation in MainKeyboardView (TRANSITION)
**Goal:** Switch keyboard to use new voice pool while maintaining functionality

**Files to modify:**
- `MainKeyboardView.swift` - Update KeyButton gesture handling
- `PentatoneApp.swift` - Integrate KeyboardState

**Implementation steps:**
1. Update KeyButton to:
   - Store reference to allocated voice (instead of hard-coded oscillator)
   - Get frequency from KeyboardState (not from pre-set voice)
   - Allocate voice on touch down: `voice = voicePool.allocate(frequency: keyFreq)`
   - Release voice on touch up: `voicePool.release(voice)`

2. Update touch gesture handler:
   ```swift
   @State private var allocatedVoice: PolyphonicVoice? = nil
   
   DragGesture(...)
       .onChanged { value in
           if allocatedVoice == nil {
               let frequency = keyboardState.frequencyForKey(at: keyIndex)
               allocatedVoice = voicePool.allocateVoice(frequency: frequency)
               allocatedVoice?.trigger()
               // Handle amplitude/filter as before
           } else {
               // Aftertouch handling
           }
       }
       .onEnded { _ in
           allocatedVoice?.release()
           voicePool.releaseVoice(allocatedVoice)
           allocatedVoice = nil
       }
   ```

3. Add feature flag to switch between old/new systems for testing

**Testing:** 
- Verify all 18 keys work with voice pool
- Test polyphony (press multiple keys)
- Verify voice stealing works smoothly (press >5 keys)

---

### Phase 4: ~~Expand Voice Parameters for Dual Oscillators~~ **SKIPPED** ✅
**Decision:** Skip this phase entirely. The dual oscillators implemented in Phase 1 already behave identically (except for tuning offset), which is exactly what's needed. No per-oscillator parameter differences required.

**Original goal:** Add separate parameters for each oscillator (different waveforms, mix control, etc.)  
**Why skipped:** Both oscillators should always behave identically for this app's sonic goals  
**What we already have:** Dual stereo oscillators with frequency offset control (Phase 1 + 1.5)

---


### Phase 5: Add Modulation System (MODULATION)
**Goal:** Implement LFOs and modulation envelopes

Phase 5 is large and complex, it would be wise to split it in to sub-stages 
1. 5A: Foundation (modulation data structures)
2. 5B: Modulation Envelopes (One hardwired to FMOscillator ModulationIndex, the second one with routable destinations
3. 5C: LFOs per voice and global
5. 5D: Touch & Key tracking 


GENERAL INFORMATION FOR PHASE 5:

**Files to create:**
- `ModulationSystem.swift` - Modulator definitions and routing

**Implementation steps:**
1. Create modulator types (already done in ModulationSystem.swift):
   ```swift
   struct LFOModulator {
       var rate: Double  // Hz
       var depth: Double  // 0-1
       var waveform: OscillatorWaveform
       var destination: ModulationDestination
   }
   
   struct ModulationEnvelope {
       var attack: Double
       var decay: Double
       var sustain: Double
       var release: Double
       var depth: Double
       var destination: ModulationDestination
   }
   ```

2. Add to `VoiceParameters`:
   ```swift
   struct VoiceParameters {
       var oscillator: OscillatorParameters
       var filter: FilterParameters
       var envelope: EnvelopeParameters  // Output amplitude (keep existing)
       var pan: PanParameters  // No longer needed (oscillators are hard-panned)
       var modulationEnvelope: ModulationEnvelope  // NEW: For FM modulationIndex
       var voiceLFO: LFOModulator  // Per-voice LFO
   }
   ```

3. Implement modulation in `PolyphonicVoice`:
   - Add control-rate update loop (~200 Hz for snappy envelopes and super smooth LFOs)
   - ModulationEnvelope controls `modulationIndex` parameter
   - Tracks time since trigger for envelope stages
   - Updates both oscLeft and oscRight with same modIndex value
   - Keep AmplitudeEnvelope unchanged (it controls output volume)

4. Add global LFO to `VoicePool`:
   - Global LFO can target global parameters (delay time, reverb mix)
   - Per-voice LFO targets voice parameters (filter cutoff, etc.)
   - Control-rate timer in VoicePool triggers all modulation updates

5. Example modulation destinations:
   - **Modulation Envelope** → FM modulationIndex (timbral evolution)
   - **Voice LFO** → Filter cutoff, oscillator detune
   - **Global LFO** → Delay time, reverb mix, global filter

**Why this architecture works:**
- ✅ Output volume controlled by familiar AmplitudeEnvelope (openGate/closeGate)
- ✅ FM timbre evolution via modulation envelope on modulationIndex
- ✅ Classic FM sounds possible (bells, brass, evolving pads)
- ✅ Fixed carrier level is musically sufficient
- ✅ Per-preset control (some presets use it, some don't)
- ✅ Moderate complexity, maximum expressiveness

**Testing:** Create test preset with visible/audible modulation:
- ModulationEnvelope on modulationIndex (hear timbre evolve from bright to warm)
- Voice LFO on filter cutoff (hear wobble)
- Global LFO on delay time (hear rhythmic delay)




>> INSERTED INTO PLAN AS REFERENCE FOR STAGE 5: 
THIS MY FULL CONCEPT FOR THE FINAL STRUCTURE OF EDITABLE PARAMETERS / SOUND EDITING SCREENS
 
 1. VOICE [the voice strutucre itself is already implemented]
 
 a) Oscillator (the same parameter values will be applied to both the left-panned and right-panned FMOscillators
 - Waveform (shared between Carrier and Modulator, options: sine, triangle, square)
 - Carrier multiplier (=>carrierMultiplier)
 - Modulator multiplier coarse (=>modulatingMultiplier, integer values)
 - Modulator multiplier fine (=> modulatingMultiplier, .00 - .99)
 - Modulator base level (=> modulationIndex)
 - Amplitude (=>amplitude)
 
 b) Stereo spread
 - Offset mode (absolute vs relative)
 - Offset amount
 
 c) Filter
 - Cutoff
 - Resonance
 - Saturation
 
 d) AmplitudeEnvelope
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 
 
 2. FX CHAIN [the fx chain itself is already implemented]
 
 a) Delay
 - Delay time (implement as sync to master tempo?)
 - Delay feedback
 - Delay PingPong
 - Delay mix
 
 b) Reverb
 - Reverb size
 - Reverb tone
 - Reverb mix
 
 
 3. MASTER [most of this yet to be implemented]
 
 - Tempo
 - Voice mode (polyphonic/monophonic)
 - Root frequency
 - Octave
 - Fine tune
 - Master volume (pre or post fx? For pre fx, could be mapped to voicemixer volume)
 
 
 4. MODULATION [most of this yet to be implemented]
 
 a) Modulator envelope (should exist per-voice, destination is 'hard wired' to oscillators' modulationIndex)
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 - Envelope amount (=> modulationIndex + Modulation envelope value * envelope amount)
 
 b) Auxiliary Envelope (should exist per-voice)
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 - destination (Oscillator baseFrequency, modulatingMultiplier, Filter frequency [default], Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)

 c) Voice LFO (should exist per-voice)
 - waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 - reset mode (free, trigger, sync)
 - frequency (0-10 Hz or tempo multipliers depending on mode)
 - destination (Oscillator baseFrequency [default], modulationIndex, modulatingMultiplier, Filter frequency, stereo spread offset amount)
 - amount (bipolar modulation, so only positive amounts)

 d) Global LFO (should exist as a single LFO on global level
 - waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 - reset mode (free, sync)
 - frequency (0-10 Hz or tempo multipliers depending on mode)
 - destination (Oscillator amplitude [default], Oscillator baseFrequency, modulationIndex, modulatingMultiplier, Filter frequency, delay time, delay amount)
 - amount (bipolar modulation, so only positive amounts)
 
 e) Key tracking (value proportional to frequency of triggered key)
  - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
  - amount (unipolar modulation, so positive and negative amount)

 e) X initial touch (x position of key trigger touch) [already implemented but currently hardwired to filter frequency]
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)
 
 f) X aftertouch (change in x position of touch while key is being held) [already implemented but currently hardwired to volume]
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (bipolar modulation, so only positive amounts)
 ? toggle for relative/absolute mode ?
 
 








---

### Phase 6: Implement Preset System (PRESETS)
**Goal:** Create preset management and browsing

**Files to create:**
- `PresetManager.swift` - Preset storage and loading
- `PresetBrowser.swift` - UI for preset selection (developer view)

**Implementation steps:**
1. Create PresetManager:
   ```swift
   final class PresetManager: ObservableObject {
       @Published private(set) var presets: [AudioParameterSet] = []
       @Published private(set) var currentPreset: AudioParameterSet?
       
       func loadPreset(_ preset: AudioParameterSet)
       func savePreset(_ preset: AudioParameterSet)
       func deletePreset(id: UUID)
       func loadBuiltInPresets()  // The 15 factory presets
   }
   ```

2. Create the 15 initial presets with appropriate parameter values:
   - Start with basic variations
   - Focus on distinct sonic characteristics
   - Use descriptive parameter sets that match preset names

3. Create developer preset browser view:
   - List all presets
   - Load/save functionality
   - Parameter editing interface
   - Export/import presets (JSON)

**Testing:** Load each preset and verify it produces distinct sound

---

### Phase 7: Implement Macro Control System (MACROS)
**Goal:** Create 4 macro controls that map to multiple parameters per preset

**Files to create:**
- `MacroSystem.swift` - Macro definitions and mapping

**Implementation steps:**
1. Define macro structure:
   ```swift
   struct MacroMapping {
       var targetParameter: KeyPath<VoiceParameters, Double>  // Or custom enum
       var range: ClosedRange<Double>
       var curve: MacroCurve  // Linear, exponential, etc.
   }
   
   struct MacroControl {
       var name: String
       var value: Double  // 0-1
       var mappings: [MacroMapping]
   }
   ```

2. Add to `AudioParameterSet`:
   ```swift
   struct AudioParameterSet {
       // ... existing fields
       var macros: [MacroControl]  // 4 macros per preset
   }
   ```

3. Implement macro application in AudioParameterManager:
   ```swift
   func updateMacro(index: Int, value: Double) {
       // Apply value to all mapped parameters
   }
   ```

4. Create macro UI controls (4 vertical sliders)

**Testing:** Verify macro controls affect multiple parameters smoothly

---

### Phase 8: Cleanup and Optimization (POLISH)
**Goal:** Remove old system, optimize performance, polish UX

**Implementation steps:**
1. Remove old voice system:
   - Delete oscillator01-18 globals
   - Remove old EngineManager.applyScale()
   - Clean up old parameter application code

2. Optimize voice pool:
   - Add voice priority system (steal oldest or quietest)
   - Implement smooth voice stealing (fade out)
   - Add CPU usage monitoring

3. Polish UI:
   - Add preset indicator to main view
   - Add macro controls to appropriate location
   - Update options view for preset browsing

4. Add in-app documentation:
   - Scale explanations
   - Preset descriptions
   - Macro control descriptions

**Testing:** Full app testing, performance profiling, user experience validation

---

## Migration Notes

### Advantages of This Approach:
1. **Incremental:** Each phase builds on the previous, allowing testing at each step
2. **Reversible:** Old system remains functional until Phase 8
3. **Testable:** Each phase has clear success criteria
4. **Risk mitigation:** Can halt at any phase if issues arise

### Key Touch Points per Phase:
- **Phase 1-2:** No user-visible changes ✅ COMPLETE
- **Phase 1.5:** Enhanced stereo width control ✅ COMPLETE
- **Phase 3:** Major internal change, should be transparent to user ✅ COMPLETE
- **Phase 4:** SKIPPED - dual oscillators already correct ✅
- **Phase 5:** New sonic possibilities with modulation (FM timbral evolution!)
- **Phase 6-7:** New features (presets, macros)
- **Phase 8:** Performance improvements, UI polish

### Estimated Complexity:
- **Phase 1:** Medium (new architecture) ✅ COMPLETE
- **Phase 1.5:** Low (detune modes) ✅ COMPLETE
- **Phase 2:** Low (mostly refactoring) ✅ COMPLETE
- **Phase 3:** High (critical transition point) ✅ COMPLETE
- **Phase 4:** SKIPPED ✅
- **Phase 5:** High (modulation + FM envelope routing)
- **Phase 6:** Low (data management)
- **Phase 7:** Medium (macro mapping logic)
- **Phase 8:** Medium (cleanup and optimization)

### Critical Decision Points:
1. **After Phase 3:** Verify voice allocation works reliably before proceeding
2. **After Phase 5:** Ensure modulation doesn't cause CPU issues
3. **During Phase 6:** Finalize the 15 preset sound design

---

## Additional Considerations

### Performance Targets:
- CPU usage < 30% on iPhone 12 or later
- No audio dropouts with 5 simultaneous voices
- Smooth parameter changes (no zipper noise)

### Testing Strategy:
- Create unit tests for voice allocation logic
- Create integration tests for parameter application
- Manual testing checklist for each phase
- Performance testing with Instruments

### Documentation Requirements:
- Code comments for new architecture
- API documentation for public interfaces
- User-facing documentation for presets/macros
- Developer notes for future maintenance

---

## Recommended Implementation Order Summary:

1. ✅ **Phase 1** (1-2 days) → New voice architecture alongside old [COMPLETE]
2. ✅ **Phase 1.5** (0.5 days) → Detune modes (proportional/constant) [COMPLETE]
3. ✅ **Phase 2** (1 day) → Key-frequency mapping separation [COMPLETE]
4. ✅ **Phase 3** (2-3 days) → **CRITICAL** Switch to new voice pool [COMPLETE]
5. ✅ **Old System Cleanup** (0.5 days) → Remove obsolete code [COMPLETE]
6. ~~**Phase 4** → SKIPPED (dual oscillators already implemented correctly)~~
7. ⚠️ **Phase 5** (3-4 days) → **COMPLEX** Modulation system (LFOs + mod envelope for FM)
8. **Phase 6** (2-3 days) → Preset management + sound design
9. **Phase 7** (2 days) → Macro controls
10. **Phase 8** (2-3 days) → Cleanup and polish

**Total estimated time:** 2-2.5 weeks remaining (reduced from 3-4 weeks by skipping Phase 4 and completing cleanup early)

**Phases completed:** 1, 1.5, 2, 3, Old System Cleanup

**Current status:** Clean codebase, ready for Phase 5 (Modulation System)

