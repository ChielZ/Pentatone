//
//
//  AudioKitCode.swift
//  Penta-Tone
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
        
        // Delay processes the mixed signal - initialized with parameters
        fxDelay = StereoDelay(
                                voiceMixer,
                                time: AUValue(masterParams.delay.time),
                                feedback: AUValue(masterParams.delay.feedback),
                                dryWetMix: AUValue(masterParams.delay.dryWetMix),
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
        let rootFreq: Double = 200
        let frequencies = makeKeyFrequencies(for: testScale, baseFrequency: rootFreq)
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

#Preview {
    AudioEngineTestView()
}

