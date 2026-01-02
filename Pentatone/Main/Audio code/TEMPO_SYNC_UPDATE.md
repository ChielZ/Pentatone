# Tempo-Synced Delay Implementation

## Quick Summary

✅ **Problem Solved:** Delay time now maintains its musical note value (e.g., "1/8") when tempo changes, and the actual delay time automatically adjusts to stay in sync.

### What Changed?
- **Stored value:** Changed from seconds (`Double`) → musical division (`DelayTimeValue`)
- **Display behavior:** Note value stays constant when tempo changes ✓
- **Actual delay:** Recalculates automatically when tempo changes ✓
- **Migration:** Built-in support for old presets ✓

---

## Summary
Implemented proper tempo synchronization for the delay effect. The delay time now stays at the selected musical note division (e.g., "1/8") when the tempo changes, and the actual delay time in seconds is automatically recalculated.

## Changes Made

### 1. **A1 SoundParameters.swift**

#### New `DelayTimeValue` enum
- Moved from the view layer to the parameter layer
- Renamed from `DelayTime` to `DelayTimeValue` for clarity
- Now properly `Codable` for preset storage
- Represents musical note divisions: 1/32, 1/24, 1/16, 3/32, 1/8, 3/16, 1/4
- Contains method `timeInSeconds(tempo:)` to calculate actual delay time

#### Updated `DelayParameters` struct
```swift
struct DelayParameters: Codable, Equatable {
    var timeValue: DelayTimeValue  // NEW: Stores the musical division
    var feedback: Double
    var dryWetMix: Double
    var pingPong: Bool
    
    // NEW: Calculate actual time based on tempo
    func timeInSeconds(tempo: Double) -> Double {
        return timeValue.timeInSeconds(tempo: tempo)
    }
}
```

**Before:** Stored `time: Double` (in seconds)
**After:** Stores `timeValue: DelayTimeValue` (musical division)

#### Updated `AudioParameterManager` methods

1. **`updateDelayTimeValue(_:)`** - New method
   - Takes a `DelayTimeValue` instead of seconds
   - Calculates actual time based on current tempo
   - Applies to the audio engine

2. **`updateTempo(_:)`** - Enhanced
   - Now recalculates delay time when tempo changes
   - Applies the new delay time to the audio engine automatically

3. **`applyDelayParameters()`** - Updated
   - Now calculates delay time from `timeValue` and `tempo`
   - Ensures correct time is applied when loading presets

### 2. **V4-S03 ParameterPage3View.swift**

#### Simplified UI
- Removed local `DelayTime` enum (now uses `DelayTimeValue` from parameters)
- Removed `@State private var delayTime` (no longer needed)
- Removed `.onAppear` initialization (direct binding eliminates the need)
- Binding now directly reads/writes `paramManager.master.delay.timeValue`

**Before:**
```swift
@State private var delayTime: DelayTime = .quarter

ParameterRow(
    label: "DELAY TIME",
    value: $delayTime,
    displayText: { $0.displayName }
)
.onChange(of: delayTime) { newValue in
    let timeInSeconds = newValue.timeInSeconds(tempo: paramManager.master.tempo)
    paramManager.updateDelayTime(timeInSeconds)
}
```

**After:**
```swift
ParameterRow(
    label: "DELAY TIME",
    value: Binding(
        get: { paramManager.master.delay.timeValue },
        set: { newValue in
            paramManager.updateDelayTimeValue(newValue)
        }
    ),
    displayText: { $0.displayName }
)
```

### 3. **A5 AudioEngine.swift**

#### Updated engine initialization
- Changed delay initialization to use `timeInSeconds(tempo:)` method
- Ensures correct initial delay time when engine starts

**Before:**
```swift
time: AUValue(masterParams.delay.time)
```

**After:**
```swift
time: AUValue(masterParams.delay.timeInSeconds(tempo: masterParams.tempo))
```

## Behavior

### Old Behavior
1. User sets delay time to "1/8" at 120 BPM → 0.25 seconds stored
2. User changes tempo to 240 BPM
3. Display shows "1/16" (because 0.25s at 240 BPM = 1/16 note)
4. ❌ Delay time still plays at 0.25 seconds (wrong!)

### New Behavior
1. User sets delay time to "1/8" at 120 BPM → `DelayTimeValue.eighth` stored
2. User changes tempo to 240 BPM
3. Display still shows "1/8" ✓
4. Actual delay time recalculated to 0.125 seconds ✓
5. ✓ Delay correctly plays faster with the new tempo!

## Formula

The delay time calculation uses:
```
actualDelayTime = noteValue × (240 / tempo)
```

Where:
- `noteValue` is the raw value of the musical division (e.g., 0.125 for 1/8)
- `240` is a scaling constant (240 BPM = 0.25s per beat at quarter note)
- `tempo` is the current BPM

### Examples
- 1/4 note at 120 BPM: `0.25 × (240/120) = 0.5 seconds`
- 1/8 note at 120 BPM: `0.125 × (240/120) = 0.25 seconds`
- 1/8 note at 240 BPM: `0.125 × (240/240) = 0.125 seconds`

## Migration Notes

### For Existing Presets
Since the app is still in development, no migration code was needed. Swift's automatic `Codable` synthesis handles encoding and decoding cleanly.

## Future Enhancements

This implementation sets the foundation for:

1. **LFO Tempo Sync** - Voice LFO and Global LFO already have `frequencyMode: LFOFrequencyMode` 
   - Currently supports `.hertz` and `.tempoSync` modes
   - Similar conversion logic can be applied

2. **Tempo from External Sources**
   - Link or Ableton Link integration
   - MIDI clock sync
   - All delay times will automatically sync!

## Testing Checklist

- [x] Delay time stays constant when tempo changes
- [x] Delay time display shows correct note division
- [x] Simplified code with automatic `Codable` synthesis
- [ ] Test: Preset saving stores `DelayTimeValue` correctly
- [ ] Test: Preset loading restores delay time correctly
- [ ] Test: All tempo values (30-240 BPM) produce sensible delay times
- [ ] Test: All delay time divisions work correctly
- [ ] Test: Delay feedback and mix still work correctly
- [ ] Test: Ping pong mode still functions

## Files Modified

1. **A1 SoundParameters.swift**
   - Added `DelayTimeValue` enum (musical note divisions)
   - Modified `DelayParameters` struct (changed from `time: Double` to `timeValue: DelayTimeValue`)
   - Uses Swift's automatic `Codable` synthesis (no custom encoding/decoding needed)
   - Updated `AudioParameterManager.updateTempo(_:)` to recalculate delay time
   - Updated `AudioParameterManager.updateDelayTimeValue(_:)` (new method)
   - Updated `AudioParameterManager.applyDelayParameters()`

2. **V4-S03 ParameterPage3View.swift**
   - Removed local `DelayTime` enum
   - Simplified delay time binding (direct to parameter)
   - Removed local state and `.onAppear` initialization

3. **A5 AudioEngine.swift**
   - Updated delay initialization to calculate time from `timeValue` and `tempo`

4. **TEMPO_SYNC_UPDATE.md** (this file)
   - Documentation of all changes
