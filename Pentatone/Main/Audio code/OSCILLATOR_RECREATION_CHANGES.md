# Oscillator Recreation Implementation

## Summary
Implemented a more targeted approach to waveform changes that recreates only the oscillators instead of entire voices. This should help resolve the "missing voice" issue that occurred after using the `recreateVoices()` function.

## Changes Made

### 1. PolyphonicVoice.swift - Made Audio Nodes Mutable
**Changed** `let` to `var` for audio nodes that need to be recreated:
- `oscLeft: FMOscillator` (was `let`, now `var`)
- `oscRight: FMOscillator` (was `let`, now `var`)
- `panLeft: Panner` (was `let`, now `var`)
- `panRight: Panner` (was `let`, now `var`)

**Kept immutable:**
- `stereoMixer: Mixer` - doesn't need recreation
- `filter: KorgLowPassFilter` - doesn't need recreation
- `envelope: AmplitudeEnvelope` - doesn't need recreation

### 2. PolyphonicVoice.swift - New Method: `recreateOscillators(waveform:)`
**Added a new method** that recreates only the oscillators while preserving the rest of the voice:

```swift
func recreateOscillators(waveform: WaveformType)
```

**What it does:**
1. Stores current oscillator state (frequency, amplitude, multipliers, etc.)
2. Stops and disconnects old oscillators
3. Disconnects old panners from stereo mixer
4. Creates new oscillators with the new waveform
5. Creates new panners with the new oscillators
6. Connects new panners to the existing stereo mixer
7. Updates internal references
8. Restarts oscillators if the voice was initialized
9. Applies stored state to new oscillators

**Key advantages:**
- Keeps filter, envelope, and mixer intact
- Preserves voice pool connections
- Maintains voice availability state
- Less complex than full voice recreation

### 3. VoicePool.swift - New Method: `recreateOscillators(waveform:completion:)`
**Added a new method** to the voice pool:

```swift
func recreateOscillators(waveform: WaveformType, completion: @escaping () -> Void)
```

**What it does:**
1. Stops all playing notes (prevents audio glitches)
2. Iterates through all voices and calls `voice.recreateOscillators(waveform:)`
3. Calls completion handler when done

**Old method `recreateVoices` is still available** but marked as deprecated in comments for full voice recreation if ever needed for other parameter changes.

### 4. ParameterPage1View.swift - Updated Waveform Picker
**Changed the waveform parameter binding** to use the new method:

**Before:**
```swift
voicePool.recreateVoices(with: paramManager.voiceTemplate) {
    print("🎹 Voices recreated with waveform: \(newValue.displayName)")
}
```

**After:**
```swift
voicePool.recreateOscillators(waveform: newValue) {
    print("🎹 Oscillators recreated with waveform: \(newValue.displayName)")
}
```

## Expected Behavior

### Before (with recreateVoices):
- Created entirely new voice objects
- Disconnected old voices from mixer
- Connected new voices to mixer
- Potential for connection issues causing missing voices

### After (with recreateOscillators):
- Voice objects remain the same
- Only oscillators and panners are recreated
- Mixer connections are preserved (just input nodes change)
- Should be more stable and less prone to connection issues

## Testing Recommendations

1. **Test waveform switching:** Change the waveform multiple times and verify all 5 voices continue to work
2. **Test during playback:** Try changing waveform while notes are playing (should stop cleanly)
3. **Test voice allocation:** After waveform change, play all 5 voices and verify they all produce sound
4. **Test voice stealing:** Play 6+ notes after waveform change to verify voice stealing still works
5. **Monitor console:** Watch for the debug print statements to verify the process completes

## Debug Output
The new implementation includes detailed logging:
- `🎵 Starting oscillator recreation with waveform: [name]...`
- `🎵   Voice [N]: oscillators recreated`
- `🎵   Oscillators recreated and restarted` (if voice was initialized)
- `🎵 ✅ Oscillator recreation complete - [N] voices ready`

## Rollback Plan
If this approach doesn't solve the issue, you can revert to the old method by:
1. Changing the call in ParameterPage1View back to `voicePool.recreateVoices(with: ...)`
2. The old method is still available in VoicePool.swift

## Notes
- The stereo mixer, filter, and envelope remain completely untouched during oscillator recreation
- All oscillator state (frequency, amplitude, FM parameters) is preserved and restored
- The voice pool's connection structure is preserved
- Voice availability states are maintained through the process
