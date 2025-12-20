# Phase 2 Architecture Diagram

## KeyboardState Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       KeyboardState                             │
│                    (@ObservableObject)                          │
│                                                                 │
│  @Published currentScale: Scale ────────┐                      │
│  @Published currentKey: MusicalKey ─────┤                      │
│  var baseFrequency: Double ─────────────┤                      │
│                                         │                      │
│                                         ▼                      │
│                         ┌──────────────────────────┐           │
│                         │  updateFrequencies()     │           │
│                         │                          │           │
│                         │  makeKeyFrequencies(    │           │
│                         │    for: currentScale,    │           │
│                         │    baseFrequency: base,  │           │
│                         │    musicalKey: currentKey│           │
│                         │  )                       │           │
│                         └───────────┬──────────────┘           │
│                                     │                          │
│                                     ▼                          │
│  @Published keyFrequencies: [Double] ─── [18 frequencies]     │
│             ↓                                                  │
│    [0]: 146.83 Hz  (Key 0)                                    │
│    [1]: 164.81 Hz  (Key 1)                                    │
│    [2]: 185.16 Hz  (Key 2)                                    │
│    ...                                                         │
│    [17]: 2348.12 Hz (Key 17)                                  │
│                                                                │
└─────────────────────────────────────────────────────────────────┘
```

## Before vs After Phase 2

### Before (Phase 1)
```
User Interface
      │
      ▼
┌─────────────────┐
│ MainKeyboardView│
│  or TestView    │
└────────┬────────┘
         │
         ▼
   Scale changed?
         │
         ▼
┌────────────────────────────┐
│ makeKeyFrequencies()       │ ← Called every time inline
│ - Computes 18 frequencies  │
│ - Based on scale/key       │
└────────────┬───────────────┘
             │
             ▼
  ┌──────────────────────┐
  │ Apply to oscillators │  (Phase 1: oscillator01-18)
  │ or voice pool        │  (Phase 2: voice pool)
  └──────────────────────┘
```

### After (Phase 2)
```
┌─────────────────┐
│ KeyboardState   │ ← Single source of truth
│  @Published     │
│  properties     │
└────────┬────────┘
         │
         ├────────────────────┐
         │                    │
         ▼                    ▼
┌─────────────────┐   ┌─────────────────┐
│ MainKeyboardView│   │   TestView      │
│  (Phase 3)      │   │  (Phase 2)      │
└────────┬────────┘   └────────┬────────┘
         │                     │
         │    ┌────────────────┘
         │    │
         ▼    ▼
  ┌──────────────────────┐
  │ Frequency already    │
  │ available - just use │
  │ keyboardState        │
  │   .frequency(forKey:)│
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │ VoicePool.allocate   │
  │  (frequency, keyIdx) │
  └──────────────────────┘
```

## KeyboardState Update Flow

```
User Action
    │
    ├─ Change Scale ───────────┐
    ├─ Change Key ─────────────┤
    ├─ Cycle Intonation ───────┤
    ├─ Cycle Celestial ────────┤
    ├─ Cycle Terrestrial ──────┤
    └─ Cycle Rotation ─────────┤
                               │
                               ▼
            ┌────────────────────────────┐
            │  KeyboardState             │
            │  property changed          │
            └──────────┬─────────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │  updateFrequencies()       │
            │  - makeKeyFrequencies()    │
            │  - Computes new array      │
            └──────────┬─────────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │  keyFrequencies updated    │
            │  @Published triggers       │
            └──────────┬─────────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │  SwiftUI View recomputes   │
            │  - testFrequencies         │
            │  - UI labels               │
            └──────────┬─────────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │  User sees/hears update    │
            │  - New pitches when played │
            │  - UI shows new values     │
            └────────────────────────────┘
```

## Property Cycling Example

### Cycling Intonation (ET ↔ JI)

```
Current: Center Meridian (JI) in D

User taps "Cycle Intonation"
         │
         ▼
┌────────────────────────────────────┐
│ cycleIntonation(forward:in:)       │
│                                    │
│ 1. Determine target: ET            │
│ 2. Search catalog for match:       │
│    - celestial: center (same)      │
│    - terrestrial: meridian (same)  │
│    - intonation: ET (different)    │
└──────────────┬─────────────────────┘
               │
               ▼
┌────────────────────────────────────┐
│ Found: Center Meridian (ET)        │
│ Set currentScale = found scale     │
└──────────────┬─────────────────────┘
               │
               ▼
┌────────────────────────────────────┐
│ updateFrequencies() triggered      │
│ Computes new frequencies           │
│ (slightly different from JI)       │
└──────────────┬─────────────────────┘
               │
               ▼
         UI updates
    Frequencies changed
```

## Integration with VoicePool

```
┌─────────────────────────────────────────────────────────────┐
│                      Complete System                        │
└─────────────────────────────────────────────────────────────┘

User presses Key 5
       │
       ▼
┌──────────────────────────┐
│ KeyButton (gesture)      │
│  keyIndex: 5             │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Get frequency from KeyboardState:    │
│ let freq = keyboardState             │
│   .frequency(forKey: 5)              │
│                                      │
│ Result: 440.0 Hz (for example)       │
└───────────┬──────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Allocate voice from pool:            │
│ voicePool.allocateVoice(             │
│   frequency: 440.0,                  │
│   forKey: 5                          │
│ )                                    │
└───────────┬──────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ VoicePool finds available voice      │
│ - Round-robin: Voice 2               │
│ - Sets frequency: 440.0 Hz           │
│ - Applies detune (stereo spread)     │
│ - Triggers envelope                  │
│ - Maps key 5 → Voice 2               │
└───────────┬──────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Audio plays!                         │
│ - Stereo width from detune           │
│ - Correct pitch from KeyboardState   │
└──────────────────────────────────────┘
```

## State Management Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                     App State Layer                           │
└───────────────────────────────────────────────────────────────┘

PentatoneApp
    │
    ├─ @State currentScaleIndex
    ├─ @State rotation
    └─ @State musicalKey
         │
         │ (Phase 3: Replace with single KeyboardState)
         │
         ▼
    ┌──────────────────────────┐
    │  MainKeyboardView        │ ← Phase 3 will use KeyboardState
    │                          │
    │  Currently:              │
    │  - Takes scale as param  │
    │  - Takes key as param    │
    │  - Computes frequencies  │
    │    inline                │
    │                          │
    │  Phase 3:                │
    │  - Has KeyboardState     │
    │  - Just reads frequencies│
    └──────────────────────────┘


NewVoicePoolTestView (Phase 2)
    │
    └─ @StateObject keyboardState ← Already using KeyboardState!
         │
         ├─ currentScale
         ├─ currentKey
         └─ keyFrequencies[18]
```

## Memory & Performance

### Frequency Computation

**Before (computed on demand):**
```
Every scale change:
  makeKeyFrequencies() called
  → 18 frequencies computed
  → Applied to voices/oscillators

Every key press:
  Frequency lookup from pre-computed array
```

**After (KeyboardState manages):**
```
Every scale/key change:
  KeyboardState.updateFrequencies()
  → makeKeyFrequencies() called once
  → 18 frequencies stored in keyFrequencies array
  → @Published triggers UI update

Every key press:
  keyboardState.frequency(forKey: index)
  → Array lookup (O(1))
  → No computation
```

**Performance Impact:** Negligible! Array lookups are instant.

**Memory Impact:** +144 bytes (18 × 8 bytes for Double array)

---

## Testing Checklist

### KeyboardState Functionality
- [ ] Scale changes update frequencies
- [ ] Key changes update frequencies (transposition)
- [ ] Rotation changes update frequencies
- [ ] Cycling methods work correctly
- [ ] Published properties trigger UI updates

### Integration Testing
- [ ] Test view shows KeyboardState info
- [ ] "Cycle Key" button works
- [ ] Display shows current key and intonation
- [ ] Playing keys produces correct pitches
- [ ] Scale switching maintains correct frequencies
- [ ] Transposition produces expected pitch changes

### Audio Verification
- [ ] D (default) sounds correct
- [ ] Transpose to A (lower)
- [ ] Transpose to G (higher)
- [ ] Switch between ET and JI (subtle difference)
- [ ] All 18 keys playable with correct frequencies

---

## Phase 3 Preview

With KeyboardState in place, Phase 3 will be straightforward:

```swift
// MainKeyboardView.swift (Phase 3)
struct MainKeyboardView: View {
    @StateObject private var keyboardState = KeyboardState()
    
    var body: some View {
        // ...
        KeyButton(
            keyIndex: 0,
            trigger: {
                let freq = keyboardState.frequency(forKey: 0)
                voicePool.allocateVoice(frequency: freq, forKey: 0)
            },
            release: {
                voicePool.releaseVoice(forKey: 0)
            }
        )
    }
}
```

**Clean, simple, and decoupled!** 🎯
