# Note Naming Algorithm for Pentatonic Scales

## Overview

This document describes the algorithmic approach for generating correct note names (e.g., "D", "F♯", "B♭") for any pentatonic scale in any key, while respecting standard music theory spelling conventions.

## The Core Principle: Diatonic Letter Constraint

**Rule**: In any scale, each letter name (A-G) must appear at most once.

This fundamental constraint determines whether a note should be spelled as "F♯" vs "G♭" vs "E𝄪". You cannot have both F and F♯ in the same scale—you must choose one or the other based on context.

## The Two-Step Algorithm

### Step 1: Define the Letter Pattern

For each scale type, determine which diatonic letters it uses, expressed as **letter offsets from the root**.

**Example: Center Meridian [0, 2, 5, 7, 10] in D**
- D, E, G, A, C

Letter progression:
- D → E = 1 letter step (D to E)
- E → G = 2 letter steps (E to F to G)
- G → A = 1 letter step (G to A)
- A → C = 2 letter steps (A to B to C)

Cumulative offsets from root: **[0, 1, 3, 4, 6]**

**Example: Center Orient [0, 4, 5, 7, 8] in D**
- D, F♯, G, A, B♭

Letter progression:
- D → F = 2 letter steps (D to E to F)
- F → G = 1 letter step
- G → A = 1 letter step
- A → B = 1 letter step

Cumulative offsets from root: **[0, 2, 3, 4, 5]**

### Step 2: Calculate Required Accidentals

Once you know which letters to use, determine what accidental (♯, ♭, ♮) makes that letter hit the correct chromatic pitch.

## Implementation Components

### 1. Diatonic Letter System

```swift
enum DiatonicLetter: Int, CaseIterable {
    case c = 0, d = 1, e = 2, f = 3, g = 4, a = 5, b = 6
    
    var name: String {
        String(describing: self).uppercased()
    }
    
    /// Advance by a number of diatonic steps (wraps around at 7)
    func advanced(by steps: Int) -> DiatonicLetter {
        let newIndex = (rawValue + steps + 7) % 7
        return DiatonicLetter(rawValue: newIndex)!
    }
    
    /// The semitone offset of this letter when unmodified (natural)
    var naturalSemitoneOffset: Int {
        switch self {
        case .c: return 0
        case .d: return 2
        case .e: return 4
        case .f: return 5
        case .g: return 7
        case .a: return 9
        case .b: return 11
        }
    }
}
```

### 2. Note Name Structure

```swift
struct NoteName {
    let letter: String        // "A", "B", "C", etc.
    let accidental: String?   // "♯", "♭", "♯♯", "♭♭", or nil
    
    var display: String {
        letter + (accidental ?? "")
    }
    
    /// Returns an AttributedString with accidentals in a different font
    /// (Solves the "Futura renders sharps/flats poorly" problem)
    func attributed(letterFont: String = "Futura", letterSize: CGFloat = 30) -> AttributedString {
        var result = AttributedString(letter)
        result.font = .custom(letterFont, size: letterSize)
        
        if let acc = accidental {
            var accString = AttributedString(acc)
            // Use system font for better sharp/flat rendering
            accString.font = .system(size: letterSize)
            result += accString
        }
        
        return result
    }
}
```

### 3. Pitch Class (Root Note) System

```swift
enum PitchClass: String, CaseIterable {
    // Natural notes
    case c = "C", d = "D", e = "E", f = "F", g = "G", a = "A", b = "B"
    
    // Sharps (for keys that use sharp spelling)
    case cSharp = "C♯", dSharp = "D♯", fSharp = "F♯", gSharp = "G♯", aSharp = "A♯"
    
    // Flats (for keys that use flat spelling)
    case dFlat = "D♭", eFlat = "E♭", gFlat = "G♭", aFlat = "A♭", bFlat = "B♭"
    
    /// The base letter (C from "C♯", D from "D♭", etc.)
    var baseLetter: DiatonicLetter {
        switch self {
        case .c, .cSharp: return .c
        case .d, .dSharp, .dFlat: return .d
        case .e, .eFlat: return .e
        case .f, .fSharp: return .f
        case .g, .gSharp, .gFlat: return .g
        case .a, .aSharp, .aFlat: return .a
        case .b, .bFlat: return .b
        }
    }
    
    /// Chromatic semitone offset (0-11)
    var semitoneOffset: Int {
        switch self {
        case .c: return 0
        case .cSharp, .dFlat: return 1
        case .d: return 2
        case .dSharp, .eFlat: return 3
        case .e: return 4
        case .f: return 5
        case .fSharp, .gFlat: return 6
        case .g: return 7
        case .gSharp, .aFlat: return 8
        case .a: return 9
        case .aSharp, .bFlat: return 10
        case .b: return 11
        }
    }
}
```

### 4. Scale Type Definition

Add to your existing `Scale` struct:

```swift
struct Scale: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let intonation: Intonation
    let celestial: Celestial
    let terrestrial: Terrestrial
    let notes: [Double]  // Frequency ratios (existing)
    var rotation: Int = 0  // (existing)
    
    // NEW: Add these properties
    let semitonePattern: [Int]  // e.g., [0, 2, 5, 7, 10]
    let letterPattern: [Int]    // e.g., [0, 1, 3, 4, 6]
}
```

### 5. The Spelling Algorithm

```swift
/// Determines what accidental is needed to spell a target semitone using a specific letter
func spell(semitone targetSemitone: Int, usingLetter letter: DiatonicLetter) -> NoteName {
    let natural = letter.naturalSemitoneOffset
    let difference = (targetSemitone - natural + 12) % 12
    
    let accidental: String?
    switch difference {
    case 0:  accidental = nil      // Natural
    case 1:  accidental = "♯"      // Sharp
    case 2:  accidental = "♯♯"     // Double sharp (rare)
    case 11: accidental = "♭"      // Flat (11 = -1 mod 12)
    case 10: accidental = "♭♭"     // Double flat (rare)
    default:
        // For extreme cases, fall back to multiple sharps
        // (In practice, well-formed scales shouldn't hit this)
        accidental = String(repeating: "♯", count: difference)
    }
    
    return NoteName(letter: letter.name, accidental: accidental)
}

/// Generates the note names for a scale in a given key
func noteNames(forScale scale: Scale, inKey root: PitchClass) -> [NoteName] {
    let rootLetter = root.baseLetter
    
    return zip(scale.letterPattern, scale.semitonePattern).map { (letterStep, semitoneStep) in
        // Which diatonic letter to use for this note
        let targetLetter = rootLetter.advanced(by: letterStep)
        
        // Which chromatic pitch to hit
        let targetSemitone = (root.semitoneOffset + semitoneStep) % 12
        
        // Spell that pitch using that letter
        return spell(semitone: targetSemitone, usingLetter: targetLetter)
    }
}
```

## Worked Examples

### Example 1: Center Meridian in D

**Scale**: [0, 2, 5, 7, 10] semitones, letter pattern [0, 1, 3, 4, 6]  
**Root**: D (semitone 2, base letter D)

| Letter Step | Semitone Step | Target Letter | Target Semitone | Natural | Difference | Result |
|-------------|---------------|---------------|-----------------|---------|------------|--------|
| 0           | 0             | D             | 2               | 2       | 0          | **D**  |
| 1           | 2             | E             | 4               | 4       | 0          | **E**  |
| 3           | 5             | G             | 7               | 7       | 0          | **G**  |
| 4           | 7             | A             | 9               | 9       | 0          | **A**  |
| 6           | 10            | C             | 0               | 0       | 0          | **C**  |

**Result**: D, E, G, A, C ✓

### Example 2: Center Meridian in A♭

**Scale**: [0, 2, 5, 7, 10] semitones, letter pattern [0, 1, 3, 4, 6]  
**Root**: A♭ (semitone 8, base letter A)

| Letter Step | Semitone Step | Target Letter | Target Semitone | Natural | Difference | Result |
|-------------|---------------|---------------|-----------------|---------|------------|--------|
| 0           | 0             | A             | 8               | 9       | -1 (11)    | **A♭** |
| 1           | 2             | B             | 10              | 11      | -1 (11)    | **B♭** |
| 3           | 5             | D             | 1               | 2       | -1 (11)    | **D♭** |
| 4           | 7             | E             | 3               | 4       | -1 (11)    | **E♭** |
| 6           | 10            | G             | 6               | 7       | -1 (11)    | **G♭** |

**Result**: A♭, B♭, D♭, E♭, G♭ ✓

### Example 3: Center Orient in G♯

**Scale**: [0, 4, 5, 7, 8] semitones, letter pattern [0, 2, 3, 4, 5]  
**Root**: G♯ (semitone 8, base letter G)

| Letter Step | Semitone Step | Target Letter | Target Semitone | Natural | Difference | Result  |
|-------------|---------------|---------------|-----------------|---------|------------|---------|
| 0           | 0             | G             | 8               | 7       | +1         | **G♯**  |
| 2           | 4             | B             | 0               | 11      | +1         | **B♯**  |
| 3           | 5             | C             | 1               | 0       | +1         | **C♯**  |
| 4           | 7             | D             | 3               | 2       | +1         | **D♯**  |
| 5           | 8             | E             | 4               | 4       | 0          | **E**   |

**Result**: G♯, B♯, C♯, D♯, E ✓

Note the B♯ (not C)—this is correct because we must use the letter B, and B natural is semitone 11, but we need semitone 0 (next octave), which is +1 semitone = B♯.

## Letter Patterns for All 9 Scale Types

Based on the two examples provided, here's how to determine letter patterns for all scales:

### Center Meridian
- **Semitones**: [0, 2, 5, 7, 10]
- **Letters**: [0, 1, 3, 4, 6]
- **In D**: D, E, G, A, C

### Center Orient
- **Semitones**: [0, 4, 5, 7, 8]
- **Letters**: [0, 2, 3, 4, 5]
- **In D**: D, F♯, G, A, B♭

### Center Occident
- **Semitones**: [0, 3, 5, 7, 9] (from Scales.swift)
- **Letters**: [0, 1, 3, 4, 6] (needs verification)
- **In D**: Would be D, E♭, G, A, B (to be confirmed)

### Moon Orient
- **Semitones**: [0, 1, 5, 7, 8]
- **Letters**: [0, 1, 3, 4, 5] (needs verification)

### Moon Meridian
- **Semitones**: [0, 3, 5, 7, 8]
- **Letters**: [0, 1, 3, 4, 5] (needs verification)

### Moon Occident
- **Semitones**: [0, 3, 5, 7, 10]
- **Letters**: [0, 1, 3, 4, 6] (needs verification)

### Sun Orient
- **Semitones**: [0, 4, 5, 7, 11]
- **Letters**: [0, 2, 3, 4, 6] (needs verification)

### Sun Meridian
- **Semitones**: [0, 4, 5, 7, 9]
- **Letters**: [0, 2, 3, 4, 5] (needs verification)

### Sun Occident
- **Semitones**: [0, 2, 5, 7, 9]
- **Letters**: [0, 1, 3, 4, 5] (needs verification)

**TODO**: Verify the letter patterns for the remaining 7 scale types by working through a reference key (like D) and determining the expected note names.

## How to Determine Letter Patterns

For any new scale type:

1. Choose a simple reference key (D or C work well)
2. Calculate what the chromatic pitches would be (using semitone pattern)
3. Determine what the "musically correct" note names should be
4. Count the letter steps between consecutive notes
5. Create the cumulative offset array

**Example for an unknown scale [0, 3, 5, 8, 10]**:

In D major:
- D + 0 = D (semitone 2)
- D + 3 = F (semitone 5) 
- D + 5 = G (semitone 7)
- D + 8 = B♭ (semitone 10)
- D + 10 = C (semitone 0)

Letter sequence: D, F, G, B, C
Letter steps: D→F=2, F→G=1, G→B=2, B→C=1
Cumulative: [0, 2, 3, 5, 6]

## Integration with SwiftUI Display

Since Futura renders sharps and flats poorly, use the `attributed()` method:

```swift
// In your OptionsView
let noteNames = noteNames(forScale: currentScale, inKey: currentRoot)

HStack {
    ForEach(noteNames.indices, id: \.self) { index in
        Text(noteNames[index].attributed())
            .foregroundColor(Color("KeyColour\(index + 1)"))
    }
}
```

This will render letters in Futura but accidentals in the system font, giving you proper musical symbols without spacing issues.

## Important Notes

### Why Enharmonic Roots Matter

Notice that G♯ and A♭ are the same pitch (semitone 8) but produce different spellings:
- **G♯ Orient**: G♯, B♯, C♯, D♯, E (all sharps)
- **A♭ Orient**: A♭, C, D♭, E♭, F♭ (all flats)

This is because the base letter determines which diatonic sequence we follow. Your key selector UI should allow users to choose between enharmonic equivalents.

### Rotation Doesn't Affect Note Names

The `rotation` property in your `Scale` struct changes which frequencies map to which keys, but it doesn't change the **names** of the notes in the scale. The scale still has the same five pitch classes regardless of rotation.

### JI vs ET Spelling

As you noted, Just Intonation vs Equal Temperament shouldn't affect note name display. Both use the same semitone pattern rounded to the nearest semitone for naming purposes.

## Future Considerations

### Double Sharps and Double Flats

The algorithm already handles these (B♯, F♭, E♯, C♭, F𝄪, C𝄫, etc.) automatically when needed. They appear in keys with many accidentals:
- C♯ major would include E♯ and B♯
- G♭ major would include C♭ and F♭

### Extended Key Support

If you add more exotic keys (F♭, B♯, etc.), the algorithm handles them naturally. Just ensure your `PitchClass` enum includes them.

### Validation

You can validate letter patterns by checking that:
1. All letter offsets are in range [0-6]
2. No letter is repeated
3. The pattern produces the expected notes in at least one test key

## Summary

This algorithmic approach:
✅ Generates correct note names for any scale in any key  
✅ Respects diatonic spelling conventions  
✅ Handles enharmonic roots properly  
✅ Avoids redundant data storage (no 13×5 matrices)  
✅ Supports mixed fonts for better sharp/flat rendering  
✅ Is extensible to new scales and keys  
✅ Produces human-readable code  

The one-time cost is determining the letter pattern for each of your 9 scale types, then the algorithm does the rest automatically.
