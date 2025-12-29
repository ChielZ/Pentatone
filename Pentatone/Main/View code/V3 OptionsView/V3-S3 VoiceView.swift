//
//  V3-S3 VoiceView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct VoiceView: View {
    var onSwitchToEdit: (() -> Void)? = nil
    
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // Computed property to force view updates
    private var fineTuneCentsDisplay: Int {
        let value = Int(round(paramManager.master.globalPitch.fineTuneCents))
        return value
    }
    
    var body: some View {
        Group {
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
                }
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
                }
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                GeometryReader { geometry in
                    Text("Pentatone")
                        .foregroundColor(Color("KeyColour1"))
                        .adaptiveFont("Signpainter", size: 65)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .onTapGesture {
                            onSwitchToEdit?()
                        }
                }
            }
            
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
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
                        .onTapGesture {
                            // Switch to monophonic
                            if paramManager.master.voiceMode != .monophonic {
                                paramManager.updateVoiceMode(.monophonic)
                            }
                        }
                    Spacer()
                    Text(paramManager.master.voiceMode == .monophonic ? "MONO" : "POLY")
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
                        .onTapGesture {
                            // Switch to polyphonic
                            if paramManager.master.voiceMode != .polyphonic {
                                paramManager.updateVoiceMode(.polyphonic)
                            }
                        }
                }
            }
            ZStack { // Row 8
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
                        .onTapGesture {
                            let current = paramManager.master.globalPitch.octaveOffset
                            if current > -2 {
                                paramManager.updateOctaveOffset(current - 1)
                            }
                        }
                    Spacer()
                    Text("OCTAVE \(paramManager.master.globalPitch.octaveOffset > 0 ? "+" : "")\(paramManager.master.globalPitch.octaveOffset)")
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
                        .onTapGesture {
                            let current = paramManager.master.globalPitch.octaveOffset
                            if current < 2 {
                                paramManager.updateOctaveOffset(current + 1)
                            }
                        }
                }
            }
            ZStack { // Row 9
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
                        .onTapGesture {
                            let current = fineTuneCentsDisplay
                            if current > -50 {
                                paramManager.updateFineTuneCents(Double(current - 1))
                                }
                        }
                    Spacer()
                    Text("TUNE \(fineTuneCentsDisplay > 0 ? "+" : "")\(fineTuneCentsDisplay)")
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
                        .onTapGesture {
                            let current = fineTuneCentsDisplay
                             if current < 50 {
                                paramManager.updateFineTuneCents(Double(current + 1))
                             }
                        }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            VoiceView()
        }
        .padding(25)
    }
}
