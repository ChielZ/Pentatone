//
//  V4-S07 ParameterPage7View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 7 - VOICE LFO

/*
PAGE 7 - VOICE LFO
1) Voice LFO waveform (sine, triangle, square, sawtooth, reversed sawtooth)
2) Voice LFO reset mode (free, trigger, sync)
3) Voice LFO frequency (0-10 Hz or tempo multipliers depending on mode)
4) Voice LFO destination (Oscillator baseFrequency [default], modulationIndex, modulatingMultiplier, Filter frequency, stereo spread offset amount)
5) Voice LFO amount (bipolar modulation, so only positive amounts)
*/

 
import SwiftUI

struct VoiceLFOView: View {
    var body: some View {
        Group {
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("VOICE LFO WAVEFORM")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("VOICE LFO RESET")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("VOICE LFO FREQUENCY")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("VOICE LFO DESTINATION")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
           }
            
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("VOICE LFO AMOUNT")
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
            VoiceLFOView()
        }
        .padding(25)
    }
}
