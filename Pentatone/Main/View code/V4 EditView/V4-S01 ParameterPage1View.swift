//
//  V4-S01 ParameterPage1View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 1 - VOICE OSCILLATORS

/*
 PAGE 1 - VOICE OSCILLATORS
 1) Oscillator Waveform. LIST. Values: sine, triangle, square
 2) Carrier multiplier. SLIDER. Values: integers only, range 1-16
 3) Modulator multiplier coarse. SLIDER. Values: integers only, range 1-16
 4) Modulator multiplier fine. SLIDER. Values: 0-1 continuous
 5) Modulator base level. SLIDER. Values: 0-1 continuous
 6) Stereo offset mode. LIST. Values: constant, proportional
 7) Stereo offset amount. SLIDER. Values: 0-4 continuous for constant offset mode, 1.0000-1.0100 continuous for proportional offset mode
 */

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

struct OscillatorView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // Local state for the modulator multiplier split into coarse + fine
    @State private var modulatorCoarse: Double = 2.0
    @State private var modulatorFine: Double = 0.0
    
    var body: some View {
        Group {
            // Row 3 - Waveform (enum cycling)
            // Note: Waveform changes require app restart due to AudioKit limitations
            ParameterRow(
                label: "WAVEFORM",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.waveform },
                    set: { newValue in
                        paramManager.updateOscillatorWaveform(newValue)
                        // Note: Waveform change saved to template but won't affect current voices
                    }
                ),
                displayText: { $0.displayName }
            )
            
            // Row 4 - Carrier Multiplier (integer 1-16)
            IntegerSliderRow(
                label: "CARRIER MULTIPLIER",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.carrierMultiplier },
                    set: { newValue in
                        paramManager.updateCarrierMultiplier(newValue)
                        applyToAllVoices()
                    }
                ),
                range: 1...16
            )
            
            // Row 5 - Modulator Multiplier Coarse (integer 1-16)
            IntegerSliderRow(
                label: "MODULATOR COARSE",
                value: $modulatorCoarse,
                range: 1...16
            )
            .onChange(of: modulatorCoarse) { newCoarse in
                updateModulatingMultiplier(coarse: Int(newCoarse), fine: modulatorFine)
            }
            
            // Row 6 - Modulator Multiplier Fine (0-1 continuous)
            SliderRow(
                label: "MODULATOR FINE",
                value: $modulatorFine,
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            .onChange(of: modulatorFine) { newFine in
                updateModulatingMultiplier(coarse: Int(modulatorCoarse), fine: newFine)
            }
            
            // Row 7 - Modulation Index (base level, 0-10)
            SliderRow(
                label: "MODULATOR BASE LEVEL",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.modulationIndex },
                    set: { newValue in
                        paramManager.updateModulationIndex(newValue)
                        applyToAllVoices()
                    }
                ),
                range: 0...10,
                step: 0.1,
                displayFormatter: { String(format: "%.1f", $0) }
            )
            
            // Row 8 - Stereo Offset Mode (enum cycling)
            ParameterRow(
                label: "STEREO MODE",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.detuneMode },
                    set: { newValue in
                        paramManager.updateDetuneMode(newValue)
                        applyToAllVoices()
                    }
                ),
                displayText: { mode in
                    switch mode {
                    case .proportional: return "Proportional"
                    case .constant: return "Constant"
                    }
                }
            )
            
            // Row 9 - Stereo Offset Amount (conditional range based on mode)
            SliderRow(
                label: "STEREO AMOUNT",
                value: Binding(
                    get: {
                        if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                            return paramManager.voiceTemplate.oscillator.stereoOffsetProportional
                        } else {
                            return paramManager.voiceTemplate.oscillator.stereoOffsetConstant
                        }
                    },
                    set: { newValue in
                        if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                            paramManager.updateStereoOffsetProportional(newValue)
                        } else {
                            paramManager.updateStereoOffsetConstant(newValue)
                        }
                        applyToAllVoices()
                    }
                ),
                range: paramManager.voiceTemplate.oscillator.detuneMode == .proportional ? 1.0000...1.0100 : 0...4,
                step: paramManager.voiceTemplate.oscillator.detuneMode == .proportional ? 0.0001 : 0.1,
                displayFormatter: { value in
                    if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                        return String(format: "%.4f", value)
                    } else {
                        return String(format: "%.1f Hz", value)
                    }
                }
            )
        }
        .onAppear {
            // Initialize local state from current template
            let current = paramManager.voiceTemplate.oscillator.modulatingMultiplier
            modulatorCoarse = floor(current)
            modulatorFine = current - floor(current)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Updates the combined modulatingMultiplier from coarse + fine components
    private func updateModulatingMultiplier(coarse: Int, fine: Double) {
        let combined = Double(coarse) + fine
        paramManager.updateModulatingMultiplier(combined)
        applyToAllVoices()
    }
    
    /// Applies current template parameters to all active voices
    /// Note: Waveform changes only apply to newly triggered notes
    private func applyToAllVoices() {
        let params = paramManager.voiceTemplate.oscillator
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            // Note: Waveform cannot be changed on running oscillators in AudioKit
            // New waveform will apply to newly triggered notes only
            
            // Update multipliers with zero-duration ramp (instant change)
            voice.oscLeft.$carrierMultiplier.ramp(to: AUValue(params.carrierMultiplier), duration: 0)
            voice.oscRight.$carrierMultiplier.ramp(to: AUValue(params.carrierMultiplier), duration: 0)
            
            voice.oscLeft.$modulatingMultiplier.ramp(to: AUValue(params.modulatingMultiplier), duration: 0)
            voice.oscRight.$modulatingMultiplier.ramp(to: AUValue(params.modulatingMultiplier), duration: 0)
            
            voice.oscLeft.$modulationIndex.ramp(to: AUValue(params.modulationIndex), duration: 0)
            voice.oscRight.$modulationIndex.ramp(to: AUValue(params.modulationIndex), duration: 0)
            
            // Update stereo spread
            voice.detuneMode = params.detuneMode
            if params.detuneMode == .proportional {
                voice.frequencyOffsetRatio = params.stereoOffsetProportional
            } else {
                voice.frequencyOffsetHz = params.stereoOffsetConstant
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            OscillatorView()
        }
        .padding(25)
    }
}
