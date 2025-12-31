//
//  V4-S05 ParameterPage5View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 5 - MOD ENVELOPE + KEY TRACKING

/*
 PAGE 5 - MODULATOR ENVELOPE + KEYBOARD TRACKING (REFACTORED - FIXED DESTINATIONS)
 √ 1) Mod Envelope Attack time
 √ 2) Mod Envelope Decay time
 √ 3) Mod Envelope Sustain level
 √ 4) Mod Envelope Release time
 √ 5) Mod Envelope amount (to modulation index - fixed destination)
 √ 6) Key track to filter frequency amount
 √ 7) Key track to voice lfo frequency amount
*/

import SwiftUI

struct ModEnvView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Modulator Envelope Attack (0-5 seconds)
            SliderRow(
                label: "MOD ENV ATTACK",
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
            
            // Row 2 - Modulator Envelope Decay (0-5 seconds)
            SliderRow(
                label: "MOD ENV DECAY",
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
            
            // Row 3 - Modulator Envelope Sustain (0-1)
            SliderRow(
                label: "MOD ENV SUSTAIN",
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
            
            // Row 4 - Modulator Envelope Release (0-5 seconds)
            SliderRow(
                label: "MOD ENV RELEASE",
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
            
            // Row 5 - Modulator Envelope Amount to Modulation Index (-5.0 to +5.0)
            // Fixed destination: modulation index only
            SliderRow(
                label: "MOD ENV AMOUNT",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.modulatorEnvelope.amountToModulationIndex },
                    set: { newValue in
                        paramManager.updateModulatorEnvelopeAmountToModulationIndex(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -5...5,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f", value) : String(format: "%.2f", value)
                }
            )
            
            // Row 6 - Key Tracking to Filter Frequency Amount (0.0 to 1.0)
            // Fixed destination 1: filter frequency (scales envelope/aftertouch modulation)
            SliderRow(
                label: "KEY TRACK TO FILTER",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.keyTracking.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateKeyTrackingAmountToFilterFrequency(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 7 - Key Tracking to Voice LFO Frequency Amount (0.0 to 1.0)
            // Fixed destination 2: voice LFO frequency (higher notes = faster LFO)
            SliderRow(
                label: "KEY TRACK TO LFO RATE",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.keyTracking.amountToVoiceLFOFrequency },
                    set: { newValue in
                        paramManager.updateKeyTrackingAmountToVoiceLFOFrequency(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
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
            ModEnvView()
        }
        .padding(25)
    }
}
