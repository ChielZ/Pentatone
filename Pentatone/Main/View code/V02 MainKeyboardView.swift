//
//  MainKeyboardView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 07/12/2025.
//

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

/// Determines the width of the center strip based on device, orientation, and fold state
struct CenterStripConfig {
    let width: CGFloat
    let isIPad: Bool
    let isUnfolded: Bool
    
    static func calculate(geometry: GeometryProxy, isUnfolded: Bool) -> CenterStripConfig {
        let screenWidth = geometry.size.width
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = geometry.size.width > geometry.size.height
        
        let percentage: CGFloat
        
        if isIPad {
            if isLandscape {
                percentage = isUnfolded ? 0.32 : 0.05  // 50% or 5%
            } else {
                percentage = isUnfolded ? 0.65 : 0.07  // 70% or 7%
            }
        } else {
            // iPhone (always portrait for this app)
            percentage = isUnfolded ? 0.9 : 0.125  // 100% or 10%
        }
        
        return CenterStripConfig(width: screenWidth * percentage, isIPad: isIPad, isUnfolded: isUnfolded)
    }
}

struct MainKeyboardView: View {
    // Callbacks provided by the App to change scales
    var onPrevScale: (() -> Void)? = nil
    var onNextScale: (() -> Void)? = nil
    
    // Current scale info and property-based navigation
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    var onCycleKey: ((Bool) -> Void)? = nil
    
    // MARK: - Voice System
    
    /// Keyboard state providing frequency calculations
    var keyboardState: KeyboardState
    
    @State private var showingOptions: Bool = true
    
    // MARK: - Key Color Calculation
    
    /// Calculates the color name for a given key index (0-17) based on current rotation
    /// Keys cycle through 5 colors corresponding to the 5 scale degrees
    /// With rotation, the color assignment shifts to match the new note mapping
    private func keyColor(for keyIndex: Int) -> String {
        // Base color pattern (without rotation): cycles 1,2,3,4,5,1,2,3,4,5...
        // Each key normally maps to: (keyIndex % 5) + 1
        let baseColorIndex = keyIndex % 5
        
        // Apply rotation offset (sign flipped to match note rotation direction)
        // Positive rotation shifts colors to the left (earlier colors move to later keys)
        // Negative rotation shifts colors to the right (later colors move to earlier keys)
        let rotatedColorIndex = (baseColorIndex + currentScale.rotation + 5) % 5
        
        // Map to color name (1-5)
        return "KeyColour\(rotatedColorIndex + 1)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centerConfig = CenterStripConfig.calculate(
                geometry: geometry,
                isUnfolded: showingOptions
            )
            
            ZStack {
                Color("BackgroundColour").ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Left column - Keys
                    VStack {
                        KeyButton(colorName: keyColor(for: 16), keyIndex: 16, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 14), keyIndex: 14, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 12), keyIndex: 12, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 10), keyIndex: 10, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 8), keyIndex: 8, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 6), keyIndex: 6, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 4), keyIndex: 4, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 2), keyIndex: 2, isLeftSide: true, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 0), keyIndex: 0, isLeftSide: true, keyboardState: keyboardState)
                    }
                    .padding(5)
                    
                    // Center column - Navigation strip or Options
                    ZStack {
                        if showingOptions {
                            // Add border for iPad, no border for iPhone
                            if centerConfig.isIPad {
                                
                                OptionsView(
                                    showingOptions: $showingOptions,
                                    currentScale: currentScale,
                                    currentKey: currentKey,
                                    onCycleIntonation: onCycleIntonation,
                                    onCycleCelestial: onCycleCelestial,
                                    onCycleTerrestrial: onCycleTerrestrial,
                                    onCycleRotation: onCycleRotation,
                                    onCycleKey: onCycleKey
                                )
                                       .transition(.opacity)
                            } else {
                                OptionsView(
                                    showingOptions: $showingOptions,
                                    currentScale: currentScale,
                                    currentKey: currentKey,
                                    onCycleIntonation: onCycleIntonation,
                                    onCycleCelestial: onCycleCelestial,
                                    onCycleTerrestrial: onCycleTerrestrial,
                                    onCycleRotation: onCycleRotation,
                                    onCycleKey: onCycleKey
                                )
                                    .transition(.opacity)
                            }
                        } else {
                            NavigationStrip(
                                showingOptions: $showingOptions,
                                onPrevScale: onPrevScale,
                                onNextScale: onNextScale,
                                stripWidth: centerConfig.width
                            )
                            .transition(.opacity)
                        }
                    }
                    .frame(width: centerConfig.width)
                    .animation(.easeInOut(duration: 0.3), value: showingOptions)
                    
                    // Right column - Keys
                    VStack {
                        KeyButton(colorName: keyColor(for: 17), keyIndex: 17, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 15), keyIndex: 15, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 13), keyIndex: 13, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 11), keyIndex: 11, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 9), keyIndex: 9, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 7), keyIndex: 7, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 5), keyIndex: 5, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 3), keyIndex: 3, isLeftSide: false, keyboardState: keyboardState)
                        KeyButton(colorName: keyColor(for: 1), keyIndex: 1, isLeftSide: false, keyboardState: keyboardState)
                    }
                    .padding(5)
                }
            }
            .statusBar(hidden: true)
        }
    }
}

/// The navigation strip shown when the options are folded
private struct NavigationStrip: View {
    @Binding var showingOptions: Bool
    var onPrevScale: (() -> Void)? = nil
    var onNextScale: (() -> Void)? = nil
    let stripWidth: CGFloat
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                
                Text("Pentatone")
                    .font(.custom("SignPainter", size: 42))
                    .foregroundColor(Color("BackgroundColour"))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: stripWidth * 0.95, height: 250, alignment: .center)
                    .rotationEffect(Angle(degrees: 90))
                   
                
                VStack {
                    Text("•UNFOLD•")
                        .font(.custom("Futura Medium", size: 18))
                        .foregroundColor(Color("BackgroundColour"))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(width: stripWidth * 0.7, height: 135, alignment: .center)
                        .rotationEffect(Angle(degrees: 90))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = true
                        }
                    Spacer()
                }
              }
        }
        .padding(5)
    }
}

/// Reusable key button component
private struct KeyButton: View {
    let colorName: String
    let keyIndex: Int  // Which keyboard key this is (0-17)
    let isLeftSide: Bool  // Whether this key is on the left side of the keyboard
    let keyboardState: KeyboardState  // Provides frequencies
    
    @State private var isDimmed = false
    @State private var hasFiredCurrentTouch = false
    @State private var initialTouchX: CGFloat? = nil  // Track initial touch position for relative aftertouch
    
    // Store allocated voice
    @State private var allocatedVoice: PolyphonicVoice? = nil
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(colorName))
                .opacity(isDimmed ? 0.5 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Calculate touch position, inverting for left side
                            // Left side: outer edge = loud/bright, center edge = quiet/dark
                            // Right side: center edge = quiet/dark, outer edge = loud/bright
                            let touchX = isLeftSide 
                                ? value.location.x
                                : geometry.size.width - value.location.x
                            
                            if !hasFiredCurrentTouch {
                                // INITIAL TOUCH - Set amplitude and trigger note
                                hasFiredCurrentTouch = true
                                initialTouchX = touchX
                                
                                handleTrigger(touchX: touchX, viewWidth: geometry.size.width)
                                isDimmed = true
                            } else {
                                // AFTERTOUCH - Update filter cutoff based on X movement from initial position
                                if let initialX = initialTouchX {
                                    handleAftertouch(initialX: initialX, currentX: touchX, viewWidth: geometry.size.width)
                                }
                            }
                        }
                        .onEnded { _ in
                            handleRelease()
                            
                            hasFiredCurrentTouch = false
                            initialTouchX = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeOut(duration: 0.28)) {
                                    isDimmed = false
                                }
                            }
                        }
                )
        }
    }
    
    // MARK: - Voice System Handlers
    
    private func handleTrigger(touchX: CGFloat, viewWidth: CGFloat) {
        // Get frequency from KeyboardState
        guard let frequency = keyboardState.frequencyForKey(at: keyIndex) else {
            print("⚠️ Could not get frequency for key \(keyIndex)")
            return
        }
        
        // Allocate voice from pool
        let voice = voicePool.allocateVoice(frequency: frequency, forKey: keyIndex)
        allocatedVoice = voice
        
        // Normalize touch position to 0...1
        let normalized = max(0.0, min(1.0, touchX / viewWidth))
        
        // Update modulation state with touch position
        // The routable modulation system will handle routing to configured destinations
        voice.modulationState.initialTouchX = normalized
        voice.modulationState.currentTouchX = normalized
        
        print("🎹 Key \(keyIndex): Allocated voice, freq \(String(format: "%.2f", frequency)) Hz, touchX \(String(format: "%.2f", normalized))")
    }
    
    private func handleAftertouch(initialX: CGFloat, currentX: CGFloat, viewWidth: CGFloat) {
        guard let voice = allocatedVoice else { return }
        
        // Update the current touch X position in modulation state
        // The routable modulation system will handle routing to configured destinations
        let normalizedCurrentX = max(0.0, min(1.0, currentX / viewWidth))
        voice.modulationState.currentTouchX = normalizedCurrentX
    }
    
    private func handleRelease() {
        guard allocatedVoice != nil else { return }
        
        // Release voice back to pool
        voicePool.releaseVoice(forKey: keyIndex)
        allocatedVoice = nil
        
        print("🎹 Key \(keyIndex): Released voice")
    }
}

#Preview {
    MainKeyboardView(
        onPrevScale: {},
        onNextScale: {},
        currentScale: ScalesCatalog.centerMeridian_JI,
        currentKey: .D,
        onCycleIntonation: { _ in },
        onCycleCelestial: { _ in },
        onCycleTerrestrial: { _ in },
        onCycleRotation: { _ in },
        onCycleKey: { _ in },
        keyboardState: KeyboardState(scale: ScalesCatalog.centerMeridian_JI, key: .D)
    )
}

