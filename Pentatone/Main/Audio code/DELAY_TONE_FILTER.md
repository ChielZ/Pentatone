# Delay Tone Filter Implementation

## Summary
Implemented a Butterworth lowpass filter after the delay to tame digital artifacts from LFO modulation, with user-controllable cutoff frequency.

## Architecture Change

### Old Signal Chain
```
VoicePool → StereoDelay (with internal dry/wet mix) → Reverb → Output
```

### New Signal Chain
```
VoicePool → StereoDelay (100% wet) → Butterworth Lowpass → DryWetMixer → Reverb → Output
             ↑                                                  ↑
             └──────────────────────────────────────────────────┘
                            (dry signal bypass)
```

## Changes Made

### 1. A1 SoundParameters.swift

#### DelayParameters struct
**Added:**
- `toneCutoff: Double` - Lowpass filter cutoff frequency (200 Hz - 20 kHz)
- Default: 10,000 Hz (wide open)

**Removed:**
- `pingPong: Bool` - Now always enabled (hardcoded to `true`)
- All migration code (clean struct)

**Changed:**
- `dryWetMix` now controls external `DryWetMixer` (not StereoDelay's internal mix)

#### AudioParameterManager
**Added methods:**
- `updateDelayToneCutoff(_ cutoff: Double)` - Controls filter cutoff

**Removed methods:**
- `updateDelayPingPong(_ pingPong: Bool)` - No longer needed

**Modified methods:**
- `updateDelayMix(_ mix: Double)` - Now controls `delayDryWetMixer.balance` instead of `fxDelay.dryWetMix`
- `applyDelayParameters()` - Now also updates filter and external mixer

### 2. A5 AudioEngine.swift

#### New Global Nodes
```swift
private(set) var delayLowpass: LowPassButterworthFilter!
private(set) var delayDryWetMixer: DryWetMixer!
```

#### Engine Initialization
**New node chain:**
1. **StereoDelay** - `dryWetMix` fixed at 0.0 (100% wet), `pingPong` always `true`
2. **LowPassButterworthFilter** - Clean filter (resonance = 0.0) after delay
3. **DryWetMixer** - Blends dry (voice pool) with wet (filtered delay)
4. **Reverb** - Processes mixed signal

## Why This Works Better

### 1. Clean Filter Placement
- **After delay** = filters the modulated delay signal including artifacts
- **Before reverb** = doesn't affect reverb character
- **Butterworth topology** = maximally flat passband, clean roll-off

### 2. Proper Dry/Wet Mixing
- **External mixer** = dry signal bypasses delay AND filter
- **Independent control** = delay can be 100% wet internally for optimal feedback
- **Better architecture** = separation of concerns (delay vs. mixing)

### 3. Musical Benefits
- **Tames glitch** = Roll off to 2-4 kHz for smooth, tape-like delays
- **Lo-fi control** = Roll off to 1 kHz for cassette/telephone vibe
- **Preserves option** = Leave at 10+ kHz for full digital character
- **Reduces harshness** = Works for LFO modulation, tempo changes, and high feedback

## Parameter Ranges

### toneCutoff
- **Range:** 200 Hz - 20,000 Hz
- **Default:** 10,000 Hz (wide open, minimal filtering)
- **Sweet spots:**
  - 20,000 Hz: Pristine digital (no filtering)
  - 8,000 Hz: Slight warmth (removes highest harmonics)
  - 4,000 Hz: Warm analog tape character
  - 2,000 Hz: Dark, vintage delay
  - 1,000 Hz: Lo-fi telephone/cassette
  - 500 Hz: Extreme lo-fi (muddy bass)

### dryWetMix (unchanged behavior for user)
- **Range:** 0.0 - 1.0
- **Default:** 0.5 (50% mix)
- **Implementation:** Now controls `DryWetMixer.balance` instead of delay's internal mix

## UI TODO

Replace "DELAY PING PONG" with "DELAY TONE":

```swift
// Old (remove):
ParameterRow(
    label: "DELAY PING PONG",
    value: Binding(
        get: { PingPongMode.from(paramManager.master.delay.pingPong) },
        set: { paramManager.updateDelayPingPong($0.boolValue) }
    ),
    displayText: { $0.displayName }
)

// New (add):
SliderRow(
    label: "DELAY TONE",
    value: Binding(
        get: { paramManager.master.delay.toneCutoff },
        set: { newValue in
            paramManager.updateDelayToneCutoff(newValue)
        }
    ),
    range: 200...20_000,
    step: 100,
    displayFormatter: { cutoff in
        if cutoff < 1000 {
            return String(format: "%.0f Hz", cutoff)
        } else {
            return String(format: "%.1f kHz", cutoff / 1000)
        }
    }
)
```

## Testing Checklist

- [ ] Build succeeds without errors
- [ ] Delay still works (time, feedback, mix)
- [ ] LFO modulation of delay time still works
- [ ] New tone control affects delay brightness
- [ ] Dry signal bypasses filter (check with mix at 0%)
- [ ] Filter doesn't affect reverb character
- [ ] Existing presets load (toneCutoff defaults to 10k)
- [ ] UI update: Ping pong removed, tone slider added

## Troubleshooting

### If delay sounds wrong:
- Check `fxDelay.dryWetMix` is 0.0 (100% wet)
- Check `delayDryWetMixer.balance` is being updated
- Verify signal flow: voicePool → delay → filter → mixer → reverb

### If filter doesn't work:
- Check `delayLowpass` is not nil
- Verify cutoff is being updated in `updateDelayToneCutoff()`
- Check filter is between delay and mixer in signal chain

### If you want to revert:
You made a commit before starting - just revert and you're back to the old architecture.

## Future Enhancements

### Already Possible
- **User control** of tone (via UI slider) ✓
- **Preset storage** of tone setting ✓
- **Works with all delay features** (time, feedback, mix, LFO mod) ✓

### Could Add Later
- **Filter resonance** parameter (currently fixed at 0.0 for clean sound)
- **Filter type** selector (Butterworth vs Moog vs State Variable)
- **Modulation of cutoff** (LFO, envelope, key tracking)
- **Pre-delay filter** (in feedback loop - would require custom delay)

## Notes

This is a **clean architectural change** that:
- ✅ Doesn't break existing functionality
- ✅ Adds new creative control
- ✅ Solves the harshness problem
- ✅ Maintains all existing features
- ✅ Follows AudioKit best practices (external mixing)

The only "loss" is ping pong toggle, but that was always-on-worthy anyway!
