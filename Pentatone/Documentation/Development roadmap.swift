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
 - implement modulation generators
 - implement modulators in parameter structure
 - create preset management
 >> sanity check code structure
 - create developer view for sound editing/storing presets
 - add macro control
 (- port engine to tonehive)
 - add in app documentation
 
UI
 √ ET / JI: display as EQUAL / JUST
 √ Improve spacing/layout
 - Implement scale type graphics display (raw shapes or image files?)
 - Implement note name display
 - Implement basic tooltip structure (toggle on/of in voice menu?)
 
MINOR IMPROVEMENTS
 √ Change intonation display from ET/JI to EQUAL / JUST
 √ Check font warning
 - distinguish between iPad landscape and iPad portrait for font sizes? (apparently tricky, couldn't get to work on first try - also, looking quite good already anyway)
 - check delay dry/wet mix parameter direction, 0.0 is now fully wet and 1.0 is fully dry (?)
 - check: what is the update rate for touch (x position) changes? Filter sweep very choppy, cause?
 
 
 
 Presets
 
 1.1  Keys (Wurlitzer-esque sound)
 1.2  Mallets (Marimba-esque sound)
 1.3  Sticks (Glockenspiel-esque sound)
 1.4  Pluck (Harp-esque sound)
 1.5  Pick (Koto-esque sound)
 
 2.1  Bow (Cello-esque sound)
 2.2  Breath (Low whistle-esque sound)
 2.3  Tube (Rock Organ-esque sound)
 2.4  Transistor (Analog polysynth-esque sound)
 2.5  Chip (Square Lead-esque sound)
 
 3.1  Ocean (Analog bass-esque sound)
 3.2  Forest (lively, organic sound)
 3.3  Field (warm, airy sound)
 3.4  Nebula (Warm, ethereal sound)
 3.5  Haze (Granular-esque sound)
 
 
 */
