//
//  V4-S06 ParameterPage6View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 6 - AUX ENVELOPE

/*
PAGE 6 - AUXILIARY ENVELOPE
1) Aux envelope Attack time. SLIDER. Values: 0-5 continuous
2) Aux envelope Decay time. SLIDER. Values: 0-5 continuous
3) Aux envelope Sustain level. SLIDER. Values: 0-1 continuous
4) Aux envelope Release time. SLIDER. Values: 0-5 continuous
5) Aux envelope destination (Oscillator baseFrequency, modulatingMultiplier, Filter frequency [default], Voice LFO frequency, Voice LFO mod amount)
6) Aux envelope amount (unipolar modulation, so positive and negative amount)
*/

import SwiftUI

struct AuxEnvView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Auxiliary Envelope Attack (0-5 seconds)
            SliderRow(
                label: "AUX ENVELOPE ATTACK",
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
            
            // Row 4 - Auxiliary Envelope Decay (0-5 seconds)
            SliderRow(
                label: "AUX ENVELOPE DECAY",
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
            
            // Row 5 - Auxiliary Envelope Sustain (0-1)
            SliderRow(
                label: "AUX ENVELOPE SUSTAIN",
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
            
            // Row 6 - Auxiliary Envelope Release (0-5 seconds)
            SliderRow(
                label: "AUX ENVELOPE RELEASE",
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
            
            // Row 7 - Auxiliary Envelope Destination (List of modulation destinations)
            ParameterRow(
                label: "AUX ENVELOPE DESTINATION",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.destination },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeDestination(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                displayText: { destination in
                    // Shortened names to fit in UI
                    switch destination {
                    case .oscillatorAmplitude: return "OSC AMP"
                    case .oscillatorBaseFrequency: return "OSC FREQ"
                    case .modulationIndex: return "MOD IDX"
                    case .modulatingMultiplier: return "MOD MULT"
                    case .filterCutoff: return "FILTER"
                    case .stereoSpreadAmount: return "SPREAD"
                    case .voiceLFOFrequency: return "LFO RATE"
                    case .voiceLFOAmount: return "LFO DEPTH"
                    case .delayTime: return "DLY TIME"
                    case .delayMix: return "DLY MIX"
                    }
                }
            )
            
            // Row 8 - Auxiliary Envelope Amount (-1.0 to +1.0)
            SliderRow(
                label: "AUX ENVELOPE AMOUNT",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amount },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmount(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -1...1,
                step: 0.01,
                displayFormatter: { value in
                    let rounded = value
                    return rounded > 0 ? String(format: "+%.2f", rounded) : String(format: "%.2f", rounded)
                }
            )
            
            // Row 9 - Empty (for UI consistency)
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current modulation parameters to all active voices
    private func applyModulationToAllVoices() {
        let modulationParams = paramManager.voiceTemplate.modulation
        
        // Apply to all voices in the pool
        // Note: This requires the voicePool to have an update method
        // For now, this is a placeholder - the actual implementation
        // will depend on how the voice pool exposes modulation updates
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
