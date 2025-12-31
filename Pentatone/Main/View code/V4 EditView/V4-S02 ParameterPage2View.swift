//
//  V4-S02 ParameterPage2View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 2 - VOICE CONTOUR

/*
 PAGE 2 - VOICE CONTOUR
 1) Amp Envelope Attack time. SLIDER. Values: 0-5 continuous
 2) Amp Envelope Decay time. SLIDER. Values: 0-5 continuous
 3) Amp Envelope Sustain level. SLIDER. Values: 0-1 continuous
 4) Amp Envelope Release time. SLIDER. Values: 0-5 continuous
 5) Lowpass Filter Cutoff frequency. SLIDER. Values: 20 - 20000 continuous << needs logarithmic scaling
 6) Lowpass Filter Resonance. SLIDER. Values: 0-2 continuous
 7) Lowpass Filter Saturation. SLIDER. Values: 0-10 continuous
 */

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

struct ContourView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Amp Envelope Attack (0-5 seconds)
            SliderRow(
                label: "AMP ENV ATTACK",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.attackDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeAttack(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 4 - Amp Envelope Decay (0-5 seconds)
            SliderRow(
                label: "AMP ENV DECAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.decayDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeDecay(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 5 - Amp Envelope Sustain (0-1)
            SliderRow(
                label: "AMP ENV SUSTAIN",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.sustainLevel },
                    set: { newValue in
                        paramManager.updateEnvelopeSustain(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.001,
                displayFormatter: { String(format: "%.3f", $0) }
            )
            
            // Row 6 - Amp Envelope Release (0-5 seconds)
            SliderRow(
                label: "AMP ENV RELEASE",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.releaseDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeRelease(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.001,
                displayFormatter: { String(format: "%.3f s", $0) }
            )
            
            // Row 7 - Filter Cutoff (20-20000 Hz, logarithmic)
            LogarithmicSliderRow(
                label: "FILTER CUTOFF",
                value: Binding(
                    get: { paramManager.voiceTemplate.filter.cutoffFrequency },
                    set: { newValue in
                        paramManager.updateFilterCutoff(newValue)
                        applyFilterToAllVoices()
                    }
                ),
                range: 20...20000,
                displayFormatter: { value in
                    if value < 1000 {
                        return String(format: "%.0f Hz", value)
                    } else {
                        return String(format: "%.1f kHz", value / 1000)
                    }
                }
            )
            
            // Row 8 - Filter Resonance (0-2)
            SliderRow(
                label: "FILTER RESONANCE",
                value: Binding(
                    get: { paramManager.voiceTemplate.filter.resonance },
                    set: { newValue in
                        paramManager.updateFilterResonance(newValue)
                        applyFilterToAllVoices()
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 9 - Filter Saturation (0-10)
            SliderRow(
                label: "FILTER SATURATION",
                value: Binding(
                    get: { paramManager.voiceTemplate.filter.saturation },
                    set: { newValue in
                        paramManager.updateFilterSaturation(newValue)
                        applyFilterToAllVoices()
                    }
                ),
                range: 0...10,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current envelope parameters to all active voices
    private func applyEnvelopeToAllVoices() {
        let params = paramManager.voiceTemplate.envelope
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            voice.updateEnvelopeParameters(params)
        }
    }
    
    /// Applies current filter parameters to all active voices
    private func applyFilterToAllVoices() {
        let params = paramManager.voiceTemplate.filter
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            voice.updateFilterParameters(params)
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            ContourView()
        }
        .padding(25)
    }
}
