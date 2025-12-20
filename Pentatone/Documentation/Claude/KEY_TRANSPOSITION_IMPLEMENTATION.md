# Key Transposition Implementation

## Overview

The key transposition feature has been successfully implemented for your pentatonic music app. This allows users to change the musical key of the scale while maintaining the same scale structure (celestial/terrestrial/intonation settings).

## Key Features

### 1. **MusicalKey Enum** (in `Scales.swift`)
- Defines 13 musical keys: Ab, Eb, Bb, F, C, G, **D** (default), A, E, B, F#, C#, G#
- **D is the center/default key** at 146.83 Hz
- Non-looping navigation (stops at Ab on the left, G# on the right)
- Supports both Equal Temperament (ET) and Just Intonation (JI)

### 2. **Pitch Factor Calculation**
The enum provides two methods for calculating pitch transposition:

#### Equal Temperament (ET)
Uses the formula: `2^(semitones/12)`
- Example: F = +3 semitones = `2^(3/12)` = ~1.189
- Example: C = -2 semitones = `2^(-2/12)` = ~0.891

#### Just Intonation (JI)
Uses exact frequency ratios:
- Example: F = 32/27 = ~1.185
- Example: C = 8/9 = ~0.889

### 3. **Zero Cumulative Error**
The implementation ensures **no cumulative error** when cycling through keys:
- The base frequency is always `MusicalKey.baseFrequency = 146.83 Hz`
- Key D has a pitch factor of exactly `1.0` (both ET and JI)
- Each key change multiplies the base frequency by its specific factor
- Returning to D always results in exactly 146.83 Hz, regardless of how many key changes occurred

Mathematical proof:
```
frequency_for_key_X = baseFrequency * pitchFactor(X)
frequency_for_key_D = baseFrequency * 1.0 = 146.83 (exact)
```

### 4. **Updated Function Signature**
The `makeKeyFrequencies()` function now accepts an optional `musicalKey` parameter:

```swift
func makeKeyFrequencies(
    for scale: Scale, 
    baseFrequency: Double = MusicalKey.baseFrequency,  // Default: 146.83 Hz
    musicalKey: MusicalKey = .D                        // Default: D (center key)
) -> [Double]
```

This function:
1. Applies rotation to the scale notes
2. Multiplies the base frequency by the key's pitch factor
3. Generates all 18 key frequencies across 4 octaves

### 5. **UI Integration**

#### ScaleView (Row 6)
- Shows current key with `<` and `>` buttons
- Displays the key name (e.g., "D", "F#", "Bb")
- Non-looping navigation

#### State Management (PentatoneApp.swift)
- `@State private var musicalKey: MusicalKey = .D` tracks current key
- `cycleKey(forward: Bool)` handles key navigation
- `applyCurrentScale()` uses the current key when generating frequencies

## Usage Example

When the user:
1. Starts app → Key = D, frequency = 146.83 Hz
2. Presses `>` to change key → Key = A, frequency = 146.83 × (3/4) = 110.12 Hz (JI)
3. Presses `>` multiple times → Cycles through E, B, F#, C#, G#
4. Returns to D → frequency = 146.83 Hz (exactly, no rounding error)

## Files Modified

1. **Scales.swift**
   - Added `MusicalKey` enum with pitch factors
   - Updated `makeKeyFrequencies()` to accept key transposition
   - Added documentation comment

2. **PentatoneApp.swift**
   - Added `@State private var musicalKey: MusicalKey = .D`
   - Added `cycleKey(forward:)` method
   - Updated `applyCurrentScale()` to use musical key
   - Updated `MainKeyboardView` initialization

3. **MainKeyboardView.swift**
   - Added `currentKey` and `onCycleKey` parameters
   - Passed parameters to `OptionsView`

4. **OptionsView.swift**
   - Added `currentKey` and `onCycleKey` parameters
   - Passed parameters to `ScaleView`

5. **ScaleView.swift**
   - Added `currentKey` and `onCycleKey` parameters
   - Updated Row 6 to display and cycle musical keys

6. **AudioKitCode.swift**
   - Updated test view to use new function signature

## Testing

To test the implementation:
1. Launch the app
2. Open the options panel (unfold)
3. Navigate to the SCALE view
4. Use Row 6 to cycle through keys using `<` and `>` buttons
5. Play notes to hear the transposed scale
6. Verify that returning to D always sounds the same (no drift)

## Technical Notes

- The pitch factors for each key are **hardcoded** based on your original specification
- This ensures exact, predictable behavior with no floating-point accumulation errors
- The key order in the enum matches the physical left-to-right arrangement you specified
- Sharp keys use `Fs`, `Cs`, `Gs` as enum names (since # is not allowed) but display as "F#", "C#", "G#"
