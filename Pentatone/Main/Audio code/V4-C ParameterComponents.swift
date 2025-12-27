//
//  V4-C ParameterComponents.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 27/12/2025.
//
//  Reusable UI components for parameter editing

import SwiftUI

// MARK: - Parameter Row (for discrete list selections)

/// A row for cycling through discrete parameter values (like enums)
/// Shows < value > with tap targets on the left and right buttons
struct ParameterRow<T: CaseIterable & Equatable>: View where T.AllCases.Index == Int {
    let label: String
    @Binding var value: T
    let displayText: (T) -> String
    
    init(label: String, value: Binding<T>, displayText: @escaping (T) -> String) {
        self.label = label
        self._value = value
        self.displayText = displayText
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack {
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cyclePrevious()
                    }
                
                Spacer()
                
                // Center display - label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
            }
            .padding(.horizontal, 5)
        }
    }
    
    private func cycleNext() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        let nextIndex = (currentIndex + 1) % allCases.count
        value = allCases[nextIndex]
    }
    
    private func cyclePrevious() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
        value = allCases[previousIndex]
    }
}

// MARK: - Slider Row (for continuous parameters)

/// A row for adjusting continuous numeric parameters
/// Shows label on left, value in center, and draggable area on right
struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.01,
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 8) {
                // Left: Label
                Text(label)
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 20)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                
                // Center: Value display
                Text(displayFormatter(value))
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("Futura", size: 26)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(minWidth: 80)
                
                // Right: Draggable area with < > indicators
                ZStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("SupportColour").opacity(0.3) : Color("SupportColour"))
                    
                    HStack(spacing: 4) {
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 24)
                            .minimumScaleFactor(0.5)
                        
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 24)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(width: 70)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert pixels to value change (1 point = 1% of range)
                            let rangeSize = range.upperBound - range.lowerBound
                            let sensitivity: CGFloat = 200.0  // pixels to traverse full range
                            let valueChange = Double(delta) * rangeSize / Double(sensitivity)
                            
                            // Apply change and clamp
                            let newValue = dragStartValue + valueChange
                            
                            // Snap to step
                            let steppedValue = round(newValue / step) * step
                            
                            // Clamp to range
                            value = min(max(steppedValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .padding(.trailing, 10)
            }
        }
    }
}

// MARK: - Integer Slider Row (convenience wrapper)

/// Convenience wrapper for integer-valued sliders
struct IntegerSliderRow: View {
    let label: String
    @Binding var value: Double  // Still Double for AudioKit compatibility
    let range: ClosedRange<Int>
    
    var body: some View {
        SliderRow(
            label: label,
            value: $value,
            range: Double(range.lowerBound)...Double(range.upperBound),
            step: 1.0,
            displayFormatter: { value in
                String(Int(round(value)))
            }
        )
    }
}

// MARK: - Preview Helper

private struct ParameterComponentsPreview: View {
    @State private var waveform: OscillatorWaveform = .sine
    @State private var multiplier: Double = 8.0
    @State private var fineValue: Double = 0.5
    @State private var detuneMode: DetuneMode = .proportional
    
    var body: some View {
        ZStack {
            Color("BackgroundColour").ignoresSafeArea()
            
            VStack(spacing: 11) {
                // Example: Enum cycling
                ParameterRow(
                    label: "WAVEFORM",
                    value: $waveform,
                    displayText: { $0.displayName }
                )
                
                // Example: Integer slider
                IntegerSliderRow(
                    label: "CARRIER MULTIPLIER",
                    value: $multiplier,
                    range: 1...16
                )
                
                // Example: Continuous slider
                SliderRow(
                    label: "MODULATOR FINE",
                    value: $fineValue,
                    range: 0...1,
                    step: 0.01,
                    displayFormatter: { String(format: "%.2f", $0) }
                )
                
                // Example: Another enum
                ParameterRow(
                    label: "STEREO MODE",
                    value: $detuneMode,
                    displayText: { $0.displayName }
                )
            }
            .padding(20)
        }
    }
}

#Preview {
    ParameterComponentsPreview()
}
