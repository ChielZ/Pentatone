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
    var body: some View {
        Group {
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE ATTACK")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE DECAY")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE SUSTAIN")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE RELEASE")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
           }
            
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE DESTINATION")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

              }
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("AUX ENVELOPE AMOUNT")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

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
            AuxEnvView()
        }
        .padding(25)
    }
}
