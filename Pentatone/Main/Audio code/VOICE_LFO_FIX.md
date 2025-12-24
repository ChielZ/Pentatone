# Voice LFO Not Working - Fix Applied

## Problem
Voice LFO parameters were configured in `A01 SoundParameters.swift` but had no audible effect, even though Global LFO was working correctly.

## Root Cause
The Voice LFO parameters were being set at voice creation time, but were never updated after that. Here's what was happening:

1. **VoicePool initialization** (in `A03 VoicePool.swift` line 63):
   ```swift
   let voiceParams = VoiceParameters.default  // Captures default at init time
   for _ in 0..<self.voiceCount {
       let voice = PolyphonicVoice(parameters: voiceParams)
       voices.append(voice)
   }
   ```

2. **Engine startup** (in `A05 AudioEngine.swift`):
   ```swift
   voicePool = VoicePool(voiceCount: 5)
   voicePool.updateGlobalLFO(masterParams.globalLFO)  // ✅ Global LFO updated
   // ❌ Voice modulation parameters NEVER updated
   ```

The Global LFO worked because it was explicitly updated with `updateGlobalLFO()`, but the Voice LFO was stuck with whatever defaults existed when the VoicePool class was compiled.

## Solution Applied

Added a call to `updateAllVoiceModulation()` in the engine startup sequence:

**File:** `A05 AudioEngine.swift`  
**Location:** Inside `EngineManager.startIfNeeded()`, after VoicePool creation

```swift
// Get default parameters from parameter manager
let masterParams = MasterParameters.default
let voiceParams = VoiceParameters.default  // NEW: Get voice params

// Create voice pool (5 polyphonic voices)
voicePool = VoicePool(voiceCount: 5)

// Apply global LFO parameters from master defaults
voicePool.updateGlobalLFO(masterParams.globalLFO)

// NEW: Apply voice modulation parameters to all voices
voicePool.updateAllVoiceModulation(voiceParams.modulation)
```

## What This Does

- When the audio engine starts, it now reads `VoiceParameters.default` from `A01 SoundParameters.swift`
- It extracts the `modulation` parameters (which include your Voice LFO settings)
- It calls `voicePool.updateAllVoiceModulation()` to apply those settings to all 5 voices
- Each voice's `voiceModulation` property is updated with your LFO configuration

## Testing
After this fix, the Voice LFO should now work correctly:

1. **Build and run** the app (⌘R)
2. **Play any key** - you should hear the Voice LFO effect
3. **Change Voice LFO settings** in `A01 SoundParameters.swift` (line ~131)
4. **Rebuild** - the new settings will be applied

## Example Configuration to Test

In `A01 SoundParameters.swift` around line 131, try this:

```swift
voiceLFO: LFOParameters(
    waveform: .sine,
    resetMode: .free,
    frequencyMode: .hertz,
    frequency: 5.0,                     // Fast wobble
    destination: .filterCutoff,         // Very audible
    amount: 0.7,                        // Strong effect
    isEnabled: true
),
```

You should hear a clear 5 Hz filter wobble on every note.

## Why Global LFO Worked But Voice LFO Didn't

- **Global LFO** is stored in `VoicePool` as a single property, and was explicitly updated via `updateGlobalLFO()`
- **Voice LFO** is stored in each `PolyphonicVoice`, and was never updated after initialization
- This was an oversight in the integration of Phase 5C - the plumbing was there, but the connection wasn't made

## Files Modified
- `A05 AudioEngine.swift` - Added `voicePool.updateAllVoiceModulation(voiceParams.modulation)` call

## Related
- Voice LFO configuration: `A01 SoundParameters.swift` line ~131
- Global LFO configuration: `A01 SoundParameters.swift` line ~184
- LFO parameter guide: `LFO_PARAMETER_GUIDE.md`
