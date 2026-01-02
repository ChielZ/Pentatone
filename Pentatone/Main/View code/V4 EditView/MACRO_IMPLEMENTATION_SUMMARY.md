//
//  MACRO_IMPLEMENTATION_SUMMARY.md
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//

# Macro Controls Implementation Summary

## Changes Made

### 1. A1 SoundParameters.swift

#### Added Data Structures:

**`MacroControlParameters`**
- Stores the ranges for each macro control
- Includes tone parameters (mod index, cutoff, saturation)
- Includes ambience parameters (delay and reverb)
- Added to `MasterParameters` struct

**`MacroControlState`**
- Stores base values for all affected parameters
- Stores current macro positions (volume, tone, ambience)
- Added as property in `AudioParameterManager`

#### Updated `MasterParameters`:
- Added `macroControl: MacroControlParameters` field

#### Updated `AudioParameterSet`:
- Added `macroState: MacroControlState` field for preset storage

#### Added AudioParameterManager Methods:

**Macro Range Updates** (for advanced editor):
```swift
updateToneToModulationIndexRange(_ value: Double)
updateToneToFilterCutoffOctaves(_ value: Double)
updateToneToFilterSaturationRange(_ value: Double)
updateAmbienceToDelayFeedbackRange(_ value: Double)
updateAmbienceToDelayMixRange(_ value: Double)
updateAmbienceToReverbFeedbackRange(_ value: Double)
updateAmbienceToReverbMixRange(_ value: Double)
updateMacroControlParameters(_ parameters: MacroControlParameters)
```

**Macro Position Updates** (for main UI):
```swift
updateVolumeMacro(_ position: Double)          // 0.0 to 1.0
updateToneMacro(_ position: Double)            // -1.0 to +1.0
updateAmbienceMacro(_ position: Double)        // -1.0 to +1.0
```

**Base Value Management**:
```swift
captureBaseValues()  // Captures current parameters as base values
```

**Private Helper Methods**:
```swift
applyToneMacro()              // Applies tone changes to parameters
applyAmbienceMacro()          // Applies ambience changes to parameters
applyOscillatorToAllVoices()  // Propagates oscillator changes
applyFilterToAllVoices()      // Propagates filter changes
```

#### Updated Preset Methods:
- `loadPreset()` now also loads `macroState`
- `createPreset()` now also saves `macroState`

### 2. V4-S11 ParameterPage11View.swift (MacroView)

**Replaced placeholder UI with functional controls:**
- 7 `SliderRow` controls for adjusting macro ranges
- Connected to `AudioParameterManager.shared`
- Proper labels and formatting:
  - Tone to Mod Index: ±0-5
  - Tone to Cutoff: ±0-4 octaves
  - Tone to Saturation: ±0-2
  - Ambience to Delay FB: ±0-1
  - Ambience to Delay Mix: ±0-1
  - Ambience to Reverb Size: ±0-1
  - Ambience to Reverb Mix: ±0-1

### 3. MacroControlsView.swift (New File)

**Created simple macro controls for main UI:**
- Three controls: Volume, Tone, Ambience
- Volume: 0-100% (absolute)
- Tone: -100% to +100% (bipolar, relative)
- Ambience: -100% to +100% (bipolar, relative)
- Uses custom `MacroControlRow` view
- Visual center mark for bipolar controls
- Ready to be imported into V3-S2 SoundView

### 4. MACRO_CONTROLS_GUIDE.md (New File)

**Comprehensive documentation including:**
- Architecture overview
- Data structure explanations
- Mathematical formulas for each macro
- Usage instructions
- Code examples
- Workflow descriptions
- Best practices
- Future enhancement ideas

### 5. MACRO_IMPLEMENTATION_SUMMARY.md (This File)

**Summary of all changes for quick reference**

## How the Macros Work

### Volume Macro
- **Direct mapping**: Position (0-1) → preVolume
- **Simple**: No base values needed
- **Use case**: Quick volume adjustment before effects

### Tone Macro
- **Affects 3 parameters**:
  1. **Modulation Index**: Linear offset from base
     - Formula: `base + (position × range)`
  2. **Filter Cutoff**: Logarithmic/octave scaling
     - Formula: `base × 2^(position × octaves)`
  3. **Filter Saturation**: Linear offset from base
     - Formula: `base + (position × range)`
- **Bipolar**: -1 to +1 (0 = neutral/base value)
- **Use case**: Brightness and harmonics control

### Ambience Macro
- **Affects 4 parameters**:
  1. **Delay Feedback**: Linear offset
  2. **Delay Mix**: Linear offset
  3. **Reverb Feedback** (Size): Linear offset
  4. **Reverb Mix**: Linear offset
- **Bipolar**: -1 to +1 (0 = neutral/base value)
- **Formula for all**: `base + (position × range)`
- **Use case**: Spatial depth and wetness control

## Integration Steps

### Step 1: Update V3-S2 SoundView
Add the macro controls to your main sound view:

```swift
import SwiftUI

struct SoundView: View {
    var body: some View {
        VStack {
            // Existing preset selector
            PresetSelectorView()  // Your existing component
            
            // NEW: Add macro controls
            MacroControlsView()
                .padding()
            
            // Rest of your UI
        }
    }
}
```

### Step 2: Capture Base Values on Preset Load
Wherever you load presets, add this call:

```swift
// Load the preset
AudioParameterManager.shared.loadPreset(selectedPreset)

// NEW: Capture base values for macro controls
AudioParameterManager.shared.captureBaseValues()
```

### Step 3: (Optional) Capture Base Values on Manual Edits
If you want macros to work relative to manual parameter changes:

```swift
// After user edits parameters in advanced editor
AudioParameterManager.shared.captureBaseValues()
```

This resets macro positions and uses new values as base.

### Step 4: Test
1. Load a preset
2. Verify macros are at neutral (0)
3. Move Tone slider up → should brighten sound
4. Move Ambience slider up → should add reverb/delay
5. Move Volume slider → should control volume directly

## Dependencies

The implementation relies on existing components:
- `SliderRow` - Used in MacroView (already exists)
- `voicePool` - Global voice pool instance (already exists)
- Color assets: `BackgroundColour`, `HighlightColour` (already exist)
- Font helper: `.adaptiveFont()` (already exists)

All these are assumed to be already implemented based on the existing codebase structure.

## Testing Checklist

- [ ] Macro ranges adjust properly in advanced editor (V4-S11)
- [ ] Volume macro controls preVolume directly
- [ ] Tone macro affects modulation index, cutoff, and saturation together
- [ ] Ambience macro affects delay and reverb together
- [ ] Base values capture correctly on preset load
- [ ] Macro positions reset to 0 when capturing base values
- [ ] Parameters update in real-time as macros are adjusted
- [ ] Preset saving includes macro state
- [ ] Preset loading restores macro state
- [ ] Direct parameter edits in advanced editor still work
- [ ] UI displays macro values correctly (percentages)
- [ ] Bipolar controls show center mark visually

## Potential Issues to Watch For

1. **Missing voicePool reference**: Ensure `voicePool` is a global variable accessible from the parameter manager
2. **Missing fxDelay/fxReverb references**: Ensure these are accessible for ambience macro
3. **UI components not found**: Ensure `SliderRow` and custom view helpers exist
4. **Color assets**: Ensure color names match your asset catalog

## Next Steps

1. ✅ Implement data structures
2. ✅ Add AudioParameterManager methods
3. ✅ Update MacroView (advanced editor)
4. ✅ Create MacroControlsView (main UI)
5. ✅ Write documentation
6. ⏳ Integrate MacroControlsView into V3-S2 SoundView
7. ⏳ Test all functionality
8. ⏳ Add preset management with macro state
9. ⏳ Consider MIDI mapping for macros (future)

## Questions for Review

1. **Should volume macro be 0-1 or also bipolar?**
   - Currently: 0-1 (absolute)
   - Alternative: Could be bipolar relative to base preVolume
   - Decision: Keeping it absolute seems more intuitive

2. **Should we auto-capture base values after advanced edits?**
   - Pro: Macros always work relative to current state
   - Con: Might surprise users if macro positions reset
   - Decision: Leave it optional, document the pattern

3. **Should macro ranges have different defaults per preset?**
   - Currently: Global defaults for all presets
   - Alternative: Each preset could have custom ranges
   - Decision: Current approach is simpler, can enhance later

4. **Filter cutoff octave calculation - correct?**
   - Using: `base × 2^(position × octaves)`
   - This gives equal musical intervals
   - Seems correct for pitch/frequency-based parameters

5. **Need to check these exist in your codebase:**
   - Global `voicePool` variable
   - Global `fxDelay` and `fxReverb` references
   - `SliderRow` custom component
   - Color assets: "BackgroundColour", "HighlightColour"
