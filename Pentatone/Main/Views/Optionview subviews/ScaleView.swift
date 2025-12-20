//
//  ScaleView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct ScaleView: View {
    // Current scale and navigation callbacks
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    var onCycleKey: ((Bool) -> Void)? = nil
    
    var body: some View {
        Group {
            ZStack { // Row 3 - Intonation
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleIntonation?(false)
                        }
                    Spacer()
                    Text(currentScale.intonation.rawValue)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleIntonation?(true)
                        }
                }
            }
            ZStack { // Row 4 (top half of image area)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            ZStack { // Row 5 (bottom half of image area)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            .overlay(
                GeometryReader { geometry in
                    Image("JI_CenterMeridian")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geometry.size.height * 2 + 11)
                        .offset(y: -(geometry.size.height + 11))
                        .padding(3)
                }
            )
            ZStack { // Row 6 - Musical Key
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleKey?(false)
                        }
                    Spacer()
                    Text(currentKey.rawValue)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleKey?(true)
                        }
                }
            }
            ZStack { // Row 7 - Celestial
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleCelestial?(false)
                        }
                    Spacer()
                    Text(currentScale.celestial.rawValue)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleCelestial?(true)
                        }
                }
            }
            ZStack { // Row 8 - Terrestrial
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleTerrestrial?(false)
                        }
                    Spacer()
                    Text(currentScale.terrestrial.rawValue)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleTerrestrial?(true)
                        }
                }
            }
            ZStack { // Row 9 - Rotation
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleRotation?(false)
                        }
                    Spacer()
                    Text(currentScale.rotation == 0 ? "0" : "\(currentScale.rotation > 0 ? "+" : "−") \(abs(currentScale.rotation))")
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleRotation?(true)
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
            ScaleView(
                currentScale: ScalesCatalog.centerMeridian_JI,
                currentKey: .D,
                onCycleIntonation: { _ in },
                onCycleCelestial: { _ in },
                onCycleTerrestrial: { _ in },
                onCycleRotation: { _ in },
                onCycleKey: { _ in }
            )
        }
        .padding(25)
    }
}
