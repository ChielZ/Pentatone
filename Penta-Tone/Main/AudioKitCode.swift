//
//
//  AudioKitCode.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import AudioKit
import SoundpipeAudioKit
internal import AudioKitEX
import AVFAudio

// Shared engine and mixer for the entire app (single engine architecture)
let sharedEngine = AudioEngine()
private(set) var sharedMixer: Mixer!

// NOTE: AudioKit Parameter Errors
// During initialization, AudioKit will log approximately 198 kAudioUnitErr_InvalidParameter
// errors to the console. These are caused by AudioKit's internal parameter-setting mechanism
// and are harmless - the parameters are correctly applied despite the errors. This is a known
// characteristic of AudioKit's initialization process and cannot be easily eliminated without
// modifying AudioKit's source code. The app functions correctly despite these console messages.

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










// Shared wavetable - created once and reused by all oscillators
//private let sharedSineTable = Table(.sine)

// A single voice: oscillator -> amplitude envelope -> shared mixer
final class OscVoice {
    let osc: FMOscillator
    let env: AmplitudeEnvelope

    private var frequency: AUValue = 200.0
    private var initialised = false

    init() {
        self.osc = FMOscillator(waveform: Table(.triangle))
        self.env = AmplitudeEnvelope(osc,
                                     attackDuration: 0.5,
                                     decayDuration: 0.5,
                                     sustainLevel: 0.2,
                                     releaseDuration: 0.10)
        sharedMixer.addInput(env)
    }

    func initialise() {
        if !initialised {
            initialised = true
            osc.baseFrequency = frequency
            osc.amplitude = 0.15
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
        env.reset()
        env.openGate()
        //print("trigger invoked- frequency: \(frequency)")
    }
    
    func release() {
        env.closeGate()
        //print("release invoked- frequency: \(frequency)")
    }
}

// Engine manager to control the shared engine lifecycle
enum EngineManager {
    private static var started = false
    private static var voicesCreated = false

    static func startIfNeeded() {
        guard !started else { return }
        
        AudioSessionManager.configureSession()
        sharedMixer = Mixer()
        sharedEngine.output = sharedMixer
        
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

// Helper to create all oscillators
private func createAllVoices() {
    oscillator01 = OscVoice()
    oscillator02 = OscVoice()
    oscillator03 = OscVoice()
    oscillator04 = OscVoice()
    oscillator05 = OscVoice()
    oscillator06 = OscVoice()
    oscillator07 = OscVoice()
    oscillator08 = OscVoice()
    oscillator09 = OscVoice()
    oscillator10 = OscVoice()
    oscillator11 = OscVoice()
    oscillator12 = OscVoice()
    oscillator13 = OscVoice()
    oscillator14 = OscVoice()
    oscillator15 = OscVoice()
    oscillator16 = OscVoice()
    oscillator17 = OscVoice()
    oscillator18 = OscVoice()
}



