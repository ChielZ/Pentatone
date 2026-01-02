//
//  A3 VoicePool.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import DunneAudioKit

/// actual polyphony
let nominalPolyphony = 5
var currentPolyphony = nominalPolyphony

/// Manages allocation and lifecycle of polyphonic voices
/// Uses round-robin allocation with availability checking and voice stealing
final class VoicePool {
    
    // MARK: - Voice Management
    
    /// All available voices
    private(set) var voices: [PolyphonicVoice] = []
    
    /// Mixer to combine all voice outputs
    let voiceMixer: Mixer
    
    /// Round-robin allocation pointer
    private var currentVoiceIndex: Int = 0
    
    /// Maps key indices (0-17) to their currently playing voices
    /// Enables precise release tracking without frequency matching
    private var keyToVoiceMap: [Int: PolyphonicVoice] = [:]
    
    /// In monophonic mode, tracks which key currently "owns" the active voice
    /// Only the owning key can release the voice (last-note priority)
    private var monoVoiceOwner: Int? = nil
    
    /// Flag to track if the voice pool has been initialized
    private var isInitialized: Bool = false
    
    // MARK: - FX Node References
    
    /// Reference to delay node for global LFO modulation
    /// Set after engine initialization via setFXNodes()
    private weak var delay: StereoDelay?
    
    /// Reference to reverb node for global LFO modulation
    /// Set after engine initialization via setFXNodes()
    private weak var reverb: CostelloReverb?
    
    // MARK: - Global Modulation (Phase 5)
    
    /// Global LFO affecting all voices (will be implemented in Phase 5)
    var globalLFO: GlobalLFOParameters = .default
    
    /// Base delay time (from tempo-synced value, before LFO modulation)
    private var baseDelayTime: Double = 0.5  // Default: 1/4 note at 120 BPM
    
    // MARK: - Initialization
    
    /// Creates a voice pool with the specified polyphony
    /// - Parameter voiceCount: Number of voices (defaults to currentPolyphony)
    ///   Use 1 for monophonic mode, nominalPolyphony for polyphonic mode
    init(voiceCount: Int = currentPolyphony) {
        // Create mixer first
        self.voiceMixer = Mixer()
        
        // Always create nominalPolyphony voices (don't change voice count at runtime)
        // In mono mode, we just use the first voice only
        let actualVoiceCount = nominalPolyphony
        
        // Create all voices
        let voiceParams = VoiceParameters.default
        for _ in 0..<actualVoiceCount {
            let voice = PolyphonicVoice(parameters: voiceParams)
            voices.append(voice)
        }
        
        // Connect all voices to mixer
        for voice in voices {
            voiceMixer.addInput(voice.envelope)
        }
        
        print("🎵 VoicePool created with \(voices.count) voice(s) available, starting in \(voiceCount == 1 ? "monophonic" : "polyphonic") mode")
    }
    
    /// Initializes all voices (starts oscillators)
    /// Must be called after the audio engine is started
    func initialize() {
        guard !isInitialized else {
            print("🎵 VoicePool already initialized, skipping")
            return
        }
        
        for voice in voices {
            voice.initialize()
        }
        
        isInitialized = true
        print("🎵 VoicePool initialized with \(voices.count) voices")
    }
    
    /// Sets references to FX nodes for global LFO modulation
    /// Must be called after FX nodes are created in the audio engine
    /// - Parameters:
    ///   - delay: The stereo delay node
    ///   - reverb: The reverb node
    func setFXNodes(delay: StereoDelay, reverb: CostelloReverb) {
        self.delay = delay
        self.reverb = reverb
        print("🎵 VoicePool: FX node references set")
    }
    
    // MARK: - Voice Allocation
    
    /// Finds an available voice, or steals the oldest one if all are busy
    /// Uses round-robin allocation starting from current index
    /// In monophonic mode (currentPolyphony == 1), always uses voice 0
    private func findAvailableVoice() -> PolyphonicVoice {
        // Monophonic mode: always use voice 0 and steal it if needed
        if currentPolyphony == 1 {
            let monoVoice = voices[0]
            if monoVoice.isAvailable {
                return monoVoice
            } else {
                // Steal the mono voice
                monoVoice.envelope.closeGate()
                monoVoice.isAvailable = true
                print("⚠️ Mono voice stealing")
                return monoVoice
            }
        }
        
        // Polyphonic mode: use round-robin with all voices
        var checkedCount = 0
        var index = currentVoiceIndex
        
        // First pass: look for available voices (use all nominalPolyphony voices)
        while checkedCount < nominalPolyphony {
            if voices[index].isAvailable {
                currentVoiceIndex = index
                return voices[index]
            }
            
            index = (index + 1) % nominalPolyphony
            checkedCount += 1
        }
        
        // No available voice found - steal the oldest one
        // Find voice with earliest trigger time (from all voices)
        let oldestVoice = voices.min(by: { $0.triggerTime < $1.triggerTime })!
        
        // Force release the oldest voice (instant cutoff as per requirements)
        oldestVoice.envelope.closeGate()
        oldestVoice.isAvailable = true  // Mark immediately available
        
        print("⚠️ Voice stealing: Took voice triggered at \(oldestVoice.triggerTime)")
        
        return oldestVoice
    }
    
    /// Increments to the next voice index (round-robin)
    /// Only used in polyphonic mode
    private func incrementVoiceIndex() {
        if currentPolyphony > 1 {
            currentVoiceIndex = (currentVoiceIndex + 1) % nominalPolyphony
        }
        // In mono mode, don't increment (always stay at 0)
    }
    
    // MARK: - Note Triggering
    
    /// Allocates a voice and triggers it with the specified frequency
    /// - Parameters:
    ///   - frequency: The base frequency to play (from keyboard/scale)
    ///   - keyIndex: The key index (0-17) triggering this note
    ///   - globalPitch: Global pitch modifiers (transpose, octave, fine tune)
    /// - Returns: The allocated voice (for reference if needed)
    @discardableResult
    func allocateVoice(frequency: Double, forKey keyIndex: Int, globalPitch: GlobalPitchParameters = .default) -> PolyphonicVoice {
        guard isInitialized else {
            assertionFailure("VoicePool must be initialized before allocating voices")
            return voices[0]
        }
        
        // Find an available voice (or steal one)
        let voice = findAvailableVoice()
        
        // Apply global pitch modifiers to the base frequency
        let finalFrequency = frequency * globalPitch.combinedFactor
        
        // Set frequency and trigger
        voice.setFrequency(finalFrequency)
        voice.trigger()
        
        // Map this key to the voice for precise release tracking
        keyToVoiceMap[keyIndex] = voice
        
        // In monophonic mode, this key becomes the new owner
        if currentPolyphony == 1 {
            monoVoiceOwner = keyIndex
        }
        
        print("🎵 Key \(keyIndex): Allocated voice, base frequency \(frequency) Hz → final \(finalFrequency) Hz (×\(globalPitch.combinedFactor))")
        
        // Move to next voice for round-robin
        incrementVoiceIndex()
        
        return voice
    }
    
    /// Releases the voice associated with a specific key
    /// - Parameter keyIndex: The key index (0-17) to release
    func releaseVoice(forKey keyIndex: Int) {
        guard let voice = keyToVoiceMap[keyIndex] else {
            print("⚠️ Key \(keyIndex): No voice found to release")
            return
        }
        
        // In monophonic mode, only release if this key is the current owner
        if currentPolyphony == 1 {
            if monoVoiceOwner == keyIndex {
                // This is the owning key - release the voice
                voice.release()
                print("🎵 Key \(keyIndex): Released (mono owner)")
                monoVoiceOwner = nil
            } else {
                // This is not the owning key - just remove from map without releasing
                print("🎵 Key \(keyIndex): Removed from map (not mono owner)")
            }
        } else {
            // Polyphonic mode - always release
            voice.release()
            print("🎵 Key \(keyIndex): Released")
        }
        
        // Remove mapping - key is no longer pressed
        keyToVoiceMap.removeValue(forKey: keyIndex)
        
        // Note: Voice will mark itself available after release duration completes
    }
    
    /// Stops all voices immediately
    func stopAll() {
        for voice in voices {
            voice.envelope.closeGate()
            voice.isAvailable = true
        }
        keyToVoiceMap.removeAll()
        monoVoiceOwner = nil
        print("🎵 All voices stopped")
    }
    
    // MARK: - Voice Recreation (for waveform changes)
    
    /// Recreates only the oscillators in all voices with a new waveform
    /// This is more efficient than recreating entire voices and avoids connection issues
    /// Warning: Will briefly interrupt any currently playing notes
    /// - Parameters:
    ///   - waveform: The new waveform to use
    ///   - completion: Called when oscillator recreation is complete
    func recreateOscillators(waveform: OscillatorWaveform, completion: @escaping () -> Void) {
        print("🎵 Starting oscillator recreation with waveform: \(waveform)...")
        
        // Stop all playing notes and clear key mappings
        stopAll()
        
        // Recreate oscillators in each voice
        for (index, voice) in voices.enumerated() {
            voice.recreateOscillators(waveform: waveform)
            print("🎵   Voice \(index): oscillators recreated")
        }
        
        print("🎵 ✅ Oscillator recreation complete - \(voices.count) voices ready")
        completion()
    }
    
    /// Recreates all voices with new parameters (e.g., when waveform changes)
    /// This properly cleans up old voices and creates new ones
    /// Note: Voice count remains fixed at nominalPolyphony
    /// Warning: Kills any currently playing notes
    /// DEPRECATED: Use recreateOscillators() instead for waveform changes
    func recreateVoices(with parameters: VoiceParameters, completion: @escaping () -> Void) {
        print("🎵 Starting voice recreation...")
        
        // Stop all playing notes and clear key mappings
        stopAll()
        
        // Reset voice index
        currentVoiceIndex = 0
        
        // Store references to old voices (keep them alive during transition)
        let oldVoices = voices
        
        print("🎵 Creating \(nominalPolyphony) new voices...")
        
        // Create new voices immediately (on main thread - AudioKit prefers this)
        var newVoices: [PolyphonicVoice] = []
        for i in 0..<nominalPolyphony {
            let voice = PolyphonicVoice(parameters: parameters)
            newVoices.append(voice)
            print("🎵   Voice \(i): created")
        }
        
        print("🎵 Swapping audio connections...")
        
        // Connect new voices to mixer FIRST (before disconnecting old ones)
        for (index, voice) in newVoices.enumerated() {
            voiceMixer.addInput(voice.envelope)
            print("🎵   Voice \(index): connected to mixer")
        }
        
        // Initialize new voices if pool was already initialized
        if isInitialized {
            print("🎵 Initializing new voices...")
            for (index, voice) in newVoices.enumerated() {
                voice.initialize()
                print("🎵   Voice \(index): initialized & started")
            }
        }
        
        // Now that new voices are live, swap the array
        voices = newVoices
        
        // Disconnect and cleanup old voices AFTER new ones are running
        print("🎵 Cleaning up old voices...")
        for (index, oldVoice) in oldVoices.enumerated() {
            voiceMixer.removeInput(oldVoice.envelope)
            oldVoice.cleanup()
            print("🎵   Old voice \(index): disconnected & cleaned")
        }
        
        print("🎵 ✅ Voice recreation complete - \(voices.count) voices ready")
        completion()
    }
    
    // MARK: - Polyphony Adjustment
    
    /// Switches between monophonic and polyphonic modes
    /// Does NOT recreate voices - just changes which voices are used for allocation
    /// - Parameter count: Number of voices to use (1 for mono, nominalPolyphony for poly)
    /// - Parameter completion: Called after mode switch is complete
    func setPolyphony(_ count: Int, completion: @escaping () -> Void) {
        print("🎵 Switching from \(currentPolyphony == 1 ? "monophonic" : "polyphonic") to \(count == 1 ? "monophonic" : "polyphonic") mode...")
        
        // Stop all playing notes and clear key mappings
        stopAll()
        
        // Reset voice index
        currentVoiceIndex = 0
        
        // Clear mono voice owner when switching modes
        monoVoiceOwner = nil
        
        // Update global currentPolyphony
        currentPolyphony = count
        
        print("🎵 Mode switched to \(count == 1 ? "monophonic (using voice 0 only)" : "polyphonic (using all \(nominalPolyphony) voices)")")
        completion()
    }
    
    // MARK: - Parameter Updates
    
    /// Updates oscillator parameters for all voices
    func updateAllVoiceOscillators(_ parameters: OscillatorParameters) {
        for voice in voices {
            voice.updateOscillatorParameters(parameters)
        }
    }
    
    /// Updates filter parameters for all voices
    func updateAllVoiceFilters(_ parameters: FilterParameters) {
        for voice in voices {
            voice.updateFilterParameters(parameters)
        }
    }
    
    /// Updates envelope parameters for all voices
    func updateAllVoiceEnvelopes(_ parameters: EnvelopeParameters) {
        for voice in voices {
            voice.updateEnvelopeParameters(parameters)
        }
    }
    
    /// Updates detune mode for all voices
    func updateDetuneMode(_ mode: DetuneMode) {
        for voice in voices {
            voice.detuneMode = mode
        }
    }
    
    /// Updates frequency offset ratio for all voices (proportional mode)
    func updateFrequencyOffsetRatio(_ ratio: Double) {
        for voice in voices {
            voice.frequencyOffsetRatio = ratio
        }
    }
    
    /// Updates frequency offset in Hz for all voices (constant mode)
    func updateFrequencyOffsetHz(_ hz: Double) {
        for voice in voices {
            voice.frequencyOffsetHz = hz
        }
    }
    
    // MARK: - Modulation (Phase 5)
    
    /// Control-rate timer for modulation updates (Phase 5B+)
    private var modulationTimer: DispatchSourceTimer?
    
    /// Global modulation state (Phase 5C)
    private var globalModulationState = GlobalModulationState()
    
    /// Current tempo for tempo-synced modulation (Phase 5C)
    var currentTempo: Double = 120.0 {
        didSet {
            globalModulationState.currentTempo = currentTempo
        }
    }
    
    /// Updates global LFO parameters
    func updateGlobalLFO(_ parameters: GlobalLFOParameters) {
        globalLFO = parameters
    }
    
    /// Updates the base delay time (tempo-synced value before LFO modulation)
    /// Should be called whenever tempo or delay time value changes
    /// - Parameter delayTime: The delay time in seconds (already calculated from tempo and time value)
    func updateBaseDelayTime(_ delayTime: Double) {
        baseDelayTime = delayTime
        print("🎵 VoicePool: Base delay time updated to \(delayTime)s")
    }
    
    /// Updates modulation parameters for all voices
    func updateAllVoiceModulation(_ parameters: VoiceModulationParameters) {
        for voice in voices {
            voice.updateModulationParameters(parameters)
        }
    }
    
    /// Starts the modulation update loop (Phase 5B)
    /// Control rate: 200 Hz (5ms intervals) for smooth envelopes
    func startModulation() {
        guard modulationTimer == nil else {
            print("🎵 Modulation timer already running")
            return
        }
        
        // Create a dispatch timer on a background queue
        let queue = DispatchQueue(label: "com.pentatone.modulation", qos: .userInteractive)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        
        // Set to fire every 5ms (200 Hz)
        timer.schedule(deadline: .now(), repeating: ControlRateConfig.updateInterval)
        
        timer.setEventHandler { [weak self] in
            self?.updateModulation()
        }
        
        timer.resume()
        modulationTimer = timer
        
        print("🎵 Modulation system started at \(ControlRateConfig.updateRate) Hz")
    }
    
    /// Stops the modulation update loop
    func stopModulation() {
        modulationTimer?.cancel()
        modulationTimer = nil
        print("🎵 Modulation system stopped")
    }
    
    /// Updates modulation for all active voices (refactored for fixed destinations)
    /// Called by control-rate timer at 200 Hz on background thread
    private func updateModulation() {
        let deltaTime = ControlRateConfig.updateInterval
        
        // Update global LFO phase and get raw value
        let globalLFORawValue = updateGlobalLFOPhase(deltaTime: deltaTime)
        
        // Apply global LFO to global-level destinations (delay time only)
        applyGlobalLFOToGlobalParameters(rawValue: globalLFORawValue)
        
        // Update all active voices with global LFO parameters
        // Note: This runs on background thread, AudioKit parameter updates are thread-safe
        for voice in voices where !voice.isAvailable {
            voice.applyModulation(
                globalLFO: (rawValue: globalLFORawValue, parameters: globalLFO),
                deltaTime: deltaTime,
                currentTempo: currentTempo
            )
        }
    }
    
    // MARK: - Global LFO Phase Management (Refactored)
    
    /// Updates the global LFO phase and returns the raw waveform value
    /// - Parameter deltaTime: Time since last update (typically 0.005 seconds)
    /// - Returns: Raw global LFO value (-1.0 to +1.0, unscaled by amounts)
    private func updateGlobalLFOPhase(deltaTime: Double) -> Double {
        guard globalLFO.isEnabled else { return 0.0 }
        
        // Calculate phase increment based on frequency mode
        let phaseIncrement: Double
        
        switch globalLFO.frequencyMode {
        case .hertz:
            // Direct Hz: phase increment = frequency * deltaTime
            phaseIncrement = globalLFO.frequency * deltaTime
            
        case .tempoSync:
            // Tempo sync: globalLFO.frequency is a tempo multiplier
            // e.g., 1.0 = quarter note, 2.0 = eighth note, 0.5 = half note
            let beatsPerSecond = currentTempo / 60.0
            let cyclesPerSecond = beatsPerSecond * globalLFO.frequency
            phaseIncrement = cyclesPerSecond * deltaTime
        }
        
        // Update phase (global LFO is always free-running or sync, never trigger)
        globalModulationState.globalLFOPhase += phaseIncrement
        
        // Wrap phase to 0-1 range
        if globalModulationState.globalLFOPhase >= 1.0 {
            globalModulationState.globalLFOPhase -= floor(globalModulationState.globalLFOPhase)
        }
        
        // Get raw LFO value (waveform output, not scaled by amounts)
        return globalLFO.rawValue(at: globalModulationState.globalLFOPhase)
    }
    
    /// Applies global LFO modulation to global-level parameters (delay time)
    /// - Parameter rawValue: Raw global LFO value (-1.0 to +1.0, unscaled)
    private func applyGlobalLFOToGlobalParameters(rawValue: Double) {
        guard globalLFO.isEnabled, globalLFO.hasActiveDestinations else { return }
        
        // Global LFO Destination: Delay Time
        // Apply LFO offset to the base tempo-synced delay time (vibrato effect)
        if globalLFO.amountToDelayTime != 0.0, let delay = self.delay {
            let finalDelayTime = ModulationRouter.calculateDelayTime(
                baseDelayTime: baseDelayTime,  // Use stored base (tempo-synced value)
                globalLFOValue: rawValue,
                globalLFOAmount: globalLFO.amountToDelayTime
            )
            // Use ramp for smooth changes (no clicks)
            delay.$time.ramp(to: AUValue(finalDelayTime), duration: 0.005)
        }
        
        // Note: Other global LFO destinations (amplitude, modulator multiplier, filter)
        // are voice-level and handled by PolyphonicVoice.applyGlobalLFO()
    }
    
    // MARK: - Diagnostics
    
    /// Returns the number of currently active (unavailable) voices
    var activeVoiceCount: Int {
        voices.filter { !$0.isAvailable }.count
    }
    
    /// Prints current voice pool status
    func printStatus() {
        print("🎵 Voice Pool Status:")
        print("   Total voices: \(voices.count)")
        print("   Active voices: \(activeVoiceCount)")
        print("   Available voices: \(voices.count - activeVoiceCount)")
        print("   Keys pressed: \(keyToVoiceMap.count)")
        print("   Global LFO: \(globalLFO.isEnabled ? "enabled" : "disabled")")
        print("   Modulation timer: \(modulationTimer != nil ? "running" : "stopped")")
    }
}
