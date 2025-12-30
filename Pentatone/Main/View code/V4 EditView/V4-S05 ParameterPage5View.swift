//
//  V4-S05 ParameterPage5View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 5 - MOD ENVELOPE + KEY TRACKING

/*
PAGE 5 - MODULATOR ENVELOPE  + KEYBOARD TRACKING
1) Mod Envelope Attack time. SLIDER. Values: 0-5 continuous
2) Mod Envelope Decay time. SLIDER. Values: 0-5 continuous
3) Mod Envelope Sustain level. SLIDER. Values: 0-1 continuous
4) Mod Envelope Release time. SLIDER. Values: 0-5 continuous
5) Mod Envelope amount (=> modulationIndex + Modulation envelope value * envelope amount)
6) Key tracking destination (Oscillator amplitude, modulationIndex, modulatingMultiplier, Filter frequency, Voice LFO frequency, Voice LFO mod amount)
7) Key tracking amount (unipolar modulation, so positive and negative amount)
*/

import SwiftUI

struct ModEnvView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Modulator Envelope Attack (0-5 seconds)
            SliderRow(
                label: "MOD ENVELOPE ATTACK",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.attack },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeAttack(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 4 - Modulator Envelope Decay (0-5 seconds)
            SliderRow(
                label: "MOD ENVELOPE DECAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.decay },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeDecay(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 5 - Modulator Envelope Sustain (0-1)
            SliderRow(
                label: "MOD ENVELOPE SUSTAIN",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.sustain },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeSustain(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.001,
                displayFormatter: { String(format: "%.3f", $0) }
            )
            
            // Row 6 - Modulator Envelope Release (0-5 seconds)
            SliderRow(
                label: "MOD ENVELOPE RELEASE",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.release },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeRelease(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 7 - Modulator Envelope Amount (-1.0 to +1.0)
            SliderRow(
                label: "MOD ENVELOPE AMOUNT",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.amount },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeAmount(newValue)
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
            
            // Row 8 - Key Tracking Destination (List of modulation destinations)
            ParameterRow(
                label: "KEY TRACK DESTINATION",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.keyTracking.destination },
                    set: { newValue in
                        paramManager.updateKeyTrackingDestination(newValue)
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
            
            // Row 9 - Key Tracking Amount (-1.0 to +1.0)
            SliderRow(
                label: "KEY TRACK AMOUNT",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.keyTracking.amount },
                    set: { newValue in
                        paramManager.updateKeyTrackingAmount(newValue)
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
            ModEnvView()
        }
        .padding(25)
    }
}
