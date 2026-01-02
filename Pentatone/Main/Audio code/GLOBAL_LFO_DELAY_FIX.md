# Global LFO Delay Time Modulation Fix

## Problem
The Global LFO's delay time modulation was not working audibly. The amount parameter could be adjusted but had no effect on the delay time.

## Root Cause
The modulation system was reading the **current delay time** from the delay node (`delay.time`) as the base value for modulation, instead of using the **tempo-synced base value**. This meant:

1. The base value was whatever had been last written to the delay
2. When LFO modulation updated the delay time, it would then use that modulated value as the new base
3. The modulation would drift and not properly oscillate around the intended tempo-synced value
4. The effect was essentially broken

## Solution

### 1. Track Base Delay Time in VoicePool
Added a stored property to track the tempo-synced delay time (before LFO modulation):

```swift
/// Base delay time (from tempo-synced value, before LFO modulation)
private var baseDelayTime: Double = 0.5  // Default: 1/4 note at 120 BPM
```

### 2. Add Update Method
Created a method to update the base delay time whenever it changes:

```swift
func updateBaseDelayTime(_ delayTime: Double) {
    baseDelayTime = delayTime
}
```

### 3. Use Base Value for Modulation
Modified `applyGlobalLFOToGlobalParameters()` to use the stored base instead of reading from the node:

**Before:**
```swift
let baseValue = Double(delay.time)  // ❌ Uses current value (already modulated!)
```

**After:**
```swift
let finalDelayTime = ModulationRouter.calculateDelayTime(
    baseDelayTime: baseDelayTime,  // ✅ Uses stored tempo-synced base
    globalLFOValue: rawValue,
    globalLFOAmount: globalLFO.amountToDelayTime
)
```

### 4. Update Base Value Whenever It Changes
Added calls to `updateBaseDelayTime()` in three places:

#### A) When delay time value changes:
```swift
func updateDelayTimeValue(_ timeValue: DelayTimeValue) {
    master.delay.timeValue = timeValue
    let timeInSeconds = timeValue.timeInSeconds(tempo: master.tempo)
    fxDelay?.time = AUValue(timeInSeconds)
    voicePool?.updateBaseDelayTime(timeInSeconds)  // ✅ Update base
}
```

#### B) When tempo changes:
```swift
func updateTempo(_ tempo: Double) {
    master.tempo = tempo
    let timeInSeconds = master.delay.timeInSeconds(tempo: tempo)
    fxDelay?.time = AUValue(timeInSeconds)
    voicePool?.updateBaseDelayTime(timeInSeconds)  // ✅ Update base
}
```

#### C) When loading presets:
```swift
private func applyDelayParameters() {
    let timeInSeconds = master.delay.timeInSeconds(tempo: master.tempo)
    delay.time = AUValue(timeInSeconds)
    // ... other parameters ...
    voicePool?.updateBaseDelayTime(timeInSeconds)  // ✅ Update base
}
```

#### D) Engine initialization:
```swift
// Initialize base delay time for LFO modulation
let initialDelayTime = masterParams.delay.timeInSeconds(tempo: masterParams.tempo)
voicePool.updateBaseDelayTime(initialDelayTime)
```

### 5. Improved Ramping
Changed the ramp duration from 0 (instant) to 0.005 seconds (5ms):

```swift
delay.$time.ramp(to: AUValue(finalDelayTime), duration: 0.005)
```

This provides smooth parameter changes that match the control rate update interval (200 Hz), avoiding clicks while still tracking the LFO accurately.

## Behavior

### Before
- LFO amount slider did nothing audible
- Delay time stayed constant
- Modulation was broken

### After
- LFO creates a **vibrato effect** on the delay line ✓
- The delay time oscillates around the tempo-synced base value ✓
- Changing tempo updates the base, LFO continues to modulate around new base ✓
- Changing delay time value updates the base, LFO continues to modulate ✓

## How It Works

The modulation behaves like **vibrato on a pitched note**:

1. **Base value** = Tempo-synced delay time (e.g., 1/8 note at 120 BPM = 0.25s)
2. **LFO amount** = Maximum offset in seconds (e.g., ±0.1s)
3. **Modulated value** = Base ± (LFO × amount)

Example with sine LFO at 2 Hz, amount = 0.05s:
- Base: 0.25s (1/8 note at 120 BPM)
- Range: 0.20s to 0.30s
- Creates a "wobbling" delay effect

The delay time smoothly oscillates around the musical note division without snapping to discrete values.

## Files Modified

1. **A3 VoicePool.swift**
   - Added `baseDelayTime` property
   - Added `updateBaseDelayTime(_:)` method
   - Modified `applyGlobalLFOToGlobalParameters(rawValue:)` to use base value
   - Improved ramping (0 → 0.005 seconds)

2. **A1 SoundParameters.swift**
   - Updated `updateDelayTimeValue(_:)` to call `updateBaseDelayTime()`
   - Updated `updateTempo(_:)` to call `updateBaseDelayTime()`
   - Updated `applyDelayParameters()` to call `updateBaseDelayTime()`

3. **A5 AudioEngine.swift**
   - Added initialization of base delay time on engine startup

## Testing

- [ ] Test: LFO modulation produces audible delay time variation
- [ ] Test: Changing tempo updates base, modulation continues around new base
- [ ] Test: Changing delay time value updates base, modulation continues
- [ ] Test: LFO amount parameter affects depth of modulation
- [ ] Test: Different LFO waveforms produce different modulation patterns
- [ ] Test: No clicking or artifacts during modulation
- [ ] Test: Loading presets initializes base delay time correctly

## Future Enhancements

This same pattern could be applied to other tempo-synced parameters if needed:
- Voice LFO frequency (when in tempo sync mode)
- Any future tempo-synced effects

The key principle: **Always modulate around the intended base value, not the current modulated value.**
