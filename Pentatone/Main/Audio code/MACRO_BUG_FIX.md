//
//  MACRO_BUG_FIX.md
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//

# Macro Control Bug Fix - Ambience Issue

## Problem Description

The ambience macro was behaving incorrectly:
1. Moving slider up: reverb increases but delay stops
2. Returning to center: all parameters go to zero instead of 0.5
3. Moving slider down: values also set to zero

## Root Causes

### 1. Mismatched Default Values
The `MacroControlState.default` base values didn't match the actual default parameter values:

**Before:**
```swift
MacroControlState.default:
  baseDelayFeedback: 0.2      // ❌ Doesn't match
  baseDelayMix: 0.0           // ❌ Doesn't match
  baseReverbFeedback: 0.9     // ❌ Doesn't match
  baseReverbMix: 0.0          // ❌ Doesn't match

DelayParameters.default:
  feedback: 0.5               // ✓ Actual default
  dryWetMix: 0.5              // ✓ Actual default

ReverbParameters.default:
  feedback: 0.5               // ✓ Actual default
  balance: 0.5                // ✓ Actual default
```

**After Fix:**
```swift
MacroControlState.default:
  baseDelayFeedback: 0.5      // ✅ Matches DelayParameters.default.feedback
  baseDelayMix: 0.5           // ✅ Matches DelayParameters.default.dryWetMix
  baseReverbFeedback: 0.5     // ✅ Matches ReverbParameters.default.feedback
  baseReverbMix: 0.5          // ✅ Matches ReverbParameters.default.balance
```

### 2. Volume Position Initialization
The volume macro is **absolute** (not relative), so its position should match the current preVolume value.

**Before:**
```swift
MacroControlState.default:
  basePreVolume: 0.5
  volumePosition: 0.0         // ❌ Doesn't match
```

**After Fix:**
```swift
MacroControlState.default:
  basePreVolume: 0.5
  volumePosition: 0.5         // ✅ Matches preVolume
```

### 3. Volume Macro Update Method
The `updateVolumeMacro()` was calling `updatePreVolume()`, which updates `master.output.preVolume` but then when `captureBaseValues()` was called, it would capture that value but reset the position to 0.0, creating a mismatch.

**Before:**
```swift
func updateVolumeMacro(_ position: Double) {
    macroState.volumePosition = clampedPosition
    updatePreVolume(clampedPosition)  // ❌ This updates master.output.preVolume
}

func captureBaseValues() {
    macroState.basePreVolume = master.output.preVolume  // Gets the updated value
    macroState.volumePosition = 0.0  // ❌ But resets position to 0!
}
```

**After Fix:**
```swift
func updateVolumeMacro(_ position: Double) {
    macroState.volumePosition = clampedPosition
    master.output.preVolume = clampedPosition  // ✅ Direct update
    voicePool?.voiceMixer.volume = AUValue(clampedPosition)
}

func captureBaseValues() {
    macroState.basePreVolume = master.output.preVolume
    macroState.volumePosition = master.output.preVolume  // ✅ Matches preVolume
    macroState.tonePosition = 0.0
    macroState.ambiencePosition = 0.0
}
```

## Why This Caused the Ambience Bug

When the ambience macro was moved:

1. **Initial state** (app launch):
   - Actual delay/reverb parameters: 0.5 (from DelayParameters.default)
   - Base values in MacroControlState: 0.2, 0.0, 0.9, 0.0 (wrong!)
   - Ambience position: 0.0 (center)

2. **User moves ambience up to +0.5**:
   ```
   newDelayFeedback = 0.2 + (0.5 × 0.5) = 0.45   // Using wrong base (0.2)
   newDelayMix = 0.0 + (0.5 × 0.5) = 0.25        // Using wrong base (0.0)
   newReverbFeedback = 0.9 + (0.5 × 0.5) = 1.15  // Using wrong base (0.9)
   newReverbMix = 0.0 + (0.5 × 0.5) = 0.25       // Using wrong base (0.0)
   ```
   - Delay decreased (was 0.5, now 0.45)
   - Reverb increased to max (clamped at 1.0)
   - This explains why delay seemed to "stop" while reverb increased!

3. **User returns ambience to center (0.0)**:
   ```
   newDelayFeedback = 0.2 + (0.0 × 0.5) = 0.2    // Returns to wrong base
   newDelayMix = 0.0 + (0.0 × 0.5) = 0.0         // Returns to wrong base
   newReverbFeedback = 0.9 + (0.0 × 0.5) = 0.9   // Returns to wrong base
   newReverbMix = 0.0 + (0.0 × 0.5) = 0.0        // Returns to wrong base
   ```
   - Values return to the wrong bases, not the actual defaults!

## Solution

The fix ensures that:

1. **Default base values match actual parameter defaults**
2. **Volume position is initialized to match preVolume** (since it's absolute)
3. **`captureBaseValues()` correctly handles volume position**
4. **Volume macro directly updates both `master.output.preVolume` and the hardware**

## Testing the Fix

After this fix, the ambience macro should behave correctly:

1. **App launches with defaults**:
   - All parameters at 0.5
   - Base values at 0.5
   - Ambience position at 0.0 (center)

2. **User moves ambience up to +0.5**:
   ```
   newDelayFeedback = 0.5 + (0.5 × 0.5) = 0.75   ✅ Increased
   newDelayMix = 0.5 + (0.5 × 0.5) = 0.75        ✅ Increased
   newReverbFeedback = 0.5 + (0.5 × 0.5) = 0.75  ✅ Increased
   newReverbMix = 0.5 + (0.5 × 0.5) = 0.75       ✅ Increased
   ```

3. **User returns ambience to center (0.0)**:
   ```
   newDelayFeedback = 0.5 + (0.0 × 0.5) = 0.5    ✅ Back to base
   newDelayMix = 0.5 + (0.0 × 0.5) = 0.5         ✅ Back to base
   newReverbFeedback = 0.5 + (0.0 × 0.5) = 0.5   ✅ Back to base
   newReverbMix = 0.5 + (0.0 × 0.5) = 0.5        ✅ Back to base
   ```

4. **User moves ambience down to -0.5**:
   ```
   newDelayFeedback = 0.5 + (-0.5 × 0.5) = 0.25  ✅ Decreased
   newDelayMix = 0.5 + (-0.5 × 0.5) = 0.25       ✅ Decreased
   newReverbFeedback = 0.5 + (-0.5 × 0.5) = 0.25 ✅ Decreased
   newReverbMix = 0.5 + (-0.5 × 0.5) = 0.25      ✅ Decreased
   ```

## Important: When to Call `captureBaseValues()`

**Always call after loading a preset or changing parameters directly:**

```swift
// After loading a preset
AudioParameterManager.shared.loadPreset(preset)
AudioParameterManager.shared.captureBaseValues()

// After direct parameter changes (optional but recommended)
AudioParameterManager.shared.updateDelayFeedback(0.7)
AudioParameterManager.shared.updateReverbMix(0.3)
AudioParameterManager.shared.captureBaseValues()  // Reset macros to new baseline
```

This ensures that the base values always match the actual parameter state, and macro positions are reset to neutral (or current value for volume).

## Summary of Changes

1. ✅ Fixed `MacroControlState.default` to match parameter defaults
2. ✅ Fixed volume position initialization (0.5 instead of 0.0)
3. ✅ Fixed `updateVolumeMacro()` to directly update parameters
4. ✅ Fixed `captureBaseValues()` to set volume position correctly

The ambience macro should now work perfectly! 🎉
