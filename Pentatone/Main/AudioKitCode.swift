//
//
//  AudioKitCode.swift
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
private(set) var voiceMixer: Mixer!
private(set) var fxDelay: StereoDelay!
private(set) var fxReverb: CostelloReverb!
private(set) var reverbDryWet: DryWetMixer!

// MARK: - Phase 1: New Voice Pool Architecture
// New polyphonic voice pool (runs in parallel with old system for testing)
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



// A single voice: oscillator -> filter -> amplitude envelope -> pan -> shared mixer
final class OscVoice {
    let osc: FMOscillator
    let voiceEnv: AmplitudeEnvelope
    let filter: LowPassFilter
    let pan: Panner

    private var frequency: AUValue = 146.83
    private var initialised = false
    private var currentWaveform: OscillatorWaveform = .sine  // Track current waveform

    init(parameters: VoiceParameters = .default) {
        // Initialize with parameters from the parameter system
        self.currentWaveform = parameters.oscillator.waveform
        
        self.osc = FMOscillator(
                            waveform: parameters.oscillator.waveform.makeTable(),  // <-- Use parameter
                            baseFrequency: frequency,
                            carrierMultiplier: AUValue(parameters.oscillator.carrierMultiplier),
                            modulatingMultiplier: AUValue(parameters.oscillator.modulatingMultiplier),
                            modulationIndex: AUValue(parameters.oscillator.modulationIndex),
                            amplitude: AUValue(parameters.oscillator.amplitude)
                            )
                        
        
        self.filter = LowPassFilter(
                        osc,
                        cutoffFrequency: AUValue(parameters.filter.clampedCutoff),
                        resonance: AUValue(parameters.filter.resonance)
                        )
        
        self.voiceEnv = AmplitudeEnvelope(
                        filter,
                        attackDuration: AUValue(parameters.envelope.attackDuration),
                        decayDuration: AUValue(parameters.envelope.decayDuration),
                        sustainLevel: AUValue(parameters.envelope.sustainLevel),
                        releaseDuration: AUValue(parameters.envelope.releaseDuration)
                        )
        
        self.pan = Panner(
                        voiceEnv,
                        pan: AUValue(parameters.pan.clampedPan)
                        )

        voiceMixer.addInput(pan)
    }
    
    func updateWaveformIfNeeded(_ newWaveform: OscillatorWaveform) {
        currentWaveform = newWaveform
        // Note: Dynamic waveform switching requires voice recreation
        // Current implementation tracks preference for future recreation
    }

    
    func initialise() {
        if !initialised {
            initialised = true
            osc.start()
        }
    }

    func setFrequency(_ freq: Double) {
        frequency = AUValue(freq)
        if initialised {
            osc.baseFrequency = frequency
        }
    }

    func trigger() {
        if !initialised {
            initialise()
        }
        voiceEnv.reset()
        voiceEnv.openGate()
    }
    
    func release() {
        voiceEnv.closeGate()
    }
}

// Engine manager to control the shared engine lifecycle
enum EngineManager {
    private static var started = false
    private static var voicesCreated = false

    static func startIfNeeded() {
        guard !started else { return }
        
        AudioSessionManager.configureSession()
        
        // Get default parameters from parameter manager
        let masterParams = MasterParameters.default
        
        voiceMixer = Mixer()
        
        // PHASE 1: Create new voice pool (5 voices by default)
        voicePool = VoicePool(voiceCount: 5)
        
        // Mix old and new voice systems together
        let combinedMixer = Mixer(voiceMixer, voicePool.voiceMixer)
        
        // Delay processes the mixed signal - initialized with parameters
        fxDelay = StereoDelay(
                                combinedMixer,  // Changed: now processes both old and new voices
                                time: AUValue(masterParams.delay.time),
                                feedback: AUValue(masterParams.delay.feedback),
                                dryWetMix: AUValue(1-masterParams.delay.dryWetMix),
                                pingPong: masterParams.delay.pingPong,
                                maximumDelayTime: 10
                                )
        
        // Reverb processes the delayed signal - initialized with parameters
        fxReverb = CostelloReverb(
                                fxDelay,
                                feedback: AUValue(masterParams.reverb.feedback),
                                cutoffFrequency: AUValue(masterParams.reverb.cutoffFrequency)
                                )
        
        // DryWetMixer blends dry (delay) and wet (reverb) signals
        reverbDryWet = DryWetMixer(
                                fxDelay, fxReverb,
                                balance: AUValue(masterParams.reverb.dryWetBalance)
                                )
        
        // Final output is the dry/wet mix
        sharedEngine.output = reverbDryWet
        
        // Create all voices with default parameters
        if !voicesCreated {
            createAllVoices()
            voicesCreated = true
        }
        
        do {
            try sharedEngine.start()
            started = true
            
            // PHASE 1: Initialize voice pool after engine starts
            voicePool.initialize()
            
        } catch {
            assertionFailure("Failed to start AudioKit engine: \(error)")
        }
    }
    
    static func startEngine() throws {
        startIfNeeded()
    }
    
    static func initializeVoices(count: Int = 18) {
        guard started else {
            assertionFailure("Cannot initialize voices before engine is started")
            return
        }
        
        guard voicesCreated else {
            assertionFailure("Voices should already be created before engine start")
            return
        }
        
        // Initialize all oscillators (starts the audio processing)
        oscillator01.initialise()
        oscillator02.initialise()
        oscillator03.initialise()
        oscillator04.initialise()
        oscillator05.initialise()
        oscillator06.initialise()
        oscillator07.initialise()
        oscillator08.initialise()
        oscillator09.initialise()
        oscillator10.initialise()
        oscillator11.initialise()
        oscillator12.initialise()
        oscillator13.initialise()
        oscillator14.initialise()
        oscillator15.initialise()
        oscillator16.initialise()
        oscillator17.initialise()
        oscillator18.initialise()
    }
    
    static func applyScale(frequencies: [Double]) {
        guard frequencies.count == 18 else {
            print("Warning: Expected 18 frequencies, got \(frequencies.count)")
            return
        }
        guard voicesCreated else {
            assertionFailure("Cannot apply scale before voices are created")
            return
        }
        
        oscillator01.setFrequency(frequencies[0])
        oscillator02.setFrequency(frequencies[1])
        oscillator03.setFrequency(frequencies[2])
        oscillator04.setFrequency(frequencies[3])
        oscillator05.setFrequency(frequencies[4])
        oscillator06.setFrequency(frequencies[5])
        oscillator07.setFrequency(frequencies[6])
        oscillator08.setFrequency(frequencies[7])
        oscillator09.setFrequency(frequencies[8])
        oscillator10.setFrequency(frequencies[9])
        oscillator11.setFrequency(frequencies[10])
        oscillator12.setFrequency(frequencies[11])
        oscillator13.setFrequency(frequencies[12])
        oscillator14.setFrequency(frequencies[13])
        oscillator15.setFrequency(frequencies[14])
        oscillator16.setFrequency(frequencies[15])
        oscillator17.setFrequency(frequencies[16])
        oscillator18.setFrequency(frequencies[17])
    }
}

// Voices will be created after engine starts (initially nil)
var oscillator01: OscVoice!
var oscillator02: OscVoice!
var oscillator03: OscVoice!
var oscillator04: OscVoice!
var oscillator05: OscVoice!
var oscillator06: OscVoice!
var oscillator07: OscVoice!
var oscillator08: OscVoice!
var oscillator09: OscVoice!
var oscillator10: OscVoice!
var oscillator11: OscVoice!
var oscillator12: OscVoice!
var oscillator13: OscVoice!
var oscillator14: OscVoice!
var oscillator15: OscVoice!
var oscillator16: OscVoice!
var oscillator17: OscVoice!
var oscillator18: OscVoice!

// Helper to create all oscillators using default parameters
private func createAllVoices() {
    let voiceParams = VoiceParameters.default
    
    oscillator01 = OscVoice(parameters: voiceParams)
    oscillator02 = OscVoice(parameters: voiceParams)
    oscillator03 = OscVoice(parameters: voiceParams)
    oscillator04 = OscVoice(parameters: voiceParams)
    oscillator05 = OscVoice(parameters: voiceParams)
    oscillator06 = OscVoice(parameters: voiceParams)
    oscillator07 = OscVoice(parameters: voiceParams)
    oscillator08 = OscVoice(parameters: voiceParams)
    oscillator09 = OscVoice(parameters: voiceParams)
    oscillator10 = OscVoice(parameters: voiceParams)
    oscillator11 = OscVoice(parameters: voiceParams)
    oscillator12 = OscVoice(parameters: voiceParams)
    oscillator13 = OscVoice(parameters: voiceParams)
    oscillator14 = OscVoice(parameters: voiceParams)
    oscillator15 = OscVoice(parameters: voiceParams)
    oscillator16 = OscVoice(parameters: voiceParams)
    oscillator17 = OscVoice(parameters: voiceParams)
    oscillator18 = OscVoice(parameters: voiceParams)
}


// ***************************
// Code below is for testing purposes only

import SwiftUI

/// A simplified test view for testing audio engine changes in Xcode previews
/// This view initializes the full audio engine so you can hear and test sound changes
/// without deploying to a device.
struct AudioEngineTestView: View {
    @State private var isAudioReady = false
    @State private var currentScaleIndex = 0
    @State private var statusMessage = "Initializing audio..."
    
    // Access the parameter manager
    private let paramManager = AudioParameterManager.shared
    
    // Test scale - you can change this to test different scales
    private var testScale: Scale {
        ScalesCatalog.all[currentScaleIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BackgroundColour").ignoresSafeArea()
                
                if isAudioReady {
                    VStack(spacing: 20) {
                        // Status header
                        VStack(spacing: 10) {
                            Text("Audio Engine Test")
                                .font(.title)
                                .foregroundColor(Color("HighlightColour"))
                            
                            Text(testScale.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
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
                        }
                        .padding()
                        
                        // Parameter controls for testing
                        VStack(spacing: 15) {
                            Text("Master Effects")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Delay mix control
                            HStack {
                                Text("Delay Mix:")
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
                                Slider(value: Binding(
                                    get: { paramManager.master.delay.dryWetMix },
                                    set: { paramManager.updateDelayMix($0) }
                                ), in: 0...1)
                                Text("\(Int(paramManager.master.delay.dryWetMix * 100))%")
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                            
                            // Reverb mix control
                            HStack {
                                Text("Reverb Mix:")
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
                                Slider(value: Binding(
                                    get: { paramManager.master.reverb.dryWetBalance },
                                    set: { paramManager.updateReverbMix($0) }
                                ), in: 0...1)
                                Text("\(Int(paramManager.master.reverb.dryWetBalance * 100))%")
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                            
                            // Filter cutoff control (affects template)
                            HStack {
                                Text("Filter Cutoff:")
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
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
                                    .frame(width: 70)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Simplified keyboard - just 9 keys for testing
                        VStack(spacing: 10) {
                            Text("Test Keys")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Top row - 3 keys
                            HStack(spacing: 10) {
                                TestKeyButton(
                                    label: "Key 1",
                                    colorName: keyColor(for: 0),
                                    trigger: { oscillator01.trigger() },
                                    release: { oscillator01.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 2",
                                    colorName: keyColor(for: 1),
                                    trigger: { oscillator02.trigger() },
                                    release: { oscillator02.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 3",
                                    colorName: keyColor(for: 2),
                                    trigger: { oscillator03.trigger() },
                                    release: { oscillator03.release() }
                                )
                            }
                            
                            // Middle row - 3 keys
                            HStack(spacing: 10) {
                                TestKeyButton(
                                    label: "Key 4",
                                    colorName: keyColor(for: 3),
                                    trigger: { oscillator04.trigger() },
                                    release: { oscillator04.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 5",
                                    colorName: keyColor(for: 4),
                                    trigger: { oscillator05.trigger() },
                                    release: { oscillator05.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 6",
                                    colorName: keyColor(for: 5),
                                    trigger: { oscillator06.trigger() },
                                    release: { oscillator06.release() }
                                )
                            }
                            
                            // Bottom row - 3 keys
                            HStack(spacing: 10) {
                                TestKeyButton(
                                    label: "Key 7",
                                    colorName: keyColor(for: 6),
                                    trigger: { oscillator07.trigger() },
                                    release: { oscillator07.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 8",
                                    colorName: keyColor(for: 7),
                                    trigger: { oscillator08.trigger() },
                                    release: { oscillator08.release() }
                                )
                                
                                TestKeyButton(
                                    label: "Key 9",
                                    colorName: keyColor(for: 8),
                                    trigger: { oscillator09.trigger() },
                                    release: { oscillator09.release() }
                                )
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Audio parameter info (you can expand this)
                        VStack(spacing: 5) {
                            Text("Quick Reference")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Edit AudioParameters.swift to change defaults")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Use AudioParameterManager to control parameters")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Try the sliders above to test parameter changes")
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
    
    // MARK: - Audio Initialization
    
    private func initializeAudioForTest() async {
        do {
            statusMessage = "Starting audio engine..."
            try EngineManager.startEngine()
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            statusMessage = "Initializing voices..."
            EngineManager.initializeVoices(count: 18)
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            statusMessage = "Loading scale..."
            applyScale()
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            await MainActor.run {
                statusMessage = "Ready!"
                isAudioReady = true
            }
        } catch {
            statusMessage = "Failed to initialize audio: \(error.localizedDescription)"
            print("Audio initialization error: \(error)")
        }
    }
    
    // MARK: - Scale Management
    
    private func applyScale() {
        // Use default base frequency and key (D)
        let frequencies = makeKeyFrequencies(for: testScale)
        EngineManager.applyScale(frequencies: frequencies)
    }
    
    private func changeScale(by delta: Int) {
        let newIndex = currentScaleIndex + delta
        guard newIndex >= 0 && newIndex < ScalesCatalog.all.count else { return }
        currentScaleIndex = newIndex
        applyScale()
    }
    
    // MARK: - Key Color Calculation
    
    private func keyColor(for keyIndex: Int) -> String {
        let baseColorIndex = keyIndex % 5
        let rotatedColorIndex = (baseColorIndex + testScale.rotation + 5) % 5
        return "KeyColour\(rotatedColorIndex + 1)"
    }
}

// MARK: - Test Key Button

private struct TestKeyButton: View {
    let label: String
    let colorName: String
    let trigger: () -> Void
    let release: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorName))
                .opacity(isPressed ? 0.5 : 1.0)
                .frame(width: 100, height: 80)
                .overlay(
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                trigger()
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            release()
                        }
                )
        }
    }
}

// MARK: - Preview

#Preview("Old Voice System") {
    AudioEngineTestView()
}

#Preview("New Voice Pool System") {
    NewVoicePoolTestView()
}

// MARK: - Phase 1: New Voice Pool Test View

/// Test view for the new polyphonic voice pool architecture
struct NewVoicePoolTestView: View {
    @State private var isAudioReady = false
    @State private var statusMessage = "Initializing audio..."
    @State private var currentScaleIndex = 0
    
    // Phase 2: KeyboardState for frequency management
    @StateObject private var keyboardState = KeyboardState()
    
    // Detune controls
    @State private var detuneMode: DetuneMode = .proportional
    @State private var frequencyOffsetRatio: Double = 1.0     // Proportional mode: 1.0 to 1.01
    @State private var frequencyOffsetHz: Double = 0.0        // Constant mode: 0 to 2.5 Hz
    
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
                            Text("Phase 1: Voice Pool Test")
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
                            
                            // Phase 2: Show KeyboardState info
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
                            
                            Text("• Press multiple keys simultaneously")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Try pressing more than 5 keys (voice stealing)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Switch between Proportional and Constant modes")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Proportional: higher notes beat faster (natural)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Constant: same beat rate for all notes (uniform)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Adjust stereo spread slider while playing")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Watch voice pool status update")
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
        
        // Phase 2: Update KeyboardState
        keyboardState.currentScale = ScalesCatalog.all[newIndex]
    }
    
    // MARK: - Key Color Calculation
    
    private func keyColor(for keyIndex: Int) -> String {
        let baseColorIndex = keyIndex % 5
        let rotatedColorIndex = (baseColorIndex + testScale.rotation + 5) % 5
        return "KeyColour\(rotatedColorIndex + 1)"
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

