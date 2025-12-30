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
    var body: some View {
        Group {
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("MOD ENVELOPE ATTACK")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("MOD ENVELOPE DECAY")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("MOD ENVELOPE SUSTAIN")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("MOD ENVELOPE RELEASE")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)
           }
            
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("MOD ENVELOPE AMOUNT")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

              }
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("KEY TRACK DESTINATION")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

             }
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                Text("KEY TRACK AMOUNT")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 30)

            }
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
