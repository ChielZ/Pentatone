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
    
    // MARK: - Phase 3: New Voice System
    
    /// Keyboard state providing frequency calculations
    var keyboardState: KeyboardState
    
    /// Feature flag to switch between old and new voice systems
    /// Set to false to use old oscillator01-18, true to use new VoicePool
    var useNewVoiceSystem: Bool = true
    
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
                        KeyButton(colorName: keyColor(for: 16), keyIndex: 16, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator17.trigger() }, oldSystemRelease: { oscillator17.release() })
                        KeyButton(colorName: keyColor(for: 14), keyIndex: 14, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator15.trigger() }, oldSystemRelease: { oscillator15.release() })
                        KeyButton(colorName: keyColor(for: 12), keyIndex: 12, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator13.trigger() }, oldSystemRelease: { oscillator13.release() })
                        KeyButton(colorName: keyColor(for: 10), keyIndex: 10, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator11.trigger() }, oldSystemRelease: { oscillator11.release() })
                        KeyButton(colorName: keyColor(for: 8), keyIndex: 8, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator09.trigger() }, oldSystemRelease: { oscillator09.release() })
                        KeyButton(colorName: keyColor(for: 6), keyIndex: 6, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator07.trigger() }, oldSystemRelease: { oscillator07.release() })
                        KeyButton(colorName: keyColor(for: 4), keyIndex: 4, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator05.trigger() }, oldSystemRelease: { oscillator05.release() })
                        KeyButton(colorName: keyColor(for: 2), keyIndex: 2, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator03.trigger() }, oldSystemRelease: { oscillator03.release() })
                        KeyButton(colorName: keyColor(for: 0), keyIndex: 0, isLeftSide: true, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator01.trigger() }, oldSystemRelease: { oscillator01.release() })
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
                        KeyButton(colorName: keyColor(for: 17), keyIndex: 17, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator18.trigger() }, oldSystemRelease: { oscillator18.release() })
                        KeyButton(colorName: keyColor(for: 15), keyIndex: 15, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator16.trigger() }, oldSystemRelease: { oscillator16.release() })
                        KeyButton(colorName: keyColor(for: 13), keyIndex: 13, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator14.trigger() }, oldSystemRelease: { oscillator14.release() })
                        KeyButton(colorName: keyColor(for: 11), keyIndex: 11, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator12.trigger() }, oldSystemRelease: { oscillator12.release() })
                        KeyButton(colorName: keyColor(for: 9), keyIndex: 9, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator10.trigger() }, oldSystemRelease: { oscillator10.release() })
                        KeyButton(colorName: keyColor(for: 7), keyIndex: 7, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator08.trigger() }, oldSystemRelease: { oscillator08.release() })
                        KeyButton(colorName: keyColor(for: 5), keyIndex: 5, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator06.trigger() }, oldSystemRelease: { oscillator06.release() })
                        KeyButton(colorName: keyColor(for: 3), keyIndex: 3, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator04.trigger() }, oldSystemRelease: { oscillator04.release() })
                        KeyButton(colorName: keyColor(for: 1), keyIndex: 1, isLeftSide: false, keyboardState: keyboardState, useNewVoiceSystem: useNewVoiceSystem, oldSystemTrigger: { oscillator02.trigger() }, oldSystemRelease: { oscillator02.release() })
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
    let useNewVoiceSystem: Bool  // Feature flag
    
    // Old system callbacks (only used when useNewVoiceSystem = false)
    let oldSystemTrigger: (() -> Void)?
    let oldSystemRelease: (() -> Void)?
    
    @State private var isDimmed = false
    @State private var hasFiredCurrentTouch = false
    @State private var initialTouchX: CGFloat? = nil  // Track initial touch position for relative aftertouch
    @State private var lastAftertouchX: CGFloat? = nil  // Track last processed aftertouch position
    
    // NEW: Store allocated voice for new system
    @State private var allocatedVoice: PolyphonicVoice? = nil
    
    // NEW: Track last smoothed cutoff for aftertouch (matches old system's lastFilterCutoffs)
    @State private var lastSmoothedCutoff: Double? = nil
    
    // Minimum movement threshold (in points) before aftertouch responds
    private let movementThreshold: CGFloat = 1.0
    
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
                                lastAftertouchX = touchX  // Initialize for threshold calculation
                                
                                if useNewVoiceSystem {
                                    // NEW SYSTEM: Allocate voice from pool
                                    handleNewSystemTrigger(touchX: touchX, viewWidth: geometry.size.width)
                                } else {
                                    // OLD SYSTEM: Use hard-coded oscillator
                                    handleOldSystemTrigger(touchX: touchX, viewWidth: geometry.size.width)
                                }
                                
                                isDimmed = true
                            } else {
                                // AFTERTOUCH - Update filter cutoff based on X movement from initial position
                                // Only respond if movement exceeds threshold
                                if let lastX = lastAftertouchX, abs(touchX - lastX) >= movementThreshold,
                                   let initialX = initialTouchX {
                                    lastAftertouchX = touchX
                                    
                                    if useNewVoiceSystem {
                                        // NEW SYSTEM: Update allocated voice filter
                                        handleNewSystemAftertouch(initialX: initialX, currentX: touchX, viewWidth: geometry.size.width)
                                    } else {
                                        // OLD SYSTEM: Update oscillator filter via parameter manager
                                        AudioParameterManager.shared.mapAftertouchToFilterCutoffSmoothed(
                                            voiceIndex: keyIndex,
                                            initialTouchX: initialX,
                                            currentTouchX: touchX,
                                            viewWidth: geometry.size.width
                                        )
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            if useNewVoiceSystem {
                                // NEW SYSTEM: Release allocated voice
                                handleNewSystemRelease()
                            } else {
                                // OLD SYSTEM: Release oscillator
                                handleOldSystemRelease()
                            }
                            
                            hasFiredCurrentTouch = false
                            initialTouchX = nil
                            lastAftertouchX = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeOut(duration: 0.28)) {
                                    isDimmed = false
                                }
                            }
                        }
                )
        }
    }
    
    // MARK: - New Voice System Handlers
    
    private func handleNewSystemTrigger(touchX: CGFloat, viewWidth: CGFloat) {
        // Get frequency from KeyboardState
        guard let frequency = keyboardState.frequencyForKey(at: keyIndex) else {
            print("⚠️ Could not get frequency for key \(keyIndex)")
            return
        }
        
        // Allocate voice from pool
        let voice = voicePool.allocateVoice(frequency: frequency, forKey: keyIndex)
        allocatedVoice = voice
        
        // Reset filter to template default (matching old system behavior)
        let templateCutoff = AudioParameterManager.shared.voiceTemplate.filter.cutoffFrequency
        voice.filter.cutoffFrequency = AUValue(templateCutoff)
        
        // Clear smoothing state (start fresh for new note)
        lastSmoothedCutoff = nil
        
        // Use the same amplitude mapping as the old system
        // Normalize touch position to 0...1
        let normalized = max(0.0, min(1.0, touchX / viewWidth))
        
        // Apply amplitude to voice (matching old system behavior)
        voice.oscLeft.amplitude = AUValue(normalized)
        voice.oscRight.amplitude = AUValue(normalized)
        
        print("🎹 Key \(keyIndex): Allocated voice, freq \(String(format: "%.2f", frequency)) Hz, amp \(String(format: "%.2f", normalized))")
    }
    
    private func handleNewSystemAftertouch(initialX: CGFloat, currentX: CGFloat, viewWidth: CGFloat) {
        guard let voice = allocatedVoice else { return }
        
        // Use the EXACT same algorithm as the old system's mapAftertouchToFilterCutoffSmoothed
        
        // Get the base cutoff from template (what the note started with)
        let baseCutoff = AudioParameterManager.shared.voiceTemplate.filter.cutoffFrequency
        
        // Calculate movement delta from initial touch
        let movementDelta = currentX - initialX
        
        // Sensitivity in octaves per point (matching old system: 2.5)
        let sensitivity = 2.5
        let octaveChange = Double(movementDelta) * (sensitivity / 100.0)
        
        // Apply exponential scaling (logarithmic frequency response)
        var targetCutoff = baseCutoff * pow(2.0, octaveChange)
        
        // Clamp to valid range (matching old system: 500-12000 Hz)
        let range = 500.0...12_000.0
        targetCutoff = max(range.lowerBound, min(range.upperBound, targetCutoff))
        
        // Get current cutoff for smoothing
        let currentCutoff: Double
        if let lastCutoff = lastSmoothedCutoff {
            currentCutoff = lastCutoff
        } else {
            // First aftertouch - start from base cutoff
            currentCutoff = baseCutoff
        }
        
        // Apply linear interpolation (lerp) for smoothing
        // Matching old system: smoothingFactor = 0.5
        let smoothingFactor = 0.5
        let interpolationAmount = 1.0 - smoothingFactor
        let smoothedCutoff = currentCutoff + (targetCutoff - currentCutoff) * interpolationAmount
        
        // Store for next iteration (maintains smoothing state)
        lastSmoothedCutoff = smoothedCutoff
        
        // Apply to voice filter
        voice.filter.cutoffFrequency = AUValue(smoothedCutoff)
        
        // Debug (throttled)
        // print("🎛️ Key \(keyIndex): Aftertouch cutoff \(String(format: "%.0f", smoothedCutoff)) Hz")
    }
    
    private func handleNewSystemRelease() {
        guard let voice = allocatedVoice else { return }
        
        // Release voice back to pool
        voicePool.releaseVoice(forKey: keyIndex)
        allocatedVoice = nil
        
        // Clear smoothing state (matching old system's lastFilterCutoffs cleanup)
        lastSmoothedCutoff = nil
        
        print("🎹 Key \(keyIndex): Released voice")
    }
    
    // MARK: - Old Voice System Handlers
    
    private func handleOldSystemTrigger(touchX: CGFloat, viewWidth: CGFloat) {
        // Reset filter cutoff to template default
        AudioParameterManager.shared.resetVoiceFilterToTemplate(at: keyIndex)
        
        // Clear the voice override so next touch uses template settings
        AudioParameterManager.shared.clearVoiceOverride(at: keyIndex)
        
        // Map initial touch X position to amplitude
        AudioParameterManager.shared.mapTouchToAmplitude(
            voiceIndex: keyIndex,
            touchX: touchX,
            viewWidth: viewWidth
        )
        
        // Trigger the oscillator
        oldSystemTrigger?()
    }
    
    private func handleOldSystemRelease() {
        // Release the oscillator
        oldSystemRelease?()
        
        // Note: Voice override clearing is handled separately in old system
        // AudioParameterManager.shared.clearVoiceOverride(at: keyIndex)
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
        keyboardState: KeyboardState(scale: ScalesCatalog.centerMeridian_JI, key: .D),
        useNewVoiceSystem: true
    )
}

