//
//  MACRO_CONTROLS_GUIDE.md
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//

# Macro Controls Implementation Guide

## Overview

The macro control system provides simplified controls for users while maintaining full parameter editing capabilities in the advanced editor. Three macro controls are provided:

1. **Volume** - Direct control of pre-FX volume
2. **Tone** - Affects modulation index, filter cutoff, and filter saturation
3. **Ambience** - Affects delay and reverb parameters

## Architecture

### Data Structures

#### `MacroControlParameters`
Defines the **ranges** for each macro's effect on underlying parameters. These are adjustable in the advanced editor (V4-S11 ParameterPage11View).

- `toneToModulationIndexRange`: ±0-5 (default: 2.5)
- `toneToFilterCutoffOctaves`: ±0-4 octaves (default: 2.0)
- `toneToFilterSaturationRange`: ±0-2 (default: 1.0)
- `ambienceToDelayFeedbackRange`: ±0-1 (default: 0.5)
- `ambienceToDelayMixRange`: ±0-1 (default: 0.5)
- `ambienceToReverbFeedbackRange`: ±0-1 (default: 0.5)
- `ambienceToReverbMixRange`: ±0-1 (default: 0.5)

#### `MacroControlState`
Stores the current state of macro controls and base parameter values.

**Base Values** (captured when preset loads or parameters change):
- `baseModulationIndex`
- `baseFilterCutoff`
- `baseFilterSaturation`
- `baseDelayFeedback`
- `baseDelayMix`
- `baseReverbFeedback`
- `baseReverbMix`
- `basePreVolume`

**Macro Positions**:
- `volumePosition`: 0.0 to 1.0 (absolute)
- `tonePosition`: -1.0 to +1.0 (relative, 0 = neutral)
- `ambiencePosition`: -1.0 to +1.0 (relative, 0 = neutral)

### How It Works

#### Volume Macro
**Simple and direct**: Maps directly to `preVolume` parameter.
- Range: 0.0 to 1.0 (absolute)
- No base value needed
- Directly controls voice mixer volume before FX

#### Tone Macro
**Bipolar control** affecting multiple parameters:
- **Modulation Index**: `base + (position × range)`
  - At position 0: uses base value
  - At position +1: base + full range
  - At position -1: base - full range
  
- **Filter Cutoff**: `base × 2^(position × octaves)`
  - Logarithmic scaling for musical octave response
  - At position 0: uses base frequency
  - At position +1: base × 2^octaves (e.g., 2 octaves = 4× frequency)
  - At position -1: base × 2^-octaves (e.g., -2 octaves = 0.25× frequency)
  
- **Filter Saturation**: `base + (position × range)`
  - Linear scaling like modulation index

#### Ambience Macro
**Bipolar control** affecting delay and reverb:
- **Delay Feedback**: `base + (position × range)`
- **Delay Mix**: `base + (position × range)`
- **Reverb Feedback**: `base + (position × range)`
- **Reverb Mix**: `base + (position × range)`

All follow the same pattern as modulation index (linear offset from base).

## Usage

### For the Main UI (V3-S2 SoundView)

Add the `MacroControlsView` to your view:

```swift
import SwiftUI

struct SoundView: View {
    var body: some View {
        VStack {
            // Your existing preset selector here
            
            // Add macro controls
            MacroControlsView()
                .padding()
            
            // Rest of your UI
        }
    }
}
```

### For the Advanced Editor (V4-S11 ParameterPage11View)

Already implemented! The `MacroView` provides controls for adjusting the ranges.

### Capturing Base Values

**Important**: When loading a preset or when the user directly edits parameters in the advanced editor, you should capture the current values as base values:

```swift
// After loading a preset
AudioParameterManager.shared.loadPreset(preset)
AudioParameterManager.shared.captureBaseValues()

// OR when user manually edits parameters
// You can call this after any direct parameter edit
AudioParameterManager.shared.captureBaseValues()
```

This ensures that the macro controls start from the current parameter state.

### Workflow

1. **Load Preset**: App loads a preset with specific parameter values
2. **Capture Base Values**: `captureBaseValues()` stores these as the starting point
3. **Reset Macro Positions**: All macros reset to 0 (neutral/center)
4. **User Adjusts Macros**: Moving sliders adjusts parameters relative to base values
5. **User Edits Advanced**: If user tweaks parameters directly, call `captureBaseValues()` again

## Implementation Details

### AudioParameterManager Methods

**Macro Range Updates** (for advanced editor):
- `updateToneToModulationIndexRange(_ value: Double)`
- `updateToneToFilterCutoffOctaves(_ value: Double)`
- `updateToneToFilterSaturationRange(_ value: Double)`
- `updateAmbienceToDelayFeedbackRange(_ value: Double)`
- `updateAmbienceToDelayMixRange(_ value: Double)`
- `updateAmbienceToReverbFeedbackRange(_ value: Double)`
- `updateAmbienceToReverbMixRange(_ value: Double)`

**Macro Position Updates** (for main UI):
- `updateVolumeMacro(_ position: Double)` - Position: 0.0 to 1.0
- `updateToneMacro(_ position: Double)` - Position: -1.0 to +1.0
- `updateAmbienceMacro(_ position: Double)` - Position: -1.0 to +1.0

**Base Value Management**:
- `captureBaseValues()` - Captures current parameters as base values and resets macro positions

### Private Methods (Internal Use)

- `applyToneMacro()` - Calculates and applies tone effects to parameters
- `applyAmbienceMacro()` - Calculates and applies ambience effects to parameters
- `applyOscillatorToAllVoices()` - Propagates oscillator changes to voice pool
- `applyFilterToAllVoices()` - Propagates filter changes to voice pool

## Example Scenarios

### Scenario 1: User Loads Preset "Bright Pad"
```
1. Preset has:
   - Modulation Index: 3.0
   - Filter Cutoff: 2400 Hz
   - Filter Saturation: 1.5
   
2. captureBaseValues() sets:
   - baseModulationIndex: 3.0
   - baseFilterCutoff: 2400
   - baseFilterSaturation: 1.5
   - All positions reset to 0
   
3. User moves Tone to +0.5 (50%):
   - New Mod Index: 3.0 + (0.5 × 2.5) = 4.25
   - New Cutoff: 2400 × 2^(0.5 × 2.0) = 2400 × 2 = 4800 Hz
   - New Saturation: 1.5 + (0.5 × 1.0) = 2.0
```

### Scenario 2: User Tweaks in Advanced Editor
```
1. User manually changes Filter Cutoff to 800 Hz
2. App calls captureBaseValues()
3. baseFilterCutoff is now 800 Hz
4. Tone macro position resets to 0
5. User can now use Tone macro relative to new 800 Hz base
```

## Best Practices

1. **Always call `captureBaseValues()` after loading a preset**
2. **Consider calling it after user edits in advanced editor** (optional but recommended)
3. **Don't mix direct parameter changes with macro changes** - decide on one approach per user action
4. **Volume macro can be updated frequently** without affecting base values (it's absolute)
5. **Tone and Ambience are relative** - they always work from the captured base values

## Future Enhancements

Potential improvements:
- Add visual feedback showing which parameters are affected by each macro
- Add "reset to base" buttons for individual macros
- Allow users to customize which parameters are affected by each macro
- Add presets for macro range configurations
- Add MIDI CC mapping for macro controls
- Add automation recording for macro movements

