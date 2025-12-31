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
 
 √ PAGE 1 - VOICE OSCILLATORS
 1) Oscillator Waveform
 2) Carrier multiplier
 3) Modulator multiplier coarse
 4) Modulator multiplier fine
 5) Modulator base level
 6) Stereo offset mode
 7) Stereo offset amount
 
 √ PAGE 2 - VOICE CONTOUR
 1) Amp Envelope Attack time
 2) Amp Envelope Decay time
 3) Amp Envelope Sustain level
 4) Amp Envelope Release time
 5) Lowpass Filter Cutoff frequency
 6) Lowpass Filter Resonance
 7) Lowpass Filter Saturation

 √ PAGE 3 - EFFECTS
 1) Delay time
 2) Delay feedback
 3) Delay PingPong
 4) Delay mix
 5) Reverb size
 6) Reverb tone
 7) Reverb mix
 
 √ PAGE 4 - GLOBAL
 1) Tempo
 2) Polyphony
 3) Root octave
 4) Root offset
 5) Fine tune
 6) Pre volume
 7) Post volume
  
 PAGE 5 - MODULATOR ENVELOPE  + KEYBOARD TRACKING
 1) Mod Envelope Attack time
 2) Mod Envelope Decay time
 3) Mod Envelope Sustain level
 4) Mod Envelope Release time
 5) Mod Envelope amount
 6) Key track to filter frequency amount
 7) Key track to voice lfo frequency amount
 
 PAGE 6 - AUXILIARY ENVELOPE
 1) Aux envelope Attack time
 2) Aux envelope Decay time
 3) Aux envelope Sustain level
 4) Aux envelope Release time
 5) Aux envelope to oscillator pitch amount
 6) Aux envelope to filter frequency amount
 7) Aux envelope to vibrato (voice lfo >> oscillator pitch) amount

 PAGE 7 - VOICE LFO
 1) Voice LFO waveform
 2) Voice LFO reset mode
 3) Voice LFO frequency
 4) Voice LFO to oscillator pitch amount
 5) Voice LFO to filter frequency amount
 6) Voice LFO to modulator level amount
 7) -
 
 PAGE 8 - GLOBAL LFO
 1) Global LFO waveform
 2) Global LFO reset mode
 3) Global LFO frequency
 4) Global LFO to oscillator amplitude amount
 5) Global LFO to filter frequency amount
 6) Global LFO to delay time amount
 7) -
 
 PAGE 9 - TOUCH RESPONSE
 1) Initial touch to oscillator amplitude amount
 2) Initial touch to filter frequency amount
 3) Aftertouch mode (relative/absolute)
 4) Aftertouch to filter frequency amount
 5) Aftertouch to vibrato (voice lfo >> oscillator pitch) amount
 6) -
 7) -
 
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
