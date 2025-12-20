//
//  NoteNameText.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import SwiftUI

/// A view that displays a note name with the letter in Futura
/// and the accidental (♯ or ♭) in Arial Unicode MS for better typography.
struct NoteNameText: View {
    let noteName: NoteName
    let size: CGFloat
    let color: Color
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var adaptiveSize: CGFloat {
        // Regular width and height = iPad in any orientation
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return size
        } else if horizontalSizeClass == .regular {
            // iPhone Plus/Max in landscape
            return size * 0.75
        } else {
            // iPhone in portrait (compact width)
            return size * 0.65
        }
    }
    
    var body: some View {
        HStack(spacing: -2) {
            // Note letter in Futura
            Text(noteName.letter)
                .foregroundColor(color)
                .font(.custom("Futura", size: adaptiveSize))
            
            // Accidental in Arial Unicode MS (if present)
            if let accidental = noteName.accidental {
                // For double sharps/flats, use tighter kerning
                if accidental.count > 1 {
                    // Double sharp or double flat
                    Text(accidental)
                        .foregroundColor(color)
                        .font(.custom("Arial Unicode MS", size: adaptiveSize * 0.7))
                        .baselineOffset(adaptiveSize * 0.15)
                        .kerning(-adaptiveSize * 0.18) // Tight kerning for double accidentals
                } else {
                    // Single sharp or flat
                    Text(accidental)
                        .foregroundColor(color)
                        .font(.custom("Arial Unicode MS", size: adaptiveSize * 0.7))
                        .baselineOffset(adaptiveSize * 0.15)
                }
            }
        }
    }
}
