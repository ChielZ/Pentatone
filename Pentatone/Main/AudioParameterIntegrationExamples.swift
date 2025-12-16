//
//  AudioParameterIntegrationExamples.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 16/12/2025.
//
//  This file contains examples and reference code for integrating the
//  AudioParameterManager with your UI. These are NOT meant to be used directly,
//  but serve as a reference when you're ready to add parameter control to your UI.
//

import SwiftUI

// MARK: - Example 1: Enhanced KeyButton with Touch Position → Filter Mapping

/// This example shows how to modify KeyButton to map horizontal touch position
/// to filter cutoff frequency, creating expressive per-key control
private struct EnhancedKeyButton_Example: View {
    let colorName: String
    let voiceIndex: Int  // Which oscillator this key controls (0-17)
    let trigger: () -> Void
    let release: () -> Void
    
    @State private var isDimmed = false
    @State private var hasFiredCurrentTouch = false
    
    private let paramManager = AudioParameterManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(colorName))
                .opacity(isDimmed ? 0.5 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !hasFiredCurrentTouch {
                                hasFiredCurrentTouch = true
                                
                                // Map touch X position to filter cutoff
                                paramManager.mapTouchToFilterCutoff(
                                    voiceIndex: voiceIndex,
                                    touchX: value.location.x,
                                    viewWidth: geometry.size.width,
                                    range: 400...8000  // Custom frequency range
                                )
                                
                                trigger()
                                isDimmed = true
                            }
                        }
                        .onEnded { _ in
                            hasFiredCurrentTouch = false
                            release()
                            
                            // Clear the override so next touch starts fresh from template
                            paramManager.clearVoiceOverride(at: voiceIndex)
                            
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

// MARK: - Example 2: Settings View with Parameter Controls

/// This example shows a simple settings panel that could be added to your OptionsView
/// or shown as a separate sheet for tweaking audio parameters
struct ParameterControlPanel_Example: View {
    private let paramManager = AudioParameterManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Settings")
                .font(.title2)
                .foregroundColor(.white)
            
            // Master Effects Section
            GroupBox {
                VStack(spacing: 15) {
                    // Delay Mix
                    HStack {
                        Text("Delay Mix:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.master.delay.dryWetMix },
                            set: { paramManager.updateDelayMix($0) }
                        ), in: 0...1)
                        Text("\(Int(paramManager.master.delay.dryWetMix * 100))%")
                            .foregroundColor(.white)
                            .frame(width: 50)
                    }
                    
                    // Delay Time
                    HStack {
                        Text("Delay Time:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.master.delay.time },
                            set: { paramManager.updateDelayTime($0) }
                        ), in: 0.1...2.0)
                        Text(String(format: "%.2fs", paramManager.master.delay.time))
                            .foregroundColor(.white)
                            .frame(width: 60)
                    }
                    
                    // Reverb Mix
                    HStack {
                        Text("Reverb Mix:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.master.reverb.dryWetBalance },
                            set: { paramManager.updateReverbMix($0) }
                        ), in: 0...1)
                        Text("\(Int(paramManager.master.reverb.dryWetBalance * 100))%")
                            .foregroundColor(.white)
                            .frame(width: 50)
                    }
                }
            } label: {
                Text("Master Effects")
                    .foregroundColor(.white)
            }
            .background(Color.black.opacity(0.3))
            
            // Voice Parameters Section
            GroupBox {
                VStack(spacing: 15) {
                    // Filter Cutoff
                    HStack {
                        Text("Filter Cutoff:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.voiceTemplate.filter.cutoffFrequency },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.filter
                                params.cutoffFrequency = newValue
                                paramManager.updateTemplateFilter(params)
                            }
                        ), in: 200...12000)
                        Text("\(Int(paramManager.voiceTemplate.filter.cutoffFrequency)) Hz")
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                    
                    // Filter Resonance
                    HStack {
                        Text("Resonance:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.voiceTemplate.filter.resonance },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.filter
                                params.resonance = newValue
                                paramManager.updateTemplateFilter(params)
                            }
                        ), in: 0...0.9)
                        Text(String(format: "%.2f", paramManager.voiceTemplate.filter.resonance))
                            .foregroundColor(.white)
                            .frame(width: 50)
                    }
                    
                    // FM Modulation Index
                    HStack {
                        Text("FM Amount:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.voiceTemplate.oscillator.modulationIndex },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.oscillator
                                params.modulationIndex = newValue
                                paramManager.updateTemplateOscillator(params)
                            }
                        ), in: 0...10)
                        Text(String(format: "%.2f", paramManager.voiceTemplate.oscillator.modulationIndex))
                            .foregroundColor(.white)
                            .frame(width: 50)
                    }
                    
                    // Waveform Selection
                    HStack {
                        Text("Waveform:")
                            .foregroundColor(.white)
                        Picker("Waveform", selection: Binding(
                            get: { paramManager.voiceTemplate.oscillator.waveform },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.oscillator
                                params.waveform = newValue
                                paramManager.updateTemplateOscillator(params)
                            }
                        )) {
                            ForEach(OscillatorWaveform.allCases, id: \.self) { waveform in
                                Text(waveform.displayName).tag(waveform)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            } label: {
                Text("Voice Timbre")
                    .foregroundColor(.white)
            }
            .background(Color.black.opacity(0.3))
            
            // Envelope Section
            GroupBox {
                VStack(spacing: 15) {
                    HStack {
                        Text("Attack:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.voiceTemplate.envelope.attackDuration },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.envelope
                                params.attackDuration = newValue
                                paramManager.updateTemplateEnvelope(params)
                            }
                        ), in: 0.001...2.0)
                        Text(String(format: "%.3fs", paramManager.voiceTemplate.envelope.attackDuration))
                            .foregroundColor(.white)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Release:")
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { paramManager.voiceTemplate.envelope.releaseDuration },
                            set: { newValue in
                                var params = paramManager.voiceTemplate.envelope
                                params.releaseDuration = newValue
                                paramManager.updateTemplateEnvelope(params)
                            }
                        ), in: 0.001...3.0)
                        Text(String(format: "%.3fs", paramManager.voiceTemplate.envelope.releaseDuration))
                            .foregroundColor(.white)
                            .frame(width: 60)
                    }
                }
            } label: {
                Text("Envelope")
                    .foregroundColor(.white)
            }
            .background(Color.black.opacity(0.3))
        }
        .padding()
        .background(Color("BackgroundColour"))
    }
}

// MARK: - Example 3: Preset Creation and Loading

/// This example shows how to create, save, and load presets
struct PresetManagerExample {
    private let paramManager = AudioParameterManager.shared
    
    /// Create a preset from current settings
    func saveCurrentAsPreset(named name: String) {
        let preset = paramManager.createPreset(named: name)
        // TODO: Save to UserDefaults, file, or Core Data
        // Example: UserDefaults.standard.set(try? JSONEncoder().encode(preset), forKey: "preset_\(preset.id)")
        print("Created preset: \(preset.name)")
    }
    
    /// Load a preset
    func loadPreset(_ preset: AudioParameterSet) {
        paramManager.loadPreset(preset)
        print("Loaded preset: \(preset.name)")
    }
    
    /// Example: Create some factory presets
    func createFactoryPresets() -> [AudioParameterSet] {
        var presets: [AudioParameterSet] = []
        
        // Bright preset - high filter, short release, triangle wave
        let brightVoice = VoiceParameters(
            oscillator: OscillatorParameters(
                carrierMultiplier: 1.0,
                modulatingMultiplier: 2.0,
                modulationIndex: 1.2,
                amplitude: 0.15,
                waveform: .triangle  // Triangle for bright, edgy sound
            ),
            filter: FilterParameters(cutoffFrequency: 10_000, resonance: 0.2),
            envelope: EnvelopeParameters(
                attackDuration: 0.01,
                decayDuration: 0.3,
                sustainLevel: 0.0,
                releaseDuration: 0.05
            ),
            pan: .default
        )
        
        let brightPreset = AudioParameterSet(
            id: UUID(),
            name: "Bright & Punchy",
            voiceTemplate: brightVoice,
            master: .default,
            createdAt: Date()
        )
        presets.append(brightPreset)
        
        // Deep Bass preset - low filter, long release, square wave
        let deepVoice = VoiceParameters(
            oscillator: OscillatorParameters(
                carrierMultiplier: 1.0,
                modulatingMultiplier: 1.5,
                modulationIndex: 0.5,
                amplitude: 0.2,
                waveform: .square  // Square for thick, powerful bass
            ),
            filter: FilterParameters(cutoffFrequency: 400, resonance: 0.4),
            envelope: EnvelopeParameters(
                attackDuration: 0.05,
                decayDuration: 1.0,
                sustainLevel: 0.0,
                releaseDuration: 0.8
            ),
            pan: .default
        )
        
        let deepPreset = AudioParameterSet(
            id: UUID(),
            name: "Deep Bass",
            voiceTemplate: deepVoice,
            master: MasterParameters(
                delay: DelayParameters(time: 0.6, feedback: 0.3, dryWetMix: 0.3, pingPong: true),
                reverb: ReverbParameters(feedback: 0.8, cutoffFrequency: 5000, dryWetBalance: 0.5)
            ),
            createdAt: Date()
        )
        presets.append(deepPreset)
        
        return presets
    }
}

// MARK: - Example 4: 2D Touch Control (Advanced)

/// This example shows how you could create a 2D touch pad that controls
/// multiple parameters simultaneously (X = filter, Y = resonance)
private struct TouchPad2D_Example: View {
    let voiceIndex: Int
    let onTrigger: () -> Void
    let onRelease: () -> Void
    
    @State private var isActive = false
    private let paramManager = AudioParameterManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Visual feedback gradient
                LinearGradient(
                    colors: [.blue, .purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isActive ? 0.7 : 0.3)
                
                Text("2D Control Pad")
                    .foregroundColor(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isActive {
                            isActive = true
                            onTrigger()
                        }
                        
                        // X = Filter Cutoff (200 - 12000 Hz)
                        paramManager.mapTouchToFilterCutoff(
                            voiceIndex: voiceIndex,
                            touchX: value.location.x,
                            viewWidth: geometry.size.width
                        )
                        
                        // Y = Resonance (0 - 0.9)
                        paramManager.mapTouchToResonance(
                            voiceIndex: voiceIndex,
                            touchY: value.location.y,
                            viewHeight: geometry.size.height
                        )
                    }
                    .onEnded { _ in
                        isActive = false
                        onRelease()
                        paramManager.clearVoiceOverride(at: voiceIndex)
                    }
            )
        }
    }
}

// MARK: - Example 5: Simple Integration with Existing KeyButton

/// This shows the minimal changes needed to add touch position control
/// to your existing KeyButton implementation
private struct MinimalIntegration_Example {
    
    // Add this to your KeyButton's DragGesture onChanged:
    func onKeyTouchChanged(voiceIndex: Int, touchX: CGFloat, viewWidth: CGFloat) {
        // Just add this one line to map touch position to filter
        AudioParameterManager.shared.mapTouchToFilterCutoff(
            voiceIndex: voiceIndex,
            touchX: touchX,
            viewWidth: viewWidth
        )
    }
    
    // Add this to your KeyButton's DragGesture onEnded:
    func onKeyTouchEnded(voiceIndex: Int) {
        // Clear the override so the voice returns to template settings
        AudioParameterManager.shared.clearVoiceOverride(at: voiceIndex)
    }
}

// MARK: - Preview

#Preview("Parameter Control Panel") {
    ParameterControlPanel_Example()
}
