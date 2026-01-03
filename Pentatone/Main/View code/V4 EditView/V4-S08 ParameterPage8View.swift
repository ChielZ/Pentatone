//
//  V4-S08 ParameterPage8View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 8 - GLOBAL LFO

/*
 PAGE 8 - GLOBAL LFO (REFACTORED - FIXED DESTINATIONS)
 √ 1) Global LFO waveform
 √ 2) Global LFO mode (free/sync)
 √ 3) Global LFO frequency
 √ 4) Global LFO to oscillator amplitude amount
 √ 5) Global LFO to modulator multiplier (fine) amount
 √ 6) Global LFO to filter frequency amount
 √ 7) Global LFO to delay time amount
 */

import SwiftUI

struct GlobLFOView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Global LFO Waveform (sine, triangle, square, sawtooth, reverse sawtooth)
            ParameterRow(
                label: "LFO WAVEFORM",
                value: Binding(
                    get: { paramManager.master.globalLFO.waveform },
                    set: { newValue in
                        paramManager.updateGlobalLFOWaveform(newValue)
                    }
                ),
                displayText: { waveform in
                    switch waveform {
                    case .sine: return "Sine"
                    case .triangle: return "Triangle"
                    case .square: return "Square"
                    case .sawtooth: return "Sawtooth"
                    case .reverseSawtooth: return "Reverse saw"
                    }
                }
            )
            
            // Row 2 - Global LFO Reset Mode (free, sync only)
            GlobalLFOModeRow(
                label: "LFO MODE",
                value: Binding(
                    get: { paramManager.master.globalLFO.resetMode },
                    set: { newValue in
                        paramManager.updateGlobalLFOResetMode(newValue)
                    }
                )
            )
            
            // Row 3 - Global LFO Frequency (0.01-20 Hz)
            SliderRow(
                label: "LFO FREQUENCY",
                value: Binding(
                    get: { paramManager.master.globalLFO.frequency },
                    set: { newValue in
                        paramManager.updateGlobalLFOFrequency(newValue)
                    }
                ),
                range: 0.01...20,
                step: 0.01,
                displayFormatter: { String(format: "%.2f Hz", $0) }
            )
            
            // Row 4 - Global LFO to Oscillator Amplitude (tremolo)
            SliderRow(
                label: "LFO TO AMP",
                value: Binding(
                    get: { paramManager.master.globalLFO.amountToOscillatorAmplitude },
                    set: { newValue in
                        paramManager.updateGlobalLFOAmountToAmplitude(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f", value) : String(format: "%.2f", value)
                }
            )
            
            // Row 5 - Global LFO to Modulator Multiplier (FM ratio modulation)
            SliderRow(
                label: "LFO TO MOD MULTI",
                value: Binding(
                    get: { paramManager.master.globalLFO.amountToModulatorMultiplier },
                    set: { newValue in
                        paramManager.updateGlobalLFOAmountToModulatorMultiplier(newValue)
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f", value) : String(format: "%.2f", value)
                }
            )
            
            // Row 6 - Global LFO to Filter Frequency
            SliderRow(
                label: "LFO TO FILTER",
                value: Binding(
                    get: { paramManager.master.globalLFO.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateGlobalLFOAmountToFilter(newValue)
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.2f oct", value) : String(format: "%.2f oct", value)
                }
            )
            
            // Row 7 - Global LFO to Delay Time
            SliderRow(
                label: "LFO TO DELAY TIME",
                value: Binding(
                    get: { paramManager.master.globalLFO.amountToDelayTime },
                    set: { newValue in
                        paramManager.updateGlobalLFOAmountToDelayTime(newValue)
                    }
                ),
                range: 0...0.05,
                step: 0.001,
                displayFormatter: { value in
                    return value > 0 ? String(format: "+%.3f s", value) : String(format: "%.3f s", value)
                }
            )
        }
    }
}

// MARK: - Global LFO Mode Row (Free and Sync only)

/// Custom parameter row for Global LFO mode that only shows Free and Sync modes
private struct GlobalLFOModeRow: View {
    let label: String
    @Binding var value: LFOResetMode
    
    // Only Free and Sync are valid for global LFO
    private let validModes: [LFOResetMode] = [.free, .sync]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack {
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cyclePrevious()
                    }
                
                Spacer()
                
                // Center display - label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
            }
            .padding(.horizontal, 0)
        }
    }
    
    private func displayText(_ mode: LFOResetMode) -> String {
        switch mode {
        case .free: return "Free"
        case .trigger: return "Trigger"  // Should never be displayed
        case .sync: return "Sync"
        }
    }
    
    private func cycleNext() {
        guard let currentIndex = validModes.firstIndex(of: value) else { return }
        let nextIndex = (currentIndex + 1) % validModes.count
        value = validModes[nextIndex]
    }
    
    private func cyclePrevious() {
        guard let currentIndex = validModes.firstIndex(of: value) else { return }
        let previousIndex = (currentIndex - 1 + validModes.count) % validModes.count
        value = validModes[previousIndex]
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            GlobLFOView()
        }
        .padding(25)
    }
}
