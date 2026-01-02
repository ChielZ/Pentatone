//
//
//  A5 AudioEngine.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AVFAudio
import DunneAudioKit

// Shared engine and mixer for the entire app (single engine architecture)
let sharedEngine = AudioEngine()
private(set) var fxDelay: StereoDelay!
private(set) var fxReverb: CostelloReverb!
private(set) var outputMixer: Mixer!

// MARK: - Polyphonic Voice Pool Architecture
// New polyphonic voice pool with dynamic voice allocation
private(set) var voicePool: VoicePool!


// Configure and activate the audio session explicitly (iOS)
enum AudioSessionManager {
    static func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Set preferred sample rate BEFORE activating session
            let desiredSampleRate: Double
            if #available(iOS 18.0, *) {
                desiredSampleRate = 48_000
            } else {
                desiredSampleRate = 44_100
            }
            
            try session.setPreferredSampleRate(desiredSampleRate)
            try session.setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure AVAudioSession: \(error)")
        }
    }
}



// Engine manager to control the shared engine lifecycle
enum EngineManager {
    private static var started = false

    static func startIfNeeded() {
        guard !started else { return }
        
        AudioSessionManager.configureSession()
        
        // Get default parameters from parameter manager
        let masterParams = MasterParameters.default
        let voiceParams = VoiceParameters.default
        
        // Set currentPolyphony based on voice mode
        switch masterParams.voiceMode {
        case .monophonic:
            currentPolyphony = 1
        case .polyphonic:
            currentPolyphony = nominalPolyphony
        }
        
        // Create voice pool with current polyphony
        voicePool = VoicePool(voiceCount: currentPolyphony)
        
        // Set initial voice mixer volume (pre-FX)
        voicePool.voiceMixer.volume = AUValue(masterParams.output.preVolume)
        
        // Apply global LFO parameters from master defaults
        voicePool.updateGlobalLFO(masterParams.globalLFO)
        
        // Apply voice modulation parameters to all voices
        voicePool.updateAllVoiceModulation(voiceParams.modulation)
        
        // Delay processes the voice pool output - initialized with parameters
        fxDelay = StereoDelay(
                                voicePool.voiceMixer,
                                time: AUValue(masterParams.delay.timeInSeconds(tempo: masterParams.tempo)),
                                feedback: AUValue(masterParams.delay.feedback),
                                dryWetMix: AUValue(1-masterParams.delay.dryWetMix),
                                pingPong: masterParams.delay.pingPong,
                                maximumDelayTime: 2
                                )
        
        // Reverb processes the delayed signal - initialized with parameters
        fxReverb = CostelloReverb(
                                fxDelay,
                                balance: AUValue(masterParams.reverb.balance),
                                feedback: AUValue(masterParams.reverb.feedback),
                                cutoffFrequency: AUValue(masterParams.reverb.cutoffFrequency)
                                
                                )
        
        // OutputMixer for control of post volume
        outputMixer = Mixer(fxReverb)
        outputMixer.volume = AUValue(masterParams.output.volume)
        
        
        // Output mixer is connected to final output
        sharedEngine.output = outputMixer
        
        do {
            try sharedEngine.start()
            started = true
            
            // Initialize voice pool after engine starts
            voicePool.initialize()
            
            // Pass FX node references to voice pool for global LFO modulation
            voicePool.setFXNodes(delay: fxDelay, reverb: fxReverb)
            
            // Initialize base delay time for LFO modulation
            let initialDelayTime = masterParams.delay.timeInSeconds(tempo: masterParams.tempo)
            voicePool.updateBaseDelayTime(initialDelayTime)
            
            // Start modulation system (Phase 5B)
            voicePool.startModulation()
            
        } catch {
            assertionFailure("Failed to start AudioKit engine: \(error)")
        }
    }
    
    static func startEngine() throws {
        startIfNeeded()
    }
}
/*
// ***************************
// Code below is for testing purposes only (envelope test code in audio engine overhaul folder needs to be uncommented for this to work)

import SwiftUI

// MARK: - Preview

#Preview("Voice Pool Test") {
    VoicePoolTestView()
}

// MARK: - Voice Pool Test View

/// Test view for the polyphonic voice pool architecture
struct VoicePoolTestView: View {
    @State private var isAudioReady = false
    @State private var statusMessage = "Initializing audio..."
    @State private var currentScaleIndex = 0
    
    // Phase 2: KeyboardState for frequency management
    @StateObject private var keyboardState = KeyboardState()
    
    // Detune controls
    @State private var detuneMode: DetuneMode = .proportional
    @State private var frequencyOffsetRatio: Double = 1.0     // Proportional mode: 1.0 to 1.01
    @State private var frequencyOffsetHz: Double = 0.0        // Constant mode: 0 to 2.5 Hz
    
    // Phase 5B: Envelope test presets
    @State private var currentEnvelopePreset: String = "None"
    
    // Test scale (synced with keyboardState)
    private var testScale: Scale {
        keyboardState.currentScale
    }
    
    // Test frequencies from keyboardState
    private var testFrequencies: [Double] {
        Array(keyboardState.keyFrequencies.prefix(9))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BackgroundColour").ignoresSafeArea()
                
                if isAudioReady {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Text("Voice Pool Test")
                                .font(.title)
                                .foregroundColor(Color("HighlightColour"))
                            
                            Text("Polyphonic Voice Allocation")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(testScale.name)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Button("Previous Scale") {
                                    changeScale(by: -1)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(currentScaleIndex == 0)
                                
                                Button("Next Scale") {
                                    changeScale(by: 1)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(currentScaleIndex >= ScalesCatalog.all.count - 1)
                            }
                            
                            // KeyboardState info
                            HStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Key: \(keyboardState.currentKey.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Intonation: \(keyboardState.currentScale.intonation.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Cycle Key") {
                                    keyboardState.cycleKey(forward: true)
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        
                        // Voice Pool Status
                        VStack(spacing: 10) {
                            Text("Voice Pool Status")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(voicePool.voiceCount)")
                                        .font(.title2)
                                        .foregroundColor(Color("HighlightColour"))
                                    Text("Total Voices")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("\(voicePool.activeVoiceCount)")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("\(voicePool.voiceCount - voicePool.activeVoiceCount)")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        }
                        
                        // Stereo Spread Control
                        VStack(spacing: 15) {
                            Text("Stereo Spread")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Detune mode toggle
                            Picker("Detune Mode", selection: $detuneMode) {
                                ForEach(DetuneMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: detuneMode) { newMode in
                                voicePool.updateDetuneMode(newMode)
                            }
                            
                            // Mode description
                            Text(detuneMode.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            // Slider for current mode
                            if detuneMode == .proportional {
                                // Proportional mode: cents-based
                                HStack {
                                    Text("Offset:")
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Slider(value: $frequencyOffsetRatio, in: 1.0...1.01) { _ in
                                        voicePool.updateFrequencyOffsetRatio(frequencyOffsetRatio)
                                    }
                                    
                                    Text("\(centsSpreadProportional, specifier: "%.1f") cents")
                                        .foregroundColor(.white)
                                        .frame(width: 80)
                                }
                            } else {
                                // Constant mode: Hz-based
                                HStack {
                                    Text("Offset:")
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Slider(value: $frequencyOffsetHz, in: 0...2.5) { _ in
                                        voicePool.updateFrequencyOffsetHz(frequencyOffsetHz)
                                    }
                                    
                                    Text("\(beatRateConstant, specifier: "%.1f") Hz")
                                        .foregroundColor(.white)
                                        .frame(width: 80)
                                }
                            }
                        }
                        .padding()
                        
                        // Phase 5B: Envelope Test Presets
                        VStack(spacing: 15) {
                            Text("Envelope Presets (Phase 5B)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Current: \(currentEnvelopePreset)")
                                .font(.caption)
                                .foregroundColor(Color("HighlightColour"))
                            
                            // Row 1: Basic presets
                            HStack(spacing: 10) {
                                Button("FM Bell") {
                                    applyEnvelopePreset(EnvelopeTestPresets.fmBell, name: "FM Bell")
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Filter Sweep") {
                                    applyEnvelopePreset(EnvelopeTestPresets.filterSweep, name: "Filter Sweep")
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Combined") {
                                    applyEnvelopePreset(EnvelopeTestPresets.combinedEvolution, name: "Combined")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            // Row 2: Advanced presets
                            HStack(spacing: 10) {
                                Button("Pitch Drop") {
                                    applyEnvelopePreset(EnvelopeTestPresets.pitchDrop, name: "Pitch Drop")
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Brass") {
                                    applyEnvelopePreset(EnvelopeTestPresets.brass, name: "Brass")
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Pluck") {
                                    applyEnvelopePreset(EnvelopeTestPresets.pluck, name: "Pluck")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            // Row 3: Pad + Reset
                            HStack(spacing: 10) {
                                Button("Pad") {
                                    applyEnvelopePreset(EnvelopeTestPresets.pad, name: "Pad")
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button("Reset (None)") {
                                    resetEnvelopes()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            
                            // Preset descriptions
                            Text(envelopePresetDescription)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(height: 30)
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Test keyboard (9 keys)
                        VStack(spacing: 10) {
                            Text("Test Keys - Try pressing more than 5!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Top row
                            HStack(spacing: 10) {
                                NewVoiceKeyButton(
                                    label: "Key 1",
                                    colorName: keyColor(for: 0),
                                    keyIndex: 0,
                                    frequency: testFrequencies[0]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 2",
                                    colorName: keyColor(for: 1),
                                    keyIndex: 1,
                                    frequency: testFrequencies[1]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 3",
                                    colorName: keyColor(for: 2),
                                    keyIndex: 2,
                                    frequency: testFrequencies[2]
                                )
                            }
                            
                            // Middle row
                            HStack(spacing: 10) {
                                NewVoiceKeyButton(
                                    label: "Key 4",
                                    colorName: keyColor(for: 3),
                                    keyIndex: 3,
                                    frequency: testFrequencies[3]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 5",
                                    colorName: keyColor(for: 4),
                                    keyIndex: 4,
                                    frequency: testFrequencies[4]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 6",
                                    colorName: keyColor(for: 5),
                                    keyIndex: 5,
                                    frequency: testFrequencies[5]
                                )
                            }
                            
                            // Bottom row
                            HStack(spacing: 10) {
                                NewVoiceKeyButton(
                                    label: "Key 7",
                                    colorName: keyColor(for: 6),
                                    keyIndex: 6,
                                    frequency: testFrequencies[6]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 8",
                                    colorName: keyColor(for: 7),
                                    keyIndex: 7,
                                    frequency: testFrequencies[7]
                                )
                                
                                NewVoiceKeyButton(
                                    label: "Key 9",
                                    colorName: keyColor(for: 8),
                                    keyIndex: 8,
                                    frequency: testFrequencies[8]
                                )
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Instructions
                        VStack(spacing: 5) {
                            Text("Testing Guide")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Voice Allocation:")
                                .font(.caption)
                                .foregroundColor(Color("HighlightColour"))
                            
                            Text("• Press multiple keys simultaneously")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Try pressing more than 5 keys (voice stealing)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Stereo Spread:")
                                .font(.caption)
                                .foregroundColor(Color("HighlightColour"))
                                .padding(.top, 5)
                            
                            Text("• Switch between Proportional and Constant modes")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Adjust stereo spread slider while playing")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Envelope Modulation (Phase 5B):")
                                .font(.caption)
                                .foregroundColor(Color("HighlightColour"))
                                .padding(.top, 5)
                            
                            Text("• Select an envelope preset above")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Play notes to hear timbral evolution")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• FM Bell: bright → mellow (classic FM)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Filter Sweep: bright → dark (analog sweep)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                        
                        Text(statusMessage)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await initializeAudioForTest()
        }
    }
    
    // MARK: - Computed Properties
    
    private var centsSpreadProportional: Double {
        // Convert frequency offset ratio to cents spread (symmetric, so multiply by 2)
        let cents = 1200.0 * log2(frequencyOffsetRatio)
        return cents * 2.0  // Symmetric spread
    }
    
    private var beatRateConstant: Double {
        // Beat rate is twice the Hz offset (symmetric: +Hz on left, -Hz on right)
        return frequencyOffsetHz * 2.0
    }
    
    private var envelopePresetDescription: String {
        switch currentEnvelopePreset {
        case "FM Bell":
            return "Bright metallic attack → warm mellow sustain"
        case "Filter Sweep":
            return "Classic analog filter sweep (bright → dark)"
        case "Combined":
            return "FM + filter evolution (complex timbre)"
        case "Pitch Drop":
            return "808-style pitch drop (starts high, drops)"
        case "Brass":
            return "Brass instrument simulation"
        case "Pluck":
            return "Plucked string (quick decay, no sustain)"
        case "Pad":
            return "Slow evolving pad (long attack/release)"
        default:
            return "No envelope modulation active"
        }
    }
    
    // MARK: - Audio Initialization
    
    private func initializeAudioForTest() async {
        do {
            statusMessage = "Starting audio engine..."
            try EngineManager.startEngine()
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            statusMessage = "Voice pool ready!"
            
            await MainActor.run {
                isAudioReady = true
            }
        } catch {
            statusMessage = "Failed to initialize: \(error.localizedDescription)"
            print("Audio initialization error: \(error)")
        }
    }
    
    // MARK: - Scale Management
    
    private func changeScale(by delta: Int) {
        let newIndex = currentScaleIndex + delta
        guard newIndex >= 0 && newIndex < ScalesCatalog.all.count else { return }
        currentScaleIndex = newIndex
        
        // Update KeyboardState
        keyboardState.currentScale = ScalesCatalog.all[newIndex]
    }
    
    // MARK: - Key Color Calculation
    
    private func keyColor(for keyIndex: Int) -> String {
        let baseColorIndex = keyIndex % 5
        let rotatedColorIndex = (baseColorIndex + testScale.rotation + 5) % 5
        return "KeyColour\(rotatedColorIndex + 1)"
    }
    
    // MARK: - Envelope Preset Management
    
    private func applyEnvelopePreset(_ preset: VoiceModulationParameters, name: String) {
        voicePool.applyEnvelopeTestPreset(preset)
        currentEnvelopePreset = name
        print("🎵 Applied envelope preset: \(name)")
    }
    
    private func resetEnvelopes() {
        var defaultModulation = VoiceModulationParameters.default
        defaultModulation.modulatorEnvelope.isEnabled = false
        defaultModulation.auxiliaryEnvelope.isEnabled = false
        voicePool.updateAllVoiceModulation(defaultModulation)
        currentEnvelopePreset = "None"
        print("🎵 Reset all envelope modulation")
    }
}

// MARK: - New Voice Key Button

private struct NewVoiceKeyButton: View {
    let label: String
    let colorName: String
    let keyIndex: Int
    let frequency: Double
    
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorName))
                .opacity(isPressed ? 0.5 : 1.0)
                .frame(width: 100, height: 80)
                .overlay(
                    VStack(spacing: 2) {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(Int(frequency)) Hz")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                voicePool.allocateVoice(frequency: frequency, forKey: keyIndex)
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            voicePool.releaseVoice(forKey: keyIndex)
                        }
                )
        }
    }
}
*/
