//
//  V3-S2 SoundView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct SoundView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                GeometryReader { geometry in
                    Text("Pentatone")
                        .foregroundColor(Color("KeyColour1"))
                        .adaptiveFont("Signpainter", size: 55)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        //.onTapGesture {
                        //    onSwitchToEdit?()
                        }
                
            }
            
            
            
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))

                HStack {
                   
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("HighlightColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("1")
                                    .foregroundColor(Color("BackgroundColour"))
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
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
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
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("Futura", size: 30)
                        )
                }
            }
            ZStack { // Row 4 - VOLUME
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(0)
                
                // Volume slider (0 to 1, left to right)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * paramManager.macroState.volumePosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - paramManager.macroState.volumePosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                let clampedPosition = min(max(newPosition, 0.0), 1.0)
                                paramManager.updateVolumeMacro(clampedPosition)
                            }
                    )
                }
                
                Text("VOLUME")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
                    .allowsHitTesting(false)
            }
            
            ZStack { // Row 5 - TONE
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(0)
                
                // Tone slider (-1 to +1, bipolar with center at 0)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Calculate widths based on position (-1 to +1)
                        let normalizedPosition = (paramManager.macroState.tonePosition + 1.0) / 2.0 // Convert -1...1 to 0...1
                        
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * normalizedPosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - normalizedPosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert x position to -1...+1 range
                                let normalizedX = value.location.x / geometry.size.width
                                let newPosition = (normalizedX * 2.0) - 1.0 // Convert 0...1 to -1...1
                                paramManager.updateToneMacro(newPosition)
                            }
                    )
                }
                
                Text("TONE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
                    .allowsHitTesting(false)
            }
            
            ZStack { // Row 6 - AMBIENCE
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(0)
                
                // Ambience slider (-1 to +1, bipolar with center at 0)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Calculate widths based on position (-1 to +1)
                        let normalizedPosition = (paramManager.macroState.ambiencePosition + 1.0) / 2.0 // Convert -1...1 to 0...1
                        
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * normalizedPosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - normalizedPosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert x position to -1...+1 range
                                let normalizedX = value.location.x / geometry.size.width
                                let newPosition = (normalizedX * 2.0) - 1.0 // Convert 0...1 to -1...1
                                paramManager.updateAmbienceMacro(newPosition)
                            }
                    )
                }
                
                Text("AMBIENCE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("Futura", size: 30)
                    .allowsHitTesting(false)
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
