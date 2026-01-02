//
//  V4-S11 ParameterPage10View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 26/12/2025.
// SUBVIEW 11 - MACROS
/*
 1) Tone ModulationIndex range
 2) Tone Cutoff range
 3) Tone Filter saturation range
 4) Ambience Delay feedback range
 5) Ambience Delay Mix range
 6) Ambience Reverb size range
 7) Ambience Reverb mix range
 */


 import SwiftUI

 struct MacroView: View {
     var body: some View {
         Group {
             ZStack { // Row 3
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("TONE TO MOD INDEX")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             ZStack { // Row 4
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("TONE TO CUTOFF")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             ZStack { // Row 5
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("TONE TO SATURATION")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             
             ZStack { // Row 6
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("AMBIENCE TO DELAY FB")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
            }
             
             ZStack { // Row 7
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("AMBIENCE TO DELAY MIX")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)

               }
             ZStack { // Row 8
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("AMBIENCE TO REVERB SIZE")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)

              }
             ZStack { // Row 9
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("AMBIENCE TO REVERB MIX")
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
             MacroView()
         }
         .padding(25)
     }
 }

 

