//
//  V4-S04 ParameterPage4View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 4 - GLOBAL

/*
PAGE 4 - GLOBAL
 1) Tempo. SLIDER. Values: 30-240, integers only
 2) Voice mode. LIST. Values: Poly, Mono
 3) Octave offset. SLIDER. Values: -2 to +2, integers only
 4) Semitone offset. SLIDER. Values: -7 to +7, integers only
 5) Fine tune. SLIDER. Values: -50 to +50, integers only
 6) Pre volume (voice mixer volume). SLIDER. Values: 0-1 continuous
 7) Post volume (output mixer volume). SLIDER. Values: 0-1 continuous
 */

import SwiftUI

struct GlobalView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Tempo (30-240 BPM, integers only)
            IntegerSliderRow(
                label: "TEMPO",
                value: Binding(
                    get: { paramManager.master.tempo },
                    set: { newValue in
                        paramManager.updateTempo(newValue)
                    }
                ),
                range: 30...240
            )
            
            // Row 4 - Voice Mode (Poly/Mono)
            ParameterRow(
                label: "VOICE MODE",
                value: Binding(
                    get: { paramManager.master.voiceMode },
                    set: { newValue in
                        paramManager.updateVoiceMode(newValue)
                    }
                ),
                displayText: { mode in
                    switch mode {
                    case .monophonic: return "Mono"
                    case .polyphonic: return "Poly"
                    }
                }
            )
            
            // Row 5 - Octave Offset (-2 to +2, integers only)
            SliderRow(
                label: "OCTAVE OFFSET",
                value: Binding(
                    get: { Double(paramManager.master.globalPitch.octaveOffset) },
                    set: { newValue in
                        paramManager.updateOctaveOffset(Int(round(newValue)))
                    }
                ),
                range: -2...2,
                step: 1.0,
                displayFormatter: { value in
                    let octaves = Int(round(value))
                    return octaves > 0 ? "+\(octaves)" : "\(octaves)"
                }
            )
            
            // Row 6 - Semitone Offset (-7 to +7, integers only)
            SliderRow(
                label: "SEMITONE OFFSET",
                value: Binding(
                    get: { Double(paramManager.master.globalPitch.transposeSemitones) },
                    set: { newValue in
                        paramManager.updateTransposeSemitones(Int(round(newValue)))
                    }
                ),
                range: -7...7,
                step: 1.0,
                displayFormatter: { value in
                    let semitones = Int(round(value))
                    return semitones > 0 ? "+\(semitones)" : "\(semitones)"
                }
            )
            
            
            
            // Row 7 - Fine Tune (-50 to +50 cents, integers only)
            SliderRow(
                label: "FINE TUNE",
                value: Binding(
                    get: { paramManager.master.globalPitch.fineTuneCents },
                    set: { newValue in
                        paramManager.updateFineTuneCents(newValue)
                    }
                ),
                range: -50...50,
                step: 1.0,
                displayFormatter: { value in
                    let cents = Int(round(value))
                    return cents > 0 ? "+\(cents)" : "\(cents)"
                }
            )
            
            // Row 8 - Pre Volume (0-1 continuous)
            SliderRow(
                label: "PRE VOLUME",
                value: Binding(
                    get: { paramManager.master.output.preVolume },
                    set: { newValue in
                        paramManager.updatePreVolume(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 9 - Post Volume (0-1 continuous)
            SliderRow(
                label: "POST VOLUME",
                value: Binding(
                    get: { paramManager.master.output.volume },
                    set: { newValue in
                        paramManager.updateOutputVolume(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            GlobalView()
        }
        .padding(25)
    }
}
