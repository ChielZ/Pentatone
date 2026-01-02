//
//  V4-S10 ParameterPage10View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 10 - PRESET MANAGEMENT


 import SwiftUI

 struct PresetView: View {
     var body: some View {
         Group {
             ZStack { // Row 3
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("SELECT BANK")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             ZStack { // Row 4
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("SELECT PRESET")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             ZStack { // Row 5
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("SAVE PRESET")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
             }
             
             ZStack { // Row 6
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("EXPORT PRESET")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)
            }
             
             ZStack { // Row 7
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("IMPORT PRESET")
                     .foregroundColor(Color("HighlightColour"))
                     .adaptiveFont("Futura", size: 30)

               }
             ZStack { // Row 8
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 Text("ACTIVATE USER BANKS")
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
             PresetView()
         }
         .padding(25)
     }
 }

 
