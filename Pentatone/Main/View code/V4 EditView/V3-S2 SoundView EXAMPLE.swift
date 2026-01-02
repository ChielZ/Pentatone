//
//  V3-S2 SoundView EXAMPLE.swift
//  Pentatone
//
//  This is an EXAMPLE showing how to integrate MacroControlsView
//  Replace the content of your actual V3-S2 SoundView with this pattern
//

import SwiftUI

// EXAMPLE: How your SoundView might look with macro controls integrated
struct SoundView_Example: View {
    @State private var selectedPresetID: UUID? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Top section: Preset selector
            PresetSelectorSection(selectedPresetID: $selectedPresetID)
                .onChange(of: selectedPresetID) { newPresetID in
                    if let presetID = newPresetID {
                        loadPreset(id: presetID)
                    }
                }
            
            Divider()
                .background(Color("HighlightColour").opacity(0.3))
            
            // Middle section: Macro controls (THE NEW ADDITION!)
            MacroControlsView()
                .padding(.horizontal)
            
            Divider()
                .background(Color("HighlightColour").opacity(0.3))
            
            // Bottom section: Other controls
            // (Your existing keyboard, scale selector, etc.)
            OtherControlsSection()
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Load default preset on appear
            loadDefaultPreset()
        }
    }
    
    // MARK: - Preset Loading
    
    private func loadPreset(id: UUID) {
        // 1. Get the preset from your preset manager
        guard let preset = PresetManager.shared.getPreset(id: id) else {
            return
        }
        
        // 2. Load it into the parameter manager
        AudioParameterManager.shared.loadPreset(preset)
        
        // 3. IMPORTANT: Capture base values for macro controls
        AudioParameterManager.shared.captureBaseValues()
        
        print("✅ Loaded preset: \(preset.name)")
    }
    
    private func loadDefaultPreset() {
        let defaultPreset = AudioParameterSet.default
        AudioParameterManager.shared.loadPreset(defaultPreset)
        AudioParameterManager.shared.captureBaseValues()
    }
}

// MARK: - Supporting Views (Placeholders for your existing components)

struct PresetSelectorSection: View {
    @Binding var selectedPresetID: UUID?
    
    var body: some View {
        VStack {
            Text("PRESET")
                .font(.headline)
                .foregroundColor(Color("HighlightColour"))
            
            // Your existing preset picker/selector
            // This is just a placeholder
            Button("Select Preset") {
                // Your preset selection logic
            }
            .foregroundColor(Color("HighlightColour"))
        }
    }
}

struct OtherControlsSection: View {
    var body: some View {
        VStack {
            // Your existing controls:
            // - Keyboard view
            // - Scale selector
            // - Key selector
            // - etc.
            Text("Other Controls")
                .foregroundColor(Color("HighlightColour"))
        }
    }
}

// MARK: - Preset Manager (Placeholder - implement based on your needs)

class PresetManager {
    static let shared = PresetManager()
    
    private var presets: [AudioParameterSet] = []
    
    func getPreset(id: UUID) -> AudioParameterSet? {
        return presets.first { $0.id == id }
    }
    
    func addPreset(_ preset: AudioParameterSet) {
        presets.append(preset)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        SoundView_Example()
    }
}

/*
 INTEGRATION NOTES:
 
 1. Replace the placeholder sections (PresetSelectorSection, OtherControlsSection)
    with your actual UI components
    
 2. The key addition is the MacroControlsView() - just drop it in where you want
    the macro controls to appear
    
 3. Make sure to call AudioParameterManager.shared.captureBaseValues() after
    loading any preset
    
 4. The macro controls will automatically update the sound in real-time
    
 5. When the user adjusts parameters in the advanced editor, you can optionally
    call captureBaseValues() again to make macros work relative to the new values
 */
