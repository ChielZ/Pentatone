//
//  OptionsView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import SwiftUI

// MARK: - Adaptive Font Modifier (Shared across all option views)
struct AdaptiveFont: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let fontName: String
    let baseSize: CGFloat
    
    var adaptiveSize: CGFloat {
        // Regular width and height = iPad in any orientation
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return baseSize
        } else if horizontalSizeClass == .regular {
            // iPhone Plus/Max in landscape
            return baseSize * 0.75
        } else {
            // iPhone in portrait (compact width)
            return baseSize * 0.65
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: adaptiveSize))
    }
}

extension View {
    func adaptiveFont(_ name: String, size: CGFloat) -> some View {
        modifier(AdaptiveFont(fontName: name, baseSize: size))
    }
}

enum OptionsSubView: CaseIterable {
    case scale, sound, voice
    
    var displayName: String {
        switch self {
        case .scale: return "SCALE"
        case .sound: return "SOUND"
        case .voice: return "VOICE"
        }
    }
}

struct OptionsView: View {
    @Binding var showingOptions: Bool
    @State private var currentSubView: OptionsSubView = .scale
    
    // Scale navigation
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil

    var body: some View {
        
        ZStack{
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(9)
            
            VStack(spacing: 11) {
                ZStack{ // Row 1
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    Text("•FOLD•")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("Futura", size: 30)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = false
                        }
                }
                .frame(maxHeight: .infinity)
                
                ZStack{ // Row 2
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("<")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                previousSubView()
                            }
                        Spacer()
                        Text(currentSubView.displayName)
                            .foregroundColor(Color("HighlightColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text(">")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                nextSubView()
                            }
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Rows 3-9: Show the current subview
                Group {
                    switch currentSubView {
                    case .scale:
                        ScaleView(
                            currentScale: currentScale,
                            onCycleIntonation: onCycleIntonation,
                            onCycleCelestial: onCycleCelestial,
                            onCycleTerrestrial: onCycleTerrestrial,
                            onCycleRotation: onCycleRotation
                        )
                    case .sound:
                        SoundView()
                    case .voice:
                        VoiceView()
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack{ // Row 10
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("A")
                                    .foregroundColor(Color("KeyColour4"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("B♭")
                                    .foregroundColor(Color("KeyColour5"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("D")
                                    .foregroundColor(Color("KeyColour1"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("F♯")
                                    .foregroundColor(Color("KeyColour2"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("G")
                                    .foregroundColor(Color("KeyColour3"))
                                    .adaptiveFont("Futura", size: 30)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack{ // Row 11
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour4"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour5"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour1"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour2"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour3"))
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                .frame(maxHeight: .infinity)
            }.padding(19)
            
        }
    }
    
    // MARK: - Navigation Functions
    
    private func nextSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let nextIndex = (currentIndex + 1) % allCases.count
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSubView = allCases[nextIndex]
            }
        }
    }
    
    private func previousSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSubView = allCases[previousIndex]
            }
        }
    }
}

#Preview {
    OptionsView(
        showingOptions: .constant(true),
        currentScale: ScalesCatalog.centerMeridian_JI,
        onCycleIntonation: { _ in },
        onCycleCelestial: { _ in },
        onCycleTerrestrial: { _ in },
        onCycleRotation: { _ in }
    )
}
