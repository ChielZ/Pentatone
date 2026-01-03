//
//  V4-S03 ParameterPage3View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 3 - EFFECTS

/*
 PAGE 3 - EFFECTS
 1) Delay time. LIST. Values: 1/32, 1/24, 1/16, 3/32, 1/8, 3/16, 1/4
 2) Delay feedback. SLIDER. Values: 0-1 continuous
 3) Delay PingPong. LIST. Values: on, off
 4) Delay mix. SLIDER. Values: 0-1 continuous
 5) Reverb size. SLIDER. Values: 0-1 continuous
 6) Reverb tone. SLIDER. Values: 0-1 continuous
 7) Reverb mix. SLIDER. Values: 0-1 continuous
 */

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - Ping Pong Mode

/// On/Off toggle for delay ping pong
enum PingPongMode: CaseIterable, Equatable {
    case on
    case off
    
    var displayName: String {
        switch self {
        case .on: return "On"
        case .off: return "Off"
        }
    }
    
    var boolValue: Bool {
        return self == .on
    }
    
    static func from(_ bool: Bool) -> PingPongMode {
        return bool ? .on : .off
    }
}

struct EffectsView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Delay Time (tempo-synced divisions)
            ParameterRow(
                label: "DELAY TIME",
                value: Binding(
                    get: { paramManager.master.delay.timeValue },
                    set: { newValue in
                        paramManager.updateDelayTimeValue(newValue)
                    }
                ),
                displayText: { $0.displayName }
            )
            
            // Row 4 - Delay Feedback (0-1)
            SliderRow(
                label: "DELAY FEEDBACK",
                value: Binding(
                    get: { paramManager.master.delay.feedback },
                    set: { newValue in
                        paramManager.updateDelayFeedback(newValue)
                        applyDelayToEngine()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 5 - Delay tone
            SliderRow(
                label: "DELAY TONE",
                value: Binding(
                    get: { paramManager.master.delay.toneCutoff },
                    set: { newValue in
                        paramManager.updateDelayToneCutoff(newValue)
                    }
                ),
                range: 200...20_000,
                step: 100,
                displayFormatter: { cutoff in
                    if cutoff < 1000 {
                        return String(format: "%.0f Hz", cutoff)
                    } else {
                        return String(format: "%.1f kHz", cutoff / 1000)
                    }
                }
            )
            // Row 6 - Delay Mix (0-1)
            SliderRow(
                label: "DELAY MIX",
                value: Binding(
                    get: { paramManager.master.delay.dryWetMix },
                    set: { newValue in
                        paramManager.updateDelayMix(newValue)
                        applyDelayToEngine()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 7 - Reverb Size (feedback 0-1)
            SliderRow(
                label: "REVERB SIZE",
                value: Binding(
                    get: { paramManager.master.reverb.feedback },
                    set: { newValue in
                        paramManager.updateReverbFeedback(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 8 - Reverb Tone (cutoff frequency, logarithmic)
            // Map 0-1 to 200-20000 Hz for user-friendly control
            SliderRow(
                label: "REVERB TONE",
                value: Binding(
                    get: {
                        // Convert cutoff frequency to 0-1 range (logarithmic)
                        let cutoff = paramManager.master.reverb.cutoffFrequency
                        let logMin = log(200.0)
                        let logMax = log(20000.0)
                        let logValue = log(cutoff)
                        return (logValue - logMin) / (logMax - logMin)
                    },
                    set: { newValue in
                        // Convert 0-1 to cutoff frequency (logarithmic)
                        let logMin = log(200.0)
                        let logMax = log(20000.0)
                        let logValue = logMin + newValue * (logMax - logMin)
                        let cutoff = exp(logValue)
                        paramManager.updateReverbCutoff(cutoff)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { value in
                    // Display the actual frequency
                    let logMin = log(200.0)
                    let logMax = log(20000.0)
                    let logValue = logMin + value * (logMax - logMin)
                    let cutoff = exp(logValue)
                    
                    if cutoff < 1000 {
                        return String(format: "%.0f Hz", cutoff)
                    } else {
                        return String(format: "%.1f kHz", cutoff / 1000)
                    }
                }
            )
            
            // Row 9 - Reverb Mix (0-1)
            SliderRow(
                label: "REVERB MIX",
                value: Binding(
                    get: { paramManager.master.reverb.balance },
                    set: { newValue in
                        paramManager.updateReverbMix(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current delay parameters to the engine
    /// Note: Some delay parameters are already applied in real-time by the update methods
    private func applyDelayToEngine() {
        // The update methods already apply directly to the AudioKit nodes
        // This is a placeholder in case additional logic is needed
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            EffectsView()
        }
        .padding(25)
    }
}
