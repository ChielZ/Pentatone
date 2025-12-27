//
//  V2 MainKeyboardView.swift
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

/// Enum to track which main view is currently showing
enum MainViewMode {
    case options
    case edit
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
    
    @State private var showingOptions: Bool = false
    @State private var currentMainView: MainViewMode = .options
    @State private var currentOptionsSubView: OptionsSubView = .scale
    
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
                    
                    // Center column - Navigation strip or Options/Edit
                    ZStack {
                        if showingOptions {
                            // Switch between OptionsView and EditView based on currentMainView
                            switch currentMainView {
                            case .options:
                                OptionsView(
                                    showingOptions: $showingOptions,
                                    currentSubView: $currentOptionsSubView,
                                    currentScale: currentScale,
                                    currentKey: currentKey,
                                    onCycleIntonation: onCycleIntonation,
                                    onCycleCelestial: onCycleCelestial,
                                    onCycleTerrestrial: onCycleTerrestrial,
                                    onCycleRotation: onCycleRotation,
                                    onCycleKey: onCycleKey,
                                    onSwitchToEdit: {
                                        currentMainView = .edit
                                    }
                                )
                                .transition(.opacity)
                                
                            case .edit:
                                EditView(
                                    showingOptions: $showingOptions,
                                    onSwitchToOptions: {
                                        currentMainView = .options
                                    }
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
                    .animation(.easeInOut(duration: 0.2), value: currentMainView)
                    
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

/// Reusable key button component with direct UIKit touch handling for minimal latency
private struct KeyButton: View {
    let colorName: String
    let keyIndex: Int  // Which keyboard key this is (0-17)
    let isLeftSide: Bool  // Whether this key is on the left side of the keyboard
    let keyboardState: KeyboardState  // Provides frequencies
    
    @State private var isDimmed = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color(colorName))
                    .opacity(isDimmed ? 0.5 : 1.0)
                
                // UIKit touch handler overlay - transparent, handles all touches
                KeyTouchHandler(
                    keyIndex: keyIndex,
                    isLeftSide: isLeftSide,
                    keyboardState: keyboardState,
                    viewWidth: geometry.size.width,
                    onTouchBegan: {
                        // UI update (low priority, happens on main thread after note triggers)
                        isDimmed = true
                    },
                    onTouchEnded: {
                        // UI update (low priority)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            withAnimation(.easeOut(duration: 0.28)) {
                                isDimmed = false
                            }
                        }
                    }
                )
            }
        }
    }
}


// MARK: - UIKit Touch Handler

/// UIKit-based touch handler for minimal latency note triggering
/// This bypasses SwiftUI's gesture system to get direct access to hardware touch events
/// Priority order: 1) Trigger audio (immediate), 2) Update modulation (5ms), 3) Update UI (next frame)
private struct KeyTouchHandler: UIViewRepresentable {
    let keyIndex: Int
    let isLeftSide: Bool
    let keyboardState: KeyboardState
    let viewWidth: CGFloat
    let onTouchBegan: () -> Void
    let onTouchEnded: () -> Void
    
    func makeUIView(context: Context) -> TouchHandlingView {
        let view = TouchHandlingView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false  // One touch per key
        view.touchHandler = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: TouchHandlingView, context: Context) {
        // Update coordinator with latest values
        context.coordinator.keyIndex = keyIndex
        context.coordinator.isLeftSide = isLeftSide
        context.coordinator.keyboardState = keyboardState
        context.coordinator.viewWidth = viewWidth
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            keyIndex: keyIndex,
            isLeftSide: isLeftSide,
            keyboardState: keyboardState,
            viewWidth: viewWidth,
            onTouchBegan: onTouchBegan,
            onTouchEnded: onTouchEnded
        )
    }
    
    // MARK: - Coordinator
    
    class Coordinator {
        var keyIndex: Int
        var isLeftSide: Bool
        var keyboardState: KeyboardState
        var viewWidth: CGFloat
        let onTouchBegan: () -> Void
        let onTouchEnded: () -> Void
        
        // Touch tracking state
        private var allocatedVoice: PolyphonicVoice?
        private var initialTouchX: CGFloat?
        
        init(
            keyIndex: Int,
            isLeftSide: Bool,
            keyboardState: KeyboardState,
            viewWidth: CGFloat,
            onTouchBegan: @escaping () -> Void,
            onTouchEnded: @escaping () -> Void
        ) {
            self.keyIndex = keyIndex
            self.isLeftSide = isLeftSide
            self.keyboardState = keyboardState
            self.viewWidth = viewWidth
            self.onTouchBegan = onTouchBegan
            self.onTouchEnded = onTouchEnded
        }
        
        // MARK: - Touch Handlers (called from TouchHandlingView)
        
        func handleTouchBegan(at location: CGPoint) {
            // PRIORITY 1: TRIGGER AUDIO (happens immediately, on touch thread)
            
            // Calculate touch position, inverting for left side
            let touchX = isLeftSide ? location.x : viewWidth - location.x
            initialTouchX = touchX
            
            // Get frequency from KeyboardState
            guard let frequency = keyboardState.frequencyForKey(at: keyIndex) else {
                print("⚠️ Could not get frequency for key \(keyIndex)")
                return
            }
            
            // Normalize touch position to 0...1
            let normalized = max(0.0, min(1.0, touchX / viewWidth))
            
            // Allocate voice from pool
            let voice = voicePool.allocateVoice(frequency: frequency, forKey: keyIndex)
            allocatedVoice = voice
            
            // Store touch position in modulation state (for aftertouch, which is relative)
            voice.modulationState.initialTouchX = normalized
            voice.modulationState.currentTouchX = normalized
            
            // APPLY INITIAL TOUCH AS TRIGGER PARAMETER (zero-latency)
            // This sets the starting value of the parameter based on touch position
            // Read configuration from voice modulation parameters
            let touchInitial = voice.voiceModulation.touchInitial
            
            if touchInitial.isEnabled {
                applyInitialTouchParameter(
                    normalized: normalized,
                    destination: touchInitial.destination,
                    amount: touchInitial.amount,
                    to: voice
                )
            }
            
            print("🎹 Key \(keyIndex): Touch at \(String(format: "%.2f", normalized)), freq \(String(format: "%.2f", frequency)) Hz")
            
            // PRIORITY 3: UPDATE UI (happens on main thread, can wait)
            DispatchQueue.main.async { [weak self] in
                self?.onTouchBegan()
            }
        }
        
        func handleTouchMoved(to location: CGPoint) {
            // PRIORITY 2: UPDATE MODULATION (control-rate timer will pick this up within 5ms)
            
            guard allocatedVoice != nil else { return }
            
            // Calculate current touch position
            let currentX = isLeftSide ? location.x : viewWidth - location.x
            let normalizedCurrentX = max(0.0, min(1.0, currentX / viewWidth))
            
            // Update modulation state - the control-rate timer will apply aftertouch
            // Aftertouch is calculated relative to initialTouchX (already stored)
            allocatedVoice?.modulationState.currentTouchX = normalizedCurrentX
            
            // Note: Aftertouch modulation is now handled entirely at control rate (200 Hz)
            // This provides smooth, glitch-free parameter changes with 5ms latency
        }
        
        func handleTouchEnded() {
            // PRIORITY 1: RELEASE AUDIO (happens immediately)
            
            guard allocatedVoice != nil else { return }
            
            // Release voice back to pool
            voicePool.releaseVoice(forKey: keyIndex)
            allocatedVoice = nil
            initialTouchX = nil
            
            print("🎹 Key \(keyIndex): Released")
            
            // PRIORITY 3: UPDATE UI (happens on main thread, can wait)
            DispatchQueue.main.async { [weak self] in
                self?.onTouchEnded()
            }
        }
        
        // MARK: - Initial Touch Parameter Application
        
        /// Applies initial touch as a trigger parameter (zero-latency)
        /// This sets the starting value of a parameter based on touch position
        /// - Parameters:
        ///   - normalized: Normalized touch X position (0.0 - 1.0)
        ///   - destination: The parameter to modulate
        ///   - amount: Modulation amount
        ///   - voice: The voice to apply to
        private func applyInitialTouchParameter(
            normalized: Double,
            destination: ModulationDestination,
            amount: Double,
            to voice: PolyphonicVoice
        ) {
            // Only apply to voice-level destinations
            guard destination.isVoiceLevel else { return }
            
            // Get base value for the destination
            let baseValue = getBaseValueForTrigger(destination: destination, voice: voice)
            
            // Calculate modulated value using envelope modulation logic (unipolar)
            // Touch position (0.0 - 1.0) acts like an envelope value
            let modulated = ModulationRouter.applyEnvelopeModulation(
                baseValue: baseValue,
                envelopeValue: normalized,
                amount: amount,
                destination: destination
            )
            
            // Apply directly to destination for zero-latency response
            applyValueDirectly(modulated, to: destination, voice: voice)
        }
        
        /// Gets the base value for a destination at trigger time
        private func getBaseValueForTrigger(destination: ModulationDestination, voice: PolyphonicVoice) -> Double {
            switch destination {
            case .oscillatorAmplitude:
                return 0.1  // Default amplitude
            case .filterCutoff:
                return 1200.0  // Default filter cutoff
            case .modulationIndex:
                return Double(voice.oscLeft.modulationIndex)
            case .modulatingMultiplier:
                return Double(voice.oscLeft.modulatingMultiplier)
            case .oscillatorBaseFrequency:
                return voice.currentFrequency
            case .stereoSpreadAmount:
                return voice.detuneMode == .proportional ? voice.frequencyOffsetRatio : voice.frequencyOffsetHz
            case .voiceLFOFrequency:
                return voice.voiceModulation.voiceLFO.frequency
            case .voiceLFOAmount:
                return voice.voiceModulation.voiceLFO.amount
            case .delayTime, .delayMix:
                return 0.0  // These shouldn't be targeted by initial touch
            }
        }
        
        /// Applies a value directly to a destination (zero-latency)
        private func applyValueDirectly(_ value: Double, to destination: ModulationDestination, voice: PolyphonicVoice) {
            guard value.isFinite else { return }
            
            switch destination {
            case .oscillatorAmplitude:
                let clamped = max(0.0, min(1.0, value))
                voice.modulationState.baseAmplitude = clamped
                // Use explicit zero-duration ramp to avoid slides between notes
                voice.oscLeft.$amplitude.ramp(to: AUValue(clamped), duration: 0)
                voice.oscRight.$amplitude.ramp(to: AUValue(clamped), duration: 0)
                
            case .filterCutoff:
                let clamped = max(20.0, min(20000.0, value))
                voice.modulationState.baseFilterCutoff = clamped
                // Use explicit zero-duration ramp to avoid slides between notes
                voice.filter.$cutoffFrequency.ramp(to: AUValue(clamped), duration: 0)
                
            case .modulationIndex:
                let clamped = max(0.0, min(10.0, value))
                // Use explicit zero-duration ramp to avoid slides between notes
                voice.oscLeft.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
                voice.oscRight.$modulationIndex.ramp(to: AUValue(clamped), duration: 0)
                
            case .modulatingMultiplier:
                let clamped = max(0.1, min(20.0, value))
                // Use explicit zero-duration ramp to avoid slides between notes
                voice.oscLeft.$modulatingMultiplier.ramp(to: AUValue(clamped), duration: 0)
                voice.oscRight.$modulatingMultiplier.ramp(to: AUValue(clamped), duration: 0)
                
            case .oscillatorBaseFrequency:
                voice.setFrequency(value)
                
            case .stereoSpreadAmount:
                if voice.detuneMode == .proportional {
                    voice.frequencyOffsetRatio = value
                } else {
                    voice.frequencyOffsetHz = value
                }
                
            case .voiceLFOFrequency:
                voice.voiceModulation.voiceLFO.frequency = max(0.01, min(10.0, value))
                
            case .voiceLFOAmount:
                voice.voiceModulation.voiceLFO.amount = max(0.0, min(1.0, value))
                
            case .delayTime, .delayMix:
                break  // These are global, not voice-level
            }
        }
    }
    
    // MARK: - Touch Handling UIView
    
    class TouchHandlingView: UIView {
        weak var touchHandler: Coordinator?
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            // Call handler IMMEDIATELY on touch thread (no dispatch, no delay)
            touchHandler?.handleTouchBegan(at: location)
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            // Call handler IMMEDIATELY on touch thread
            touchHandler?.handleTouchMoved(to: location)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            // Call handler IMMEDIATELY on touch thread
            touchHandler?.handleTouchEnded()
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            // Treat cancellation same as ended
            touchHandler?.handleTouchEnded()
        }
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

