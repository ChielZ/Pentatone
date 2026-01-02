//
//  V4-S11 ParameterPage10View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 26/12/2025.
// SUBVIEW 11 - MACROS
/*
 1) Tone >> ModulationIndex range +/- 0...5
 2) Tone >> Cutoff range +/- 0-4 octaves
 3) Tone >> Filter saturation range +/- 0...2
 4) Ambience >> Delay feedback range +/- 0...1
 5) Ambience >> Delay Mix range +/- 0...1
 6) Ambience >> Reverb size range +/- 0...1
 7) Ambience >> Reverb mix range +/- 0...1
 */


import SwiftUI

struct MacroView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Tone to Modulation Index Range
            SliderRow(
                label: "TONE TO MOD INDEX",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToModulationIndexRange },
                    set: { newValue in
                        paramManager.updateToneToModulationIndexRange(newValue)
                    }
                ),
                range: 0...5,
                step: 0.1,
                displayFormatter: { String(format: "±%.1f", $0) }
            )
            
            // Row 4 - Tone to Filter Cutoff Octaves
            SliderRow(
                label: "TONE TO CUTOFF",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToFilterCutoffOctaves },
                    set: { newValue in
                        paramManager.updateToneToFilterCutoffOctaves(newValue)
                    }
                ),
                range: 0...4,
                step: 0.1,
                displayFormatter: { String(format: "±%.1f oct", $0) }
            )
            
            // Row 5 - Tone to Filter Saturation Range
            SliderRow(
                label: "TONE TO SATURATION",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToFilterSaturationRange },
                    set: { newValue in
                        paramManager.updateToneToFilterSaturationRange(newValue)
                    }
                ),
                range: 0...2,
                step: 0.1,
                displayFormatter: { String(format: "±%.1f", $0) }
            )
            
            // Row 6 - Ambience to Delay Feedback Range
            SliderRow(
                label: "AMBIENCE TO DELAY FB",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToDelayFeedbackRange },
                    set: { newValue in
                        paramManager.updateAmbienceToDelayFeedbackRange(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "±%.2f", $0) }
            )
            
            // Row 7 - Ambience to Delay Mix Range
            SliderRow(
                label: "AMBIENCE TO DELAY MIX",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToDelayMixRange },
                    set: { newValue in
                        paramManager.updateAmbienceToDelayMixRange(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "±%.2f", $0) }
            )
            
            // Row 8 - Ambience to Reverb Feedback Range
            SliderRow(
                label: "AMBIENCE TO REVERB SIZE",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToReverbFeedbackRange },
                    set: { newValue in
                        paramManager.updateAmbienceToReverbFeedbackRange(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "±%.2f", $0) }
            )
            
            // Row 9 - Ambience to Reverb Mix Range
            SliderRow(
                label: "AMBIENCE TO REVERB MIX",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToReverbMixRange },
                    set: { newValue in
                        paramManager.updateAmbienceToReverbMixRange(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "±%.2f", $0) }
            )
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            MacroView()
        }
        .padding(25)
    }
}
