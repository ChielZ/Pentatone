//
//  V3 OptionsView.swift
//  Pentatone
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
        case .scale: return "SCALES"
        case .sound: return "SOUNDS"
        case .voice: return "VOICES"
        }
    }
}

struct OptionsView: View {
    @Binding var showingOptions: Bool
    @Binding var currentSubView: OptionsSubView
    
    // Scale navigation
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    var onCycleKey: ((Bool) -> Void)? = nil
    
    // View switching
    var onSwitchToEdit: (() -> Void)? = nil

    var body: some View {
        
        // Compute the note names for the current scale and key
        let noteNamesArray = noteNames(forScale: currentScale, inKey: currentKey)
        
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
                            currentKey: currentKey,
                            onCycleIntonation: onCycleIntonation,
                            onCycleCelestial: onCycleCelestial,
                            onCycleTerrestrial: onCycleTerrestrial,
                            onCycleRotation: onCycleRotation,
                            onCycleKey: onCycleKey
                        )
                    case .sound:
                        SoundView()
                    case .voice:
                        VoiceView(onSwitchToEdit: onSwitchToEdit)
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
                                NoteNameText(
                                    noteName: noteNamesArray[3],
                                    size: 30,
                                    color: Color("KeyColour4")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[4],
                                    size: 30,
                                    color: Color("KeyColour5")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[0],
                                    size: 30,
                                    color: Color("KeyColour1")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[1],
                                    size: 30,
                                    color: Color("KeyColour2")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[2],
                                    size: 30,
                                    color: Color("KeyColour3")
                                )
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
            currentSubView = allCases[nextIndex]
        }
    }
    
    private func previousSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
            currentSubView = allCases[previousIndex]
        }
    }
}

#Preview {
    OptionsView(
        showingOptions: .constant(true),
        currentSubView: .constant(.scale),
        currentScale: ScalesCatalog.centerMeridian_JI,
        currentKey: .D,
        onCycleIntonation: { _ in },
        onCycleCelestial: { _ in },
        onCycleTerrestrial: { _ in },
        onCycleRotation: { _ in },
        onCycleKey: { _ in },
        onSwitchToEdit: {}
    )
}
