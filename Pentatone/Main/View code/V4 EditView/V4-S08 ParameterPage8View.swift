//
//  V4-S08 ParameterPage8View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 8 - GLOBAL LFO

/*
PAGE 8 - GLOBAL LFO
1) Global LFO waveform (sine, triangle, square, sawtooth, reversed sawtooth)
2) Global LFO reset mode (free, sync)
3) Global LFO frequency (0-10 Hz or tempo multipliers depending on mode)
4) Global LFO destination (Oscillator amplitude [default], Oscillator baseFrequency, modulationIndex, modulatingMultiplier, Filter frequency, delay time, delay amount)
5) Global LFO amount (bipolar modulation, so only positive amounts)
*/

import SwiftUI

struct GlobLFOView: View {
    var body: some View {
        Group {
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("GLOBAL LFO WAVEFORM")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("GLOBAL LFO RESET")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("GLOBAL LFO FREQUENCY")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("GLOBAL LFO DESTINATION")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
           }
            
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("GLOBAL LFO AMOUNT")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

              }
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                             }
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
        }
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
