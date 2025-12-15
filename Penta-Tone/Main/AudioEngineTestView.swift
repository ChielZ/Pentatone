//
//  AudioEngineTestView.swift
//  Penta-Tone
//
//  Created for audio engine testing in Xcode previews
//
/*
import SwiftUI

/// A simplified test view for testing audio engine changes in Xcode previews
/// This view initializes the full audio engine so you can hear and test sound changes
/// without deploying to a device.
struct AudioEngineTestView: View {
    @State private var isAudioReady = false
    @State private var currentScaleIndex = 0
    @State private var statusMessage = "Initializing audio..."
    
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
                            
                            Text("Edit AudioKitCode.swift to change:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Waveform: OscVoice.init() - waveform parameter")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Envelope: AmplitudeEnvelope parameters")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Volume: osc.amplitude in initialise()")
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
*/
