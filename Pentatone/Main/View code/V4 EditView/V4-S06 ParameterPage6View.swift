//  V4-S06 ParameterPage6View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 6 - AUX ENVELOPE

/*
 PAGE 6 - AUXILIARY ENVELOPE (REFACTORED - FIXED DESTINATIONS)
 √ 1) Aux envelope Attack time
 √ 2) Aux envelope Decay time
 √ 3) Aux envelope Sustain level
 √ 4) Aux envelope Release time
 √ 5) Aux envelope to oscillator pitch amount
 √ 6) Aux envelope to filter frequency amount
 √ 7) Aux envelope to vibrato (voice lfo >> oscillator pitch) amount
*/

import SwiftUI

struct AuxEnvView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Auxiliary Envelope Attack (0-5 seconds)
            SliderRow(
                label: "AUX ENV ATTACK",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.attack },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAttack(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 2 - Auxiliary Envelope Decay (0-5 seconds)
            SliderRow(
                label: "AUX ENV DECAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.decay },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeDecay(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 3 - Auxiliary Envelope Sustain (0-1)
            SliderRow(
                label: "AUX ENV SUSTAIN",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.sustain },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeSustain(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.001,
                displayFormatter: { String(format: "%.3f", $0) }
            )
            
            // Row 4 - Auxiliary Envelope Release (0-5 seconds)
            SliderRow(
                label: "AUX ENV RELEASE",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.release },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeRelease(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 5 - Auxiliary Envelope to Oscillator Pitch (pitch sweep)
            SliderRow(
                label: "AUX ENV TO PITCH",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToOscillatorPitch },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToPitch(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -12...12,
                step: 0.1,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.1f st", value) : String(format: "%.1f st", value)
                }
            )
            
            // Row 6 - Auxiliary Envelope to Filter Frequency
            SliderRow(
                label: "AUX ENV TO FILTER",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToFilter(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -3...3,
                step: 0.1,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.1f oct", value) : String(format: "%.1f oct", value)
                }
            )
            
            // Row 7 - Auxiliary Envelope to Vibrato (meta-modulation of voice LFO pitch amount)
            SliderRow(
                label: "AUX ENV TO LFO",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToVibrato },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToVibrato(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -2...2,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f", value) : String(format: "%.2f", value)
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current modulation parameters to all active voices
    private func applyModulationToAllVoices() {
        let modulationParams = paramManager.voiceTemplate.modulation
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            voice.updateModulationParameters(modulationParams)
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            AuxEnvView()
        }
        .padding(25)
    }
}
