//
//  Development roadmap.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 14/12/2025.
//

/*

MAIN
 √ Fix iOS 15 compatibility
 √ Add oscillator waveform to parameters
 √ add initial touch and aftertouch sensitivity
 √ switch over to limited polyphony + voice management (round robin)
 √ switch over to stereo architecture
 √ try different filters
 √ implement modulation generators
 √ implement modulators in parameter structure
 √ implement fine tune and octave adjustments
 - create preset management
 - create developer view for sound editing/storing presets
 - add macro control
 >> sanity check code structure
 - add drone note toggles to central note buttons?
 (- port engine to tonehive)
 - add in app documentation
 >> ready for launch of version 1 (free app only)
 - implement MIDI output
 - implement Preset management/sound editing features made public as upgrade
 - implement AUv3 compatibility
 - implement IAP structure
 >> ready for launch of version 2 (free app with IAP)
 
 
 
 
UI
 √ ET / JI: display as EQUAL / JUST
 √ Improve spacing/layout
 √ Implement scale type graphics display (raw shapes or image files?)
 √ Implement note name display
 - Implement basic tooltip structure (toggle on/of in voice menu?)
 
CHECKLIST FOR LATER TROUBLESHOOTING/IMPROVEMENTS
 - distinguish between iPad landscape and iPad portrait for font sizes? (apparently tricky, couldn't get to work on first try - also, looking quite good already anyway)
 - accidentals don't resize properly in key display on iPhone (but they do in scale note display)
 - Voice LFO to basefrequency seems overly smoothed, remove ramping?
 - Global LFO not working on filter?
 - Improve fullscreen / swipe gesture handling?
 - Check AudioKit console warnings on startup
 - Check multiple console messages of scale frequency updates
 - Check AudioKit warning message streams when modulation is enabled (already fixed for aftertouch)
 
 
 CONCEPT FOR IMPROVED SOUND ENGINE:
 
 √ There will be a polyphonic synth engine with some number of voices (5 would be a good start, this should be adjustable).
 √ Instead of a 1 on 1 connection between keys and voices, there will be a dynamic voice allocation system with a simple round robin voice assignment system
 √ The frequency of each voice will be updated each time it is triggered, dependant on the key that triggers it.
 √ Each voice will get a second oscillator and a more sophisticated internal structure
 √ In addition to the editable parameters, we will create dedicated modulators (LFOs, modulation envelopes), that will be able to update these parameters in realtime (at control rate, not at audio rate)
 - We will create a 'developer view' allowing the creation of different presets (values for all audio and modulator parameters)
 - The final app will contain 15 different presets that should be browsable
 - We will also be creating a macro structure: while the final app will not allow the user to individually sculpt each parameter, there will be 4 macro sliders that map to one or more parameters, this will vary per preset.
 
 
 IDEAS FOR PRESETS
 
 1 - ACOUSTIC PERCUSSIVE
 1.1  Keys (Wurlitzer-esque sound)
 1.2  Mallets (Marimba-esque sound)
 1.3  Sticks (Glockenspiel-esque sound)
 1.4  Pluck (Harp-esque sound)
 1.5  Pick (Koto-esque sound)
 
 2 - ACOUSTIC SUSTAINED
 2.1  Bow (Cello-esque sound)
 2.2  Breath (Low whistle-esque sound)
 2.3
 2.4
 2.5
 
 3 - ELECTRIC
 3.1  Slide (Pedal steel-esque sound)
 3.2  Rotary (Rock Organ-esque sound)
 3.3  Voodoo (Lead guitar-esque sound)
 3.4  Lev (Theremin-esque sound)
 3.5
 
 4 - SYNTH
 4.1  Transistor (Analog polysynth-esque sound)
 4.2  Chip (Square Lead-esque sound)
 4.3  ... (Analog bass-esque sound)
 4.4
 4.5
 
 5 - AMBIENT
 5.1  Ocean (deep, swirly sound)
 5.1  Forest (lively, organic sound)
 5.2  Field (warm, airy sound)
 5.3  Nebula (cool, ethereal sound)
 5.4  Haze (Granular-esque sound)
 
 
 KEY TRANSPOSITION
 
 Key    ET pitch factor     JI pitch factor
 Ab     -6 semitones        * 
 Eb     +1 semitones        * 256/243
 Bb     -4 semitones        * 64/81
 F      +3 semitones        * 32/27
 C      -2 semitones        * 8/9
 G      +5 semitones        * 4/3
 D       0 semitones        * 1
 A      -5 semitones        * 3/4
 E      +2 semitones        * 9/8
 B      -3 semitones        * 27/32
 F#     +4 semitones        * 81/64
 C#     -1 semitones        * 243/256
 G#     +6 semitones        * 729/512
 
 
 DOCUMENTATION
 
 Add tooltips to following UI elements
 
 1. Optionsview (shared)
 1.2        Scale/Sound/Voice
 1.10/11    Note display area
 
 2. Scale view
 2.3        JI/ET
 2.4/5      Scale display area
 2.6        Key
 2.7        Celestial orientation
 2.8        Terrestrial orientation
 2.9        Keyboard rotation
 
 3. Sound view
 3.3        Preset selector
 3.4        Empty area
 3.5        Volume slider
 3.6        Tone slider
 3.7        Sustain slider
 3.8        Modulation slider
 3.9        Ambience slider
 
 4. Voice view
 4.3        Tips
 4.4/5/6    Pentatone logo area
 4.7        Voice mode
 4.8        Octave
 4.9        Fine tune
 
 Add 'More details' section with:
 - what is a pentatonic scale?
 - basic scale construction
 - JI vs ET
 - The advantages of pentatonics
 - Some examples (Western Pentatonic major/Minor, Ethiopian, African, Japanese)
 - Diagrams ET, JI ratios, JI names
 
 
 
 IDEAS FOR IN APP PURCHASES (FOR FUTURE VERSIONS OF APP)
 - Sound design: unlock 'developer view' with full access to all sound parameters plus option to create and store presets
 - Midi out: add midi output functionality, optimally in 4 versions:
    1) Standard >> polyphonic ET, compatible with any midi synthesizers (single selectable midi channel)
    2) Pitch bend JI >> works monophonically with any midi synthesizers (single selectable midi channel)
    3) MPE JI >> works polyphonically with MPE-capable synthesizers (multi channel)
    4) JI through .scala/.tun >> works polyphonically with synthesizers that support .tun/.scala (single selectable midi channel)
 - DAW integration: AUv3 for Garageband, Ableton link functionality
 - Pro package consisting of all three updgrades (sound editor, midi out, DAW integration)
 Pricing idea: around €3 each for single IAPs, or €6 for all three (pro package)
 
 
 
 CONCEPT FOR FINAL STRUCTURE OF EDITABLE PARAMETERS / SOUND EDITING SCREENS
 
 
 1. VOICE √
 
 a) Oscillator (the same parameter values will be applied to both the left-panned and right-panned FMOscillators
 - Waveform (shared between Carrier and Modulator, options: sine, triangle, square)
 - Carrier multiplier (=>carrierMultiplier)
 - Modulator multiplier coarse (=>modulatingMultiplier, integer values)
 - Modulator multiplier fine (=> modulatingMultiplier, .00 - .99)
 - Modulator base level (=> modulationIndex)
 - Amplitude (=>amplitude)
 
 b) Stereo spread
 - Offset mode (absolute vs relative)
 - Offset amount
 
 c) Filter
 - Cutoff
 - Resonance
 - Saturation
 
 d) AmplitudeEnvelope
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 
 
 2. FX CHAIN √
 
 a) Delay
 - Delay time (implement as sync to master tempo?)
 - Delay feedback
 - Delay PingPong
 - Delay mix
 
 b) Reverb
 - Reverb size
 - Reverb tone
 - Reverb mix
 
 
 3. MASTER √
 
 - Tempo
 - Voice mode (polyphonic/monophonic)
 - Root frequency
 - Octave
 - Fine tune
 - Master volume (pre or post fx? For pre fx, could be mapped to voicemixer volume)
 
 
 4. MODULATION
 
 a) Modulator envelope (should exist per-voice, destination is 'hard wired' to oscillators' modulationIndex)
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 - Envelope amount (=> modulationIndex + Modulation envelope value * envelope amount)
 
 b) Auxiliary Envelope (should exist per-voice)
 - Attack time
 - Decay time
 - Sustain level
 - Release time
 - destination (Oscillator baseFrequency, modulatingMultiplier, Filter frequency [default], Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)

 c) Voice LFO (should exist per-voice)
 - waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 - reset mode (free, trigger, sync)
 - frequency (0-10 Hz or tempo multipliers depending on mode)
 - destination (Oscillator baseFrequency [default], modulationIndex, modulatingMultiplier, Filter frequency, stereo spread offset amount)
 - amount (bipolar modulation, so only positive amounts)

 d) Global LFO (should exist as a single LFO on global level
 - waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 - reset mode (free, sync)
 - frequency (0-10 Hz or tempo multipliers depending on mode)
 - destination (Oscillator amplitude [default], Oscillator baseFrequency, modulationIndex, modulatingMultiplier, Filter frequency, delay time, delay amount)
 - amount (bipolar modulation, so only positive amounts)
 
 e) Key tracking (value proportional to frequency of triggered key)
  - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
  - amount (unipolar modulation, so positive and negative amount)

 e) X initial touch (x position of key trigger touch)
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)
 
 f) X aftertouch (change in x position of touch while key is being held)
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (bipolar modulation, so only positive amounts)
 ? toggle for relative/absolute mode
 
 
 
 >>> the modulation sources below, y touch sensitivity and touchArea detection will not be implemented in this particular app, but it would be good to add them to the synth engine for purposes of portability / reusability)
 
 g) Y initial touch (y position of key trigger touch)
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)
 
 h) Y aftertouch (change in y position of touch while key is being held)
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (bipolar modulation, so only positive amounts)
 ? toggle for relative/absolute mode
 
 i) Velocity sensitivity through 'touchArea' detection
 - destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 - amount (unipolar modulation, so positive and negative amount)

 
 
 PARAMETER PAGE VIEWS
 
 √ PAGE 1 - VOICE OSCILLATORS
 1) Oscillator Waveform. LIST. Values: sine, triangle, square
 2) Carrier multiplier. SLIDER. Values: integers only, range 1-16
 3) Modulator multiplier coarse. SLIDER. Values: integers only, range 1-16
 4) Modulator multiplier fine. SLIDER. Values: 0-1 continuous
 5) Modulator base level. SLIDER. Values: 0-1 continuous
 6) Stereo offset mode. LIST. Values: constant, proportional
 7) Stereo offset amount. SLIDER. Values: 0-4 continuous for constant offset mode, 1.0000-1.0100 continuous for proportional offset mode
 
 √ PAGE 2 - VOICE CONTOUR
 1) Amp Envelope Attack time. SLIDER. Values: 0-5 continuous
 2) Amp Envelope Decay time. SLIDER. Values: 0-5 continuous
 3) Amp Envelope Sustain level. SLIDER. Values: 0-1 continuous
 4) Amp Envelope Release time. SLIDER. Values: 0-5 continuous
 5) Lowpass Filter Cutoff frequency. SLIDER. Values: 20 - 20000 continuous << needs logarithmic scaling
 6) Lowpass Filter Resonance. SLIDER. Values: 0-2 continuous
 7) Lowpass Filter Saturation. SLIDER. Values: 0-10 continuous

 √ PAGE 3 - EFFECTS
 1) Delay time. LIST. Values: 1/32, 1/24, 1/16, 3/32, 1/8, 3/16, 1/4
 2) Delay feedback. SLIDER. Values: 0-1 continuous
 3) Delay PingPong
 4) Delay mix. SLIDER. Values: 0-1 continuous
 5) Reverb size. SLIDER. Values: 0-1 continuous
 6) Reverb tone. SLIDER. Values: 0-1 continuous
 7) Reverb mix. SLIDER. Values: 0-1 continuous
 
 √ PAGE 4 - GLOBAL
 1) Tempo. SLIDER. Values: 30-240, integers only
 2) Polyphony. SLIDER. Values: 1-12, integers only
 3) Root frequency. SLIDER. Values: 98-220 continuous
 4) Root octave. LIST. Values: -2,-1,0,1,2
 5) Fine tune. SLIDER. Values: 98-220 continuous
 6) Pre volume (voice mixer volume). SLIDER. Values: 0-1 continuous
 7) Post volume (output mixer volume). SLIDER. Values: 0-1 continuous
  
 PAGE 5 - MODULATOR ENVELOPE  + KEYBOARD TRACKING
 1) Mod Envelope Attack time. SLIDER. Values: 0-5 continuous
 2) Mod Envelope Decay time. SLIDER. Values: 0-5 continuous
 3) Mod Envelope Sustain level. SLIDER. Values: 0-1 continuous
 4) Mod Envelope Release time. SLIDER. Values: 0-5 continuous
 5) Mod Envelope amount (=> modulationIndex + Modulation envelope value * envelope amount)
 6) Key tracking destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 7) Key tracking amount (unipolar modulation, so positive and negative amount)
 
 PAGE 6 - AUXILIARY ENVELOPE
 1) Aux envelope Attack time. SLIDER. Values: 0-5 continuous
 2) Aux envelope Decay time. SLIDER. Values: 0-5 continuous
 3) Aux envelope Sustain level. SLIDER. Values: 0-1 continuous
 4) Aux envelope Release time. SLIDER. Values: 0-5 continuous
 5) Aux envelope destination (Oscillator baseFrequency, modulatingMultiplier, Filter frequency [default], Voice LFO frequency, Voice LFO mod amount)
 6) Aux envelope amount (unipolar modulation, so positive and negative amount)

 PAGE 7 - VOICE LFO
 1) Voice LFO waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 2) Voice LFO reset mode (free, trigger, sync)
 3) Voice LFO frequency (0-10 Hz or tempo multipliers depending on mode)
 4) Voice LFO destination (Oscillator baseFrequency [default], modulationIndex, modulatingMultiplier, Filter frequency, stereo spread offset amount)
 5) Voice LFO amount (bipolar modulation, so only positive amounts)

 PAGE 8 - GLOBAL LFO
 1) Global LFO waveform (sine, triangle, square, sawtooth, reversed sawtooth)
 2) Global LFO reset mode (free, sync)
 3) Global LFO frequency (0-10 Hz or tempo multipliers depending on mode)
 4) Global LFO destination (Oscillator amplitude [default], Oscillator baseFrequency, modulationIndex, modulatingMultiplier, Filter frequency, delay time, delay amount)
 5) Global LFO amount (bipolar modulation, so only positive amounts)
 
 PAGE 9 - TOUCH RESPONSE
 1) Initial touch destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 2) Initial touch amount (unipolar modulation, so positive and negative amount)
 3) Aftertouch mode (relative/absolute)
 4) Aftertouch scaling (linear/logarithmic)
 5) Aftertouch destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
 6) Aftertouch amount (bipolar modulation, so only positive amounts)

 PAGE 10 - PRESETS
 - Select and store presets
 
 PAGE 11 - TONE MACRO
 1) ModulationIndex minimum
 2) ModulationIndex maximum
 3) Filter frequency minimum
 4) Filter frequency maximum
 5) Filter saturation minimum
 6) Filter saturation maximum
 
 PAGE 12 - AMBIENCE MACRO
 1) Delay feedback minimum
 2) Delay feedback maximum
 3) Delay Mix minimum
 4) Delay Mix maximum
 5) Reverb mix minimum
 6) Reverb mix maximum
  
 */
