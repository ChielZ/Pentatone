# Phase 5C: Touch Control Fix

## Problem Identified

After implementing LFO modulation in Phase 5C, the initial touch position and aftertouch controls stopped working. The issue was a conflict between the touch-based control system and the modulation system.

### Root Cause

The modulation system was reading the **current** audio parameter values (amplitude and filter cutoff) as the "base value" for LFO modulation. This created a feedback loop:

1. User touches key → amplitude and cutoff are set directly on the voice
2. 200 Hz modulation timer runs → reads those values back as "base"
3. LFO modulation is applied → overwrites the touch-controlled values
4. Next modulation cycle → reads the modulated values as new "base"
5. This completely broke the touch control system

### Example of the Problem

```swift
// In MainKeyboardView (touch handler):
voice.oscLeft.amplitude = AUValue(0.8)  // Set by touch

// In PolyphonicVoice.applyVoiceLFO() - 5ms later:
let baseValue = Double(oscLeft.amplitude)  // Reads 0.8
let modulated = baseValue + lfoModulation  // Calculates 0.8 + wobble
oscLeft.amplitude = AUValue(modulated)     // Overwrites with modulated value

// Next cycle (5ms later):
let baseValue = Double(oscLeft.amplitude)  // Reads the modulated value!
// The touch-controlled value (0.8) is now lost forever
```

## Solution

### 1. Added Base Value Storage to ModulationState

Added two new fields to `ModulationState` to store the **user's intended values** before modulation:

```swift
struct ModulationState {
    // ... existing fields ...
    
    // User-controlled base values (before modulation)
    var baseAmplitude: Double = 0.5        // User's desired amplitude
    var baseFilterCutoff: Double = 1000.0  // User's desired filter cutoff
}
```

### 2. Created Touch Control Methods on PolyphonicVoice

Added two new methods to properly set touch-controlled parameters:

```swift
/// Sets the amplitude from touch input
/// This updates the base amplitude in modulation state, which LFOs will modulate
func setAmplitudeFromTouch(_ amplitude: Double) {
    let clamped = max(0.0, min(1.0, amplitude))
    modulationState.baseAmplitude = clamped  // Store for modulation
    oscLeft.amplitude = AUValue(clamped)     // Apply immediately
    oscRight.amplitude = AUValue(clamped)
}

/// Sets the filter cutoff from touch input
/// This updates the base cutoff in modulation state, which LFOs will modulate
func setFilterCutoffFromTouch(_ cutoff: Double) {
    let clamped = max(20.0, min(22050.0, cutoff))
    modulationState.baseFilterCutoff = clamped  // Store for modulation
    filter.cutoffFrequency = AUValue(clamped)    // Apply immediately
}
```

### 3. Updated LFO Application to Use Base Values

Modified `applyVoiceLFO()` and `applyGlobalLFO()` to use the stored base values:

```swift
// OLD (broken):
let baseValue = Double(oscLeft.amplitude)  // Reads modulated value!

// NEW (fixed):
let baseValue = modulationState.baseAmplitude  // Reads user's value
```

### 4. Updated MainKeyboardView Touch Handlers

Changed the touch handlers to use the new methods:

```swift
// OLD (broken):
voice.oscLeft.amplitude = AUValue(normalized)
voice.oscRight.amplitude = AUValue(normalized)

// NEW (fixed):
voice.setAmplitudeFromTouch(normalized)

// OLD (broken):
voice.filter.cutoffFrequency = AUValue(smoothedCutoff)

// NEW (fixed):
voice.setFilterCutoffFromTouch(smoothedCutoff)
```

## How It Works Now

### Correct Flow

1. **User touches key** → `handleTrigger()` calls `voice.setAmplitudeFromTouch(0.8)`
2. **Touch method** → Stores `modulationState.baseAmplitude = 0.8` AND applies to `oscLeft.amplitude`
3. **Modulation timer (5ms later)** → Reads `modulationState.baseAmplitude` (still 0.8)
4. **LFO calculation** → `modulated = 0.8 + lfoWobble` (e.g., 0.85)
5. **Apply modulation** → Sets `oscLeft.amplitude = 0.85`
6. **Next cycle** → Reads `modulationState.baseAmplitude` (still 0.8!)
7. **LFO calculation** → `modulated = 0.8 + lfoWobble` (e.g., 0.75)
8. **Result:** LFO oscillates **around** the user's touch value (0.8)

### User moves finger (aftertouch)

1. **Aftertouch handler** → `voice.setFilterCutoffFromTouch(2000)`
2. **Touch method** → Updates `modulationState.baseFilterCutoff = 2000`
3. **Modulation system** → Now modulates around the new value (2000 Hz)
4. **Result:** User control is preserved, LFO adds movement on top

## Benefits

✅ **Touch control works again** - Initial touch position controls amplitude  
✅ **Aftertouch works again** - Finger movement controls filter cutoff  
✅ **LFO modulation still works** - Oscillates around user-controlled values  
✅ **Clean separation** - User control and modulation don't interfere  
✅ **Predictable behavior** - LFO amount is always relative to user's setting  

## Files Modified

1. **A06 ModulationSystem.swift**
   - Added `baseAmplitude` and `baseFilterCutoff` to `ModulationState`

2. **A02 PolyphonicVoice.swift**
   - Added `setAmplitudeFromTouch()` method
   - Added `setFilterCutoffFromTouch()` method
   - Updated `applyVoiceLFO()` to use base values
   - Updated `applyGlobalLFO()` to use base values

3. **V02 MainKeyboardView.swift**
   - Updated `handleTrigger()` to use new touch methods
   - Updated `handleAftertouch()` to use new touch methods

## Testing

After applying this fix:

1. ✅ Touch a key on the outer edge → loud sound
2. ✅ Touch a key on the inner edge → quiet sound
3. ✅ Move finger left/right while holding → filter sweeps
4. ✅ LFO modulation (if active) → adds wobble on top of touch control
5. ✅ No interference between touch and LFO

## Architecture Lesson

**Key principle:** When implementing modulation, always separate:
- **User control layer** (direct input from user)
- **Modulation layer** (automated parameter changes)

The modulation layer should **never read back** the final audio parameters as base values, because those parameters contain both user control AND modulation. This creates feedback loops.

Instead, store the user's intended values separately, and have modulation **always** start from those stored values.

## Next Steps

Phase 5C is now complete with touch control working correctly. The next substage is **Phase 5D: Touch & Key Tracking**, which will add:
- Initial touch X as a modulation source (routable destination)
- Aftertouch X as a modulation source (routable destination)
- Key tracking (frequency-based modulation)

These will build on the `ModulationState` infrastructure we just enhanced.
