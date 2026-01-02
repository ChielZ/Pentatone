//
//  MACRO_QUICK_START.md
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//

# Macro Controls - Quick Start Guide

## What's Been Implemented

I've implemented a complete macro control system for your app with three main controls:

1. **Volume** - Direct control of pre-FX volume (0-100%)
2. **Tone** - Controls brightness/harmonics by adjusting modulation index, filter cutoff, and saturation (-100% to +100%)
3. **Ambience** - Controls spatial depth by adjusting delay and reverb parameters (-100% to +100%)

## Files Modified

### 1. `A1 SoundParameters.swift`
- ✅ Added `MacroControlParameters` struct (defines ranges)
- ✅ Added `MacroControlState` struct (stores positions and base values)
- ✅ Added to `MasterParameters` and `AudioParameterSet`
- ✅ Added all necessary methods to `AudioParameterManager`

### 2. `V4-S11 ParameterPage11View.swift` (MacroView)
- ✅ Replaced placeholder UI with working sliders
- ✅ Allows users to adjust macro ranges in advanced editor

### 3. `MacroControlsView.swift` (NEW)
- ✅ Created simple UI for main app view
- ✅ Three sliders for Volume, Tone, Ambience
- ✅ Ready to be added to V3-S2 SoundView

### 4. Documentation (NEW)
- ✅ `MACRO_CONTROLS_GUIDE.md` - Complete technical documentation
- ✅ `MACRO_IMPLEMENTATION_SUMMARY.md` - Detailed change summary
- ✅ `MACRO_QUICK_START.md` - This file!

## How to Use It

### Step 1: Add Macro Controls to Your Main UI

In your **V3-S2 SoundView** (or wherever you want the controls), add:

```swift
import SwiftUI

struct SoundView: View {
    var body: some View {
        VStack {
            // Your existing content (preset selector, etc.)
            
            // ADD THIS:
            MacroControlsView()
                .padding()
            
            // Rest of your UI
        }
    }
}
```

### Step 2: Capture Base Values When Loading Presets

Whenever you load a preset, add one line:

```swift
// Your existing code:
AudioParameterManager.shared.loadPreset(selectedPreset)

// ADD THIS LINE:
AudioParameterManager.shared.captureBaseValues()
```

This tells the macro system "these are the starting values" so the macros work relative to them.

### Step 3: Test It!

1. Run your app
2. Load a preset (make sure you call `captureBaseValues()` after loading)
3. Try the macro controls:
   - **Volume**: Should directly control volume
   - **Tone**: Should brighten/darken the sound
   - **Ambience**: Should add/reduce reverb and delay

## How It Works (Simple Explanation)

### Volume
Super simple: The slider position (0-100%) directly sets the pre-FX volume.

### Tone
When you move the tone slider:
- **Center (0%)**: Uses the preset's original values
- **Up (+50%)**: Increases modulation index, filter cutoff, and saturation
- **Down (-50%)**: Decreases those same parameters

The amount of change is set in the advanced editor (V4-S11).

### Ambience
When you move the ambience slider:
- **Center (0%)**: Uses the preset's original values  
- **Up (+50%)**: Increases delay/reverb feedback and mix
- **Down (-50%)**: Decreases delay/reverb feedback and mix

Again, the amount of change is adjustable in the advanced editor.

## Advanced Editor (V4-S11 ParameterPage11View)

Users can adjust how much effect each macro has:

- **Tone to Mod Index**: ±0-5 (default: 2.5)
- **Tone to Cutoff**: ±0-4 octaves (default: 2.0)
- **Tone to Saturation**: ±0-2 (default: 1.0)
- **Ambience to Delay FB**: ±0-1 (default: 0.5)
- **Ambience to Delay Mix**: ±0-1 (default: 0.5)
- **Ambience to Reverb Size**: ±0-1 (default: 0.5)
- **Ambience to Reverb Mix**: ±0-1 (default: 0.5)

These ranges are stored per-preset, so different sounds can have different macro sensitivities.

## Workflow Example

Let's say you have a preset called "Warm Pad":

```
1. User loads "Warm Pad" preset
   - Mod Index: 2.0
   - Filter Cutoff: 800 Hz
   - Reverb Mix: 0.3
   
2. captureBaseValues() is called
   - Stores these as base values
   - Resets all macro positions to 0 (center)
   
3. User moves Tone slider to +50%
   - Mod Index becomes: 2.0 + (0.5 × 2.5) = 3.25
   - Cutoff becomes: 800 × 2^(0.5 × 2.0) = 1600 Hz
   - Saturation becomes: original + (0.5 × 1.0) = increased
   
4. User moves Ambience slider to +75%
   - Reverb Mix becomes: 0.3 + (0.75 × 0.5) = 0.675
   - Delay and reverb are more prominent
   
5. Sound is now brighter and more spacious!
```

## Optional: Recapture Base Values After Manual Edits

If a user tweaks parameters directly in the advanced editor, you can optionally call:

```swift
AudioParameterManager.shared.captureBaseValues()
```

This will:
- Store the new parameter values as base values
- Reset all macro positions to 0
- Allow macros to work relative to the new edited values

This is optional but can be useful if you want macros to always work from the "current state" rather than the "loaded preset state".

## Technical Notes

### Mathematical Formulas

**Volume:**
```
preVolume = position (0.0 to 1.0)
```

**Tone - Modulation Index:**
```
newValue = base + (position × range)
```

**Tone - Filter Cutoff:**
```
newValue = base × 2^(position × octaves)
```
This gives equal musical intervals (octaves).

**Tone - Filter Saturation:**
```
newValue = base + (position × range)
```

**Ambience - All Parameters:**
```
newValue = base + (position × range)
```

### Clamping

All values are automatically clamped to valid ranges:
- Mod Index: 0-10
- Filter Cutoff: 20-20000 Hz
- Saturation: 0-10
- Delay/Reverb: 0-1

## Customization Ideas

The system is designed to be flexible. You could:

1. **Change which parameters are affected** by modifying the `applyToneMacro()` and `applyAmbienceMacro()` methods
2. **Add more macros** by following the same pattern
3. **Create preset-specific macro ranges** (already supported!)
4. **Add MIDI CC control** for the macro sliders
5. **Add visual indicators** showing which parameters are being affected
6. **Add "reset" buttons** to return macros to center position

## Troubleshooting

**Macros don't seem to work:**
- Did you call `captureBaseValues()` after loading the preset?
- Are the macro ranges set to non-zero values in the advanced editor?

**Values jump when moving macros:**
- Check that base values were captured correctly
- Verify the ranges aren't set too high

**Presets don't remember macro positions:**
- Macro positions are saved in presets, check that `macroState` is being loaded
- Call `captureBaseValues()` to reset positions if needed

**Parameters don't update in advanced editor:**
- The macros affect the actual parameters, so changes should be visible
- Check that `applyToneMacro()` and `applyAmbienceMacro()` are being called

## What's Next?

After integration:

1. ✅ Test with different presets
2. ✅ Adjust default macro ranges if needed
3. ✅ Consider UI/UX improvements (visual feedback, etc.)
4. ✅ Add preset management system (saves macro state automatically)
5. ⏳ Consider MIDI mapping for macro controls (future enhancement)

## Questions?

If you have questions about the implementation, check:
- `MACRO_CONTROLS_GUIDE.md` for detailed technical documentation
- `MACRO_IMPLEMENTATION_SUMMARY.md` for a complete list of changes
- The inline comments in `A1 SoundParameters.swift`

The system is fully functional and ready to use! Just add `MacroControlsView` to your main UI and remember to call `captureBaseValues()` when loading presets.
