//
//  KeyboardState.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import SwiftUI
import Combine

/// Manages the current keyboard state including scale, key, and computed frequencies
/// This decouples frequency calculations from voice allocation, allowing dynamic voice management
@MainActor
final class KeyboardState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently selected scale
    @Published var currentScale: Scale {
        didSet {
            updateFrequencies()
        }
    }
    
    /// The currently selected musical key (transposition)
    @Published var currentKey: MusicalKey {
        didSet {
            updateFrequencies()
        }
    }
    
    /// The 18 computed key frequencies based on current scale and key
    /// Index 0-17 corresponds to keyboard keys 0-17
    @Published private(set) var keyFrequencies: [Double] = []
    
    // MARK: - Configuration
    
    /// Base frequency for calculations (D4 = 146.83 Hz by default)
    var baseFrequency: Double = MusicalKey.baseFrequency {
        didSet {
            updateFrequencies()
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a keyboard state with the specified scale and key
    /// - Parameters:
    ///   - scale: The initial scale (default: Center Meridian JI)
    ///   - key: The initial musical key (default: D)
    init(scale: Scale = ScalesCatalog.centerMeridian_JI, key: MusicalKey = .D) {
        self.currentScale = scale
        self.currentKey = key
        
        // Compute initial frequencies
        updateFrequencies()
    }
    
    // MARK: - Frequency Access
    
    /// Returns the frequency for a specific key index
    /// - Parameter index: The key index (0-17)
    /// - Returns: The frequency in Hz, or nil if index is out of range
    func frequencyForKey(at index: Int) -> Double? {
        guard (0..<18).contains(index) else { return nil }
        guard index < keyFrequencies.count else { return nil }
        return keyFrequencies[index]
    }
    
    /// Returns the frequency for a specific key index (unsafe, crashes if out of range)
    /// Use this when you're certain the index is valid
    /// - Parameter index: The key index (0-17)
    /// - Returns: The frequency in Hz
    func frequency(forKey index: Int) -> Double {
        precondition((0..<18).contains(index), "Key index must be 0-17")
        precondition(index < keyFrequencies.count, "Frequencies not yet computed")
        return keyFrequencies[index]
    }
    
    // MARK: - Scale & Key Updates
    
    /// Updates the current scale
    /// - Parameter scale: The new scale
    func updateScale(_ scale: Scale) {
        self.currentScale = scale
        // updateFrequencies() is called automatically by didSet
    }
    
    /// Updates the current musical key
    /// - Parameter key: The new key
    func updateKey(_ key: MusicalKey) {
        self.currentKey = key
        // updateFrequencies() is called automatically by didSet
    }
    
    /// Updates both scale and key simultaneously (more efficient than separate calls)
    /// - Parameters:
    ///   - scale: The new scale
    ///   - key: The new key
    func updateScaleAndKey(scale: Scale, key: MusicalKey) {
        // Update both without triggering didSet twice
        self.currentScale = scale
        self.currentKey = key
        updateFrequencies()
    }
    
    // MARK: - Frequency Calculation
    
    /// Recalculates all 18 key frequencies based on current scale and key
    private func updateFrequencies() {
        keyFrequencies = makeKeyFrequencies(
            for: currentScale,
            baseFrequency: baseFrequency,
            musicalKey: currentKey
        )
        
        print("🎹 KeyboardState: Updated frequencies for \(currentScale.name) in \(currentKey.rawValue)")
    }
    
    // MARK: - Rotation Helpers
    
    /// Applies a rotation offset to the current scale
    /// - Parameter offset: The rotation amount (-2 to +2)
    func applyRotation(_ offset: Int) {
        var newScale = currentScale
        newScale.rotation = offset
        currentScale = newScale
    }
    
    /// Cycles rotation forward or backward
    /// - Parameter forward: true to rotate forward, false to rotate backward
    func cycleRotation(forward: Bool) {
        var newScale = currentScale
        let newRotation = forward ? newScale.rotation + 1 : newScale.rotation - 1
        
        // Clamp rotation to -2...+2 range
        newScale.rotation = max(-2, min(2, newRotation))
        currentScale = newScale
    }
    
    // MARK: - Diagnostics
    
    /// Prints current keyboard state for debugging
    func printState() {
        print("🎹 Keyboard State:")
        print("   Scale: \(currentScale.name)")
        print("   Key: \(currentKey.rawValue)")
        print("   Rotation: \(currentScale.rotation)")
        print("   Base Frequency: \(baseFrequency) Hz")
        print("   Computed Frequencies: \(keyFrequencies.count)")
        
        if !keyFrequencies.isEmpty {
            print("   Key 0: \(keyFrequencies[0]) Hz")
            print("   Key 9 (middle): \(keyFrequencies[9]) Hz")
            print("   Key 17: \(keyFrequencies[17]) Hz")
        }
    }
}

// MARK: - Convenience Extensions

extension KeyboardState {
    
    /// Returns all key frequencies as an array (for compatibility)
    var allFrequencies: [Double] {
        keyFrequencies
    }
    
    /// Returns the number of keys (should always be 18)
    var keyCount: Int {
        keyFrequencies.count
    }
    
    /// Returns frequencies for a range of keys
    /// - Parameter range: The range of key indices
    /// - Returns: Array of frequencies for the specified keys
    func frequencies(for range: Range<Int>) -> [Double] {
        let safeRange = range.clamped(to: 0..<keyFrequencies.count)
        return Array(keyFrequencies[safeRange])
    }
}

// MARK: - Scale Cycling Helpers

extension KeyboardState {
    
    /// Cycles to the next scale in the catalog
    /// - Parameter catalog: The scale catalog to cycle through
    func cycleScaleForward(in catalog: [Scale]) {
        guard let currentIndex = catalog.firstIndex(where: { $0 == currentScale }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % catalog.count
        currentScale = catalog[nextIndex]
    }
    
    /// Cycles to the previous scale in the catalog
    /// - Parameter catalog: The scale catalog to cycle through
    func cycleScaleBackward(in catalog: [Scale]) {
        guard let currentIndex = catalog.firstIndex(where: { $0 == currentScale }) else {
            return
        }
        
        let previousIndex = (currentIndex - 1 + catalog.count) % catalog.count
        currentScale = catalog[previousIndex]
    }
}

// MARK: - Property Cycling Helpers

extension KeyboardState {
    
    /// Cycles the intonation (ET ↔ JI) by finding a matching scale
    /// - Parameters:
    ///   - forward: true to cycle forward, false backward (same effect for binary choice)
    ///   - catalog: The scale catalog to search
    func cycleIntonation(forward: Bool = true, in catalog: [Scale]) {
        let targetIntonation: Intonation = currentScale.intonation == .et ? .ji : .et
        
        // Find a scale with same celestial/terrestrial but different intonation
        if let matchingScale = catalog.first(where: {
            $0.intonation == targetIntonation &&
            $0.celestial == currentScale.celestial &&
            $0.terrestrial == currentScale.terrestrial
        }) {
            currentScale = matchingScale
        }
    }
    
    /// Cycles the celestial property (moon → center → sun)
    /// - Parameters:
    ///   - forward: true to cycle forward, false backward
    ///   - catalog: The scale catalog to search
    func cycleCelestial(forward: Bool, in catalog: [Scale]) {
        let allCelestials = Celestial.allCases
        guard let currentIndex = allCelestials.firstIndex(of: currentScale.celestial) else {
            return
        }
        
        let nextIndex = forward
            ? (currentIndex + 1) % allCelestials.count
            : (currentIndex - 1 + allCelestials.count) % allCelestials.count
        
        let targetCelestial = allCelestials[nextIndex]
        
        // Find a scale with same intonation/terrestrial but different celestial
        if let matchingScale = catalog.first(where: {
            $0.celestial == targetCelestial &&
            $0.intonation == currentScale.intonation &&
            $0.terrestrial == currentScale.terrestrial
        }) {
            currentScale = matchingScale
        }
    }
    
    /// Cycles the terrestrial property (occident → meridian → orient)
    /// - Parameters:
    ///   - forward: true to cycle forward, false backward
    ///   - catalog: The scale catalog to search
    func cycleTerrestrial(forward: Bool, in catalog: [Scale]) {
        let allTerrestrials = Terrestrial.allCases
        guard let currentIndex = allTerrestrials.firstIndex(of: currentScale.terrestrial) else {
            return
        }
        
        let nextIndex = forward
            ? (currentIndex + 1) % allTerrestrials.count
            : (currentIndex - 1 + allTerrestrials.count) % allTerrestrials.count
        
        let targetTerrestrial = allTerrestrials[nextIndex]
        
        // Find a scale with same intonation/celestial but different terrestrial
        if let matchingScale = catalog.first(where: {
            $0.terrestrial == targetTerrestrial &&
            $0.intonation == currentScale.intonation &&
            $0.celestial == currentScale.celestial
        }) {
            currentScale = matchingScale
        }
    }
    
    /// Cycles the musical key
    /// - Parameter forward: true to cycle forward, false backward
    func cycleKey(forward: Bool) {
        let allKeys = MusicalKey.allCases
        guard let currentIndex = allKeys.firstIndex(of: currentKey) else {
            return
        }
        
        let nextIndex = forward
            ? (currentIndex + 1) % allKeys.count
            : (currentIndex - 1 + allKeys.count) % allKeys.count
        
        currentKey = allKeys[nextIndex]
    }
}
