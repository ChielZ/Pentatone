//
//  MacroControlsView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//  Simple macro controls for the main UI

import SwiftUI

/// Simple macro controls for the main UI
/// Contains Volume, Tone, and Ambience controls
struct MacroControlsView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Volume Control (0 to 1, absolute)
            MacroControlRow(
                label: "VOLUME",
                value: Binding(
                    get: { paramManager.master.output.preVolume },
                    set: { newValue in
                        paramManager.updateVolumeMacro(newValue)
                    }
                ),
                range: 0...1,
                isBipolar: false,
                displayFormatter: { String(format: "%.0f%%", $0 * 100) }
            )
            
            // Tone Control (-1 to +1, relative/bipolar)
            MacroControlRow(
                label: "TONE",
                value: Binding(
                    get: { paramManager.macroState.tonePosition },
                    set: { newValue in
                        paramManager.updateToneMacro(newValue)
                    }
                ),
                range: -1...1,
                isBipolar: true,
                displayFormatter: { value in
                    if value > 0 {
                        return String(format: "+%.0f%%", value * 100)
                    } else if value < 0 {
                        return String(format: "%.0f%%", value * 100)
                    } else {
                        return "0%"
                    }
                }
            )
            
            // Ambience Control (-1 to +1, relative/bipolar)
            MacroControlRow(
                label: "AMBIENCE",
                value: Binding(
                    get: { paramManager.macroState.ambiencePosition },
                    set: { newValue in
                        paramManager.updateAmbienceMacro(newValue)
                    }
                ),
                range: -1...1,
                isBipolar: true,
                displayFormatter: { value in
                    if value > 0 {
                        return String(format: "+%.0f%%", value * 100)
                    } else if value < 0 {
                        return String(format: "%.0f%%", value * 100)
                    } else {
                        return "0%"
                    }
                }
            )
        }
    }
}

/// A single macro control row with label and slider
struct MacroControlRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let isBipolar: Bool  // If true, shows center mark at 0
    let displayFormatter: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("HighlightColour"))
                Spacer()
                Text(displayFormatter(value))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("HighlightColour").opacity(0.8))
            }
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("BackgroundColour"))
                    .frame(height: 40)
                
                // Center mark for bipolar controls
                if isBipolar {
                    Rectangle()
                        .fill(Color("HighlightColour").opacity(0.3))
                        .frame(width: 2)
                        .position(x: UIScreen.main.bounds.width / 2, y: 20)
                }
                
                // Slider
                Slider(value: $value, in: range)
                    .accentColor(Color("HighlightColour"))
                    .padding(.horizontal, 12)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            MacroControlsView()
        }
        .padding(25)
    }
}
