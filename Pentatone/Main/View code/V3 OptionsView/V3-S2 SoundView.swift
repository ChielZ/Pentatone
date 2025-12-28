//
//  V3-S2 SoundView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct SoundView: View {
    var body: some View {
        Group {
            
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
                HStack{
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                        .padding(0)
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .padding(4)
                }
                Text("VOLUME")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
                HStack{
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                        .padding(0)
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .padding(4)
                }
                Text("TONE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
                HStack{
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                        .padding(0)
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .padding(4)
                }
                Text("AMBIENCE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    Text("1.1 KEYS")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                }
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("1")
                                .foregroundColor(Color("HighlightColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("2")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("3")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("4")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("5")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    
                }
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("1")
                                .foregroundColor(Color("HighlightColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("2")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("3")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("4")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("5")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                    
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            SoundView()
        }
        .padding(25)
    }
}
