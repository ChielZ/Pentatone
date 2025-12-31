//
//  V4-S07 ParameterPage7View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 7 - VOICE LFO

/*
 PAGE 7 - VOICE LFO (REFACTORED - FIXED DESTINATIONS)
 √ 1) Voice LFO waveform
 √ 2) Voice LFO mode (free/trigger/sync)
 √ 3) Voice LFO frequency
 √ 4) Voice LFO to oscillator pitch amount
 √ 5) Voice LFO to filter frequency amount
 √ 6) Voice LFO to modulator level amount
 √ 7) Voice LFO delay (ramps amounts)
 */

 
import SwiftUI

struct VoiceLFOView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Voice LFO Waveform (sine, triangle, square, sawtooth, reverse sawtooth)
            ParameterRow(
                label: "LFO WAVEFORM",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.waveform },
                    set: { newValue in
                        paramManager.updateVoiceLFOWaveform(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                displayText: { waveform in
                    switch waveform {
                    case .sine: return "Sine"
                    case .triangle: return "Triangle"
                    case .square: return "Square"
                    case .sawtooth: return "Sawtooth"
                    case .reverseSawtooth: return "Reverse Saw"
                    }
                }
            )
            
            // Row 2 - Voice LFO Reset Mode (free, trigger, sync)
            ParameterRow(
                label: "LFO MODE",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.resetMode },
                    set: { newValue in
                        paramManager.updateVoiceLFOResetMode(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                displayText: { mode in
                    switch mode {
                    case .free: return "Free"
                    case .trigger: return "Trigger"
                    case .sync: return "Sync"
                    }
                }
            )
            
            // Row 3 - Voice LFO Frequency (0.01-20 Hz)
            SliderRow(
                label: "LFO FREQUENCY",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.frequency },
                    set: { newValue in
                        paramManager.updateVoiceLFOFrequency(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0.01...20,
                step: 0.01,
                displayFormatter: { String(format: "%.2f Hz", $0) }
            )
            
            // Row 4 - Voice LFO Delay (ramp time for amounts)
            SliderRow(
                label: "LFO DELAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.delayTime },
                    set: { newValue in
                        paramManager.updateVoiceLFODelayTime(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f s", $0) }
            )
            
            // Row 5 - Voice LFO to Oscillator Pitch (vibrato)
            SliderRow(
                label: "LFO TO PITCH",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.amountToOscillatorPitch },
                    set: { newValue in
                        paramManager.updateVoiceLFOAmountToPitch(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -5...5,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f st", value) : String(format: "%.2f st", value)
                }
            )
            
            // Row 6 - Voice LFO to Filter Frequency
            SliderRow(
                label: "LFO TO FILTER",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateVoiceLFOAmountToFilter(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -2...2,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f oct", value) : String(format: "%.2f oct", value)
                }
            )
            
            // Row 7 - Voice LFO to Modulator Level (FM timbre modulation)
            SliderRow(
                label: "LFO TO MODULATOR",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.voiceLFO.amountToModulatorLevel },
                    set: { newValue in
                        paramManager.updateVoiceLFOAmountToModulatorLevel(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -5...5,
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
            VoiceLFOView()
        }
        .padding(25)
    }
}
