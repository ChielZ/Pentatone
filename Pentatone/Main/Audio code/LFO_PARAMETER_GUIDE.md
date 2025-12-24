# LFO Parameter Quick Reference Guide

## Overview
This guide shows you **exactly where** to edit LFO parameters for testing in Pentatone.

---

## Voice LFO (Per-Voice Modulation)

**File:** `A01 SoundParameters.swift`  
**Line:** ~108-120 (inside `VoiceParameters.default`)

```swift
voiceLFO: LFOParameters(
    waveform: .sine,              // Waveform shape
    resetMode: .free,             // Phase reset behavior
    frequencyMode: .hertz,        // Hz or tempo sync
    frequency: 3.0,               // Speed in Hz (0.1 - 10)
    destination: .filterCutoff,   // ← EDIT THIS
    amount: 0.4,                  // ← EDIT THIS (0.0 - 1.0)
    isEnabled: true               // ← EDIT THIS (true/false)
),
```

### Voice LFO Destinations
Choose from:
- `.oscillatorAmplitude` - Volume tremolo
- `.oscillatorBaseFrequency` - Vibrato (pitch wobble)
- `.modulationIndex` - FM timbral evolution
- `.modulatingMultiplier` - FM harmonic sweep
- `.filterCutoff` - Filter wobble (default)
- `.stereoSpreadAmount` - Stereo width wobble

### Voice LFO Waveforms
- `.sine` - Smooth, musical (default)
- `.triangle` - Linear rise/fall
- `.square` - Hard switching
- `.sawtooth` - Rising ramp
- `.reverseSawtooth` - Falling ramp

### Suggested Voice LFO Settings

**Classic Filter Wobble:**
```swift
frequency: 2.5,
destination: .filterCutoff,
amount: 0.5,
isEnabled: true
```

**Vibrato:**
```swift
frequency: 5.0,
destination: .oscillatorBaseFrequency,
amount: 0.15,
isEnabled: true
```

**FM Timbral Evolution:**
```swift
frequency: 1.0,
destination: .modulationIndex,
amount: 0.6,
isEnabled: true
```

---

## Global LFO (All-Voice Modulation)

**File:** `A01 SoundParameters.swift`  
**Line:** ~154-161 (inside `MasterParameters.default`)

```swift
globalLFO: GlobalLFOParameters(
    waveform: .sine,
    resetMode: .free,
    frequencyMode: .hertz,
    frequency: 1.5,                    // Speed in Hz
    destination: .oscillatorAmplitude, // ← EDIT THIS
    amount: 0.3,                       // ← EDIT THIS (0.0 - 1.0)
    isEnabled: true                    // ← EDIT THIS (true/false)
),
```

### Global LFO Destinations
Same as Voice LFO, plus:
- `.delayTime` - Rhythmic delay wobble
- `.delayMix` - Delay wet/dry pulsing

### Suggested Global LFO Settings

**Tremolo (Volume Pulsing):**
```swift
frequency: 3.5,
destination: .oscillatorAmplitude,
amount: 0.4,
isEnabled: true
```

**Stereo Width Animation:**
```swift
frequency: 0.8,
destination: .stereoSpreadAmount,
amount: 0.3,
isEnabled: true
```

**Rhythmic Delay:**
```swift
frequency: 2.0,
destination: .delayTime,
amount: 0.5,
isEnabled: true
```

---

## Aftertouch Sensitivity

**File:** `V02 MainKeyboardView.swift`  
**Line:** ~303 (inside `handleAftertouch` method)

```swift
let sensitivity = 2.5  // ← EDIT THIS
```

- **Higher values** (3.0 - 5.0) = More sensitive, larger filter sweeps
- **Lower values** (1.0 - 2.0) = Less sensitive, subtle changes
- **Current default: 2.5** (balanced)

---

## Combining Voice LFO and Global LFO

You can have **both active at once** for complex modulation:

### Example 1: Voice Filter + Global Amplitude
```swift
// Voice LFO (different per note)
voiceLFO: LFOParameters(
    frequency: 3.0,
    destination: .filterCutoff,
    amount: 0.4,
    isEnabled: true
)

// Global LFO (same for all notes)
globalLFO: GlobalLFOParameters(
    frequency: 1.5,
    destination: .oscillatorAmplitude,
    amount: 0.3,
    isEnabled: true
)
```
**Result:** Each note has its own filter wobble (3 Hz), while all notes pulse together (1.5 Hz).

### Example 2: Dual Filter Modulation
```swift
// Voice LFO (fast wobble)
voiceLFO: LFOParameters(
    frequency: 5.0,
    destination: .filterCutoff,
    amount: 0.3,
    isEnabled: true
)

// Global LFO (slow sweep)
globalLFO: GlobalLFOParameters(
    frequency: 0.5,
    destination: .filterCutoff,
    amount: 0.4,
    isEnabled: true
)
```
**Result:** Fast wobble riding on top of a slow sweep.

---

## Quick Testing Workflow

1. **Edit** `A01 SoundParameters.swift` with desired LFO settings
2. **Build and run** the app (⌘R)
3. **Play keys** to hear the LFO effect
4. **Tweak parameters** and rebuild
5. **Use aftertouch** (slide finger) to test interaction with LFOs

---

## Troubleshooting

### "I don't hear any LFO effect"
- Check `isEnabled: true` in both Voice LFO and Global LFO
- Check `amount` is > 0.0 (try 0.5 for testing)
- If destination is `.filterCutoff`, make sure filter cutoff isn't already at max
- Try a more obvious destination like `.oscillatorAmplitude` to verify LFO works

### "The effect is too subtle"
- Increase `amount` to 0.7 or 0.8
- Try a different destination (`.filterCutoff` is usually most obvious)
- Increase `frequency` to make it more noticeable

### "The effect is too extreme"
- Decrease `amount` to 0.2 or 0.3
- Try a smoother waveform (`.sine` instead of `.square`)
- Decrease `frequency` to slow it down

### "Aftertouch doesn't work"
- Check that you're sliding your finger **left/right** (not up/down)
- Increase sensitivity in `MainKeyboardView.swift` line ~303
- Make sure the filter cutoff has room to move (not already at max)

---

## Parameter Value Ranges

### frequency
- **Minimum:** 0.01 Hz (very slow)
- **Musical range:** 0.5 - 10 Hz
- **Typical:** 1.0 - 5.0 Hz
- **Maximum:** 10 Hz (audio rate, can create interesting aliasing)

### amount
- **Minimum:** 0.0 (off)
- **Subtle:** 0.1 - 0.3
- **Moderate:** 0.4 - 0.6 (default)
- **Strong:** 0.7 - 0.9
- **Maximum:** 1.0

### sensitivity (aftertouch)
- **Minimum:** 0.5 (very subtle)
- **Low:** 1.0 - 2.0
- **Default:** 2.5
- **High:** 3.0 - 4.0
- **Maximum:** 5.0+ (extreme)

---

## Current Default Configuration

As of Phase 5C completion:

**Voice LFO:** 
- 3 Hz sine wave
- Filter cutoff destination
- 40% amount
- **ENABLED**

**Global LFO:**
- 1.5 Hz sine wave
- Oscillator amplitude destination
- 30% amount
- **ENABLED**

**Aftertouch:**
- Sensitivity: 2.5
- Exponential scaling (musical)
- Smoothed updates (200 Hz)

---

## Next Steps

After Phase 5C is complete and tested, Phase 5D will add:
- **Touch X position** as a modulation source
- **Aftertouch** as a routable modulation source (not just filter)
- **Key tracking** (frequency-based modulation)

These will become **additional modulation sources** that can be routed to any destination, just like LFOs.
