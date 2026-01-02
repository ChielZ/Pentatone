# Preset System Implementation Guide

## Overview

This guide covers the implementation plan for the Pentatone preset system, designed to be portable across multiple apps in the series (Pentatone, ChromaTone, etc.).

---

## Core Architecture Principles

### **Separation of Concerns**

- **Sound Engine + Preset Data**: Universal, portable, identical across all apps
- **Preset Organization/Layout**: App-specific UI concern
- **Never mix these two layers**

### **What's Universal**

✅ `AudioParameterSet` structure (already implemented)  
✅ JSON file format  
✅ File type registration (`.pentatonepreset`)  
✅ Basic load/save logic  
✅ Preset sharing via export/import  

### **What's App-Specific**

🎹 Pentatone: 5×5 grid layout (F1.1 - F5.5, U1.1 - U5.5)  
🎹 ChromaTone: Different layout (7×7, 0-99, etc.)  
🎹 Each app has its own preset organization system  

---

## Storage Strategy: Three-Tier System

### **1. Factory Presets**
- **Location**: App bundle (`Resources/Presets/Factory/`)
- **Format**: Individual JSON files with descriptive names
- **Characteristics**:
  - Read-only (bundled with app at compile time)
  - Included in every app installation
  - User cannot modify or delete
- **Example**: `Ethereal Bells.json`, `Warm Pad.json`

### **2. User Presets**
- **Location**: Documents directory (`Documents/UserPresets/`)
- **Format**: Individual JSON files (UUID-based filenames)
- **Characteristics**:
  - Read-write (user creates/edits/deletes)
  - Automatically backed up via iCloud (if user has it enabled)
  - Persists across app updates
- **Example**: `A1B2C3D4-E5F6-4A5B-6C7D-8E9F0A1B2C3D.json`

### **3. Current State (Optional)**
- **Location**: `UserDefaults`
- **Purpose**: Quick app restoration (remember last used parameters)
- **Not a named preset**: Just the current working state

---

## File Structure Recommendations

### **Why Individual Files Per Preset?**

✅ Easier to manage (rename, delete, duplicate)  
✅ Better for iCloud sync (only changed presets sync)  
✅ Easier to share individual presets  
✅ More robust (one corrupted file doesn't break everything)  
✅ Better performance (load only what you need)  

### **File Naming Strategy**

**Factory Presets**: Human-readable names
```
Resources/Presets/Factory/
├── Ethereal Bells.json
├── Warm Pad.json
├── Bright Lead.json
└── ...
```

**User Presets**: UUID-based names (auto-generated)
```
Documents/UserPresets/
├── A1B2C3D4-E5F6-4A5B-6C7D-8E9F0A1B2C3D.json
├── B2C3D4E5-F6A7-4B5C-6D7E-8F9A0B1C2D3E.json
└── ...
```

---

## Preset Mapping System

### **Use UUIDs, Not Names**

Each preset has a stable `UUID` identifier. Use this for mapping presets to slots.

**Don't do this**:
```swift
❌ var presetName: String  // Fragile, breaks on rename
```

**Do this**:
```swift
✅ var presetID: UUID  // Stable, unique, never changes
```

### **App-Specific Slot Structure (Pentatone Example)**

```swift
// PentatonePresetSlot.swift (app-specific, not in engine)
struct PentatonePresetSlot: Codable {
    var bank: Int              // 1...5
    var position: Int          // 1...5
    var presetID: UUID         // References AudioParameterSet.id
    var slotType: SlotType     // Factory or User
    
    enum SlotType: Codable {
        case factory
        case user
    }
    
    var displayName: String {
        let prefix = slotType == .factory ? "F" : "U"
        return "\(prefix)\(bank).\(position)"
    }
}
```

### **Factory Layout: Hardcoded in App**

```swift
// PentatoneFactoryLayout.swift
struct PentatoneFactoryLayout {
    // These UUIDs match the ones inside your factory preset JSON files
    static let factorySlots: [PentatonePresetSlot] = [
        PentatonePresetSlot(
            bank: 1, 
            position: 1, 
            presetID: UUID(uuidString: "A1B2C3D4-E5F6-4A5B-6C7D-8E9F0A1B2C3D")!,
            slotType: .factory
        ),
        PentatonePresetSlot(
            bank: 1, 
            position: 2, 
            presetID: UUID(uuidString: "B2C3D4E5-F6A7-4B5C-6D7E-8F9A0B1C2D3E")!,
            slotType: .factory
        ),
        // ... 25 total factory slots
    ]
}
```

### **User Layout: Saved to Documents**

```swift
// PentatoneUserLayout.swift
struct PentatoneUserLayout: Codable {
    var userSlots: [PentatonePresetSlot]
    
    // Default: 25 empty slots
    static let `default` = PentatoneUserLayout(
        userSlots: (1...5).flatMap { bank in
            (1...5).map { position in
                PentatonePresetSlot(
                    bank: bank,
                    position: position,
                    presetID: UUID(),  // Placeholder until user assigns a preset
                    slotType: .user
                )
            }
        }
    )
}
```

---

## Preset Manager Implementation

### **Core Responsibilities**

1. Load factory presets from bundle
2. Load user presets from Documents
3. Save/delete user presets
4. Maintain UUID → Preset lookup dictionary
5. Handle preset export/import
6. Manage app-specific layout (Pentatone's 5×5 grid)

### **Basic Structure**

```swift
@MainActor
final class PresetManager: ObservableObject {
    // MARK: - Preset Storage
    
    /// All loaded presets indexed by UUID
    private var presetLookup: [UUID: AudioParameterSet] = [:]
    
    /// Factory presets (read-only)
    @Published private(set) var factoryPresets: [AudioParameterSet] = []
    
    /// User presets (read-write)
    @Published private(set) var userPresets: [AudioParameterSet] = []
    
    // MARK: - Pentatone-Specific Layout
    
    /// Factory preset layout (5×5 grid, hardcoded)
    var factoryLayout: [PentatonePresetSlot] = PentatoneFactoryLayout.factorySlots
    
    /// User preset layout (5×5 grid, saved to disk)
    @Published var userLayout: PentatoneUserLayout = .default
    
    // MARK: - File Paths
    
    private let factoryPresetsURL: URL? = {
        Bundle.main.url(forResource: "Presets", withExtension: nil)
    }()
    
    private let userPresetsURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("UserPresets")
    }()
    
    // MARK: - Loading
    
    func loadAllPresets() {
        loadFactoryPresets()
        loadUserPresets()
        loadUserLayout()
    }
    
    private func loadFactoryPresets() {
        // Load all JSON files from bundle
        // Add to presetLookup and factoryPresets array
    }
    
    private func loadUserPresets() {
        // Load all JSON files from Documents/UserPresets
        // Add to presetLookup and userPresets array
    }
    
    private func loadUserLayout() {
        // Load PentatoneUserLayout from Documents
        // Or use default if not found
    }
    
    // MARK: - Saving
    
    func savePreset(_ preset: AudioParameterSet) throws {
        // Create UserPresets folder if needed
        try FileManager.default.createDirectory(at: userPresetsURL, withIntermediateDirectories: true)
        
        // Save to file
        let filename = "\(preset.id.uuidString).json"
        let fileURL = userPresetsURL.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(preset)
        try data.write(to: fileURL)
        
        // Update lookup and published array
        presetLookup[preset.id] = preset
        if !userPresets.contains(where: { $0.id == preset.id }) {
            userPresets.append(preset)
        }
    }
    
    func deletePreset(_ preset: AudioParameterSet) throws {
        // Remove file from disk
        let filename = "\(preset.id.uuidString).json"
        let fileURL = userPresetsURL.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
        
        // Update lookup and published array
        presetLookup.removeValue(forKey: preset.id)
        userPresets.removeAll(where: { $0.id == preset.id })
    }
    
    func saveUserLayout() throws {
        // Save PentatoneUserLayout to Documents
        let layoutURL = userPresetsURL.appendingPathComponent("UserLayout.json")
        let data = try JSONEncoder().encode(userLayout)
        try data.write(to: layoutURL)
    }
    
    // MARK: - Slot Access
    
    /// Get preset for a specific slot (F1.1, U2.3, etc.)
    func preset(forBank bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> AudioParameterSet? {
        let layout = (type == .factory) ? factoryLayout : userLayout.userSlots
        guard let slot = layout.first(where: { $0.bank == bank && $0.position == position }) else {
            return nil
        }
        return presetLookup[slot.presetID]
    }
    
    /// Assign a preset to a user slot
    func assignPresetToSlot(preset: AudioParameterSet, bank: Int, position: Int) throws {
        guard let index = userLayout.userSlots.firstIndex(where: { 
            $0.bank == bank && $0.position == position 
        }) else {
            return
        }
        
        userLayout.userSlots[index].presetID = preset.id
        try saveUserLayout()
    }
    
    // MARK: - Export/Import
    
    func exportPreset(_ preset: AudioParameterSet) throws -> URL {
        // Export to temporary location for sharing
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(preset.name).pentatonepreset")
        let data = try JSONEncoder().encode(preset)
        try data.write(to: tempURL)
        return tempURL
    }
    
    func importPreset(from url: URL) throws -> AudioParameterSet {
        let data = try Data(contentsOf: url)
        let preset = try JSONDecoder().decode(AudioParameterSet.self, from: data)
        
        // Save to user presets
        try savePreset(preset)
        
        return preset
    }
}
```

---

## Factory Preset Creation Workflow

### **Step-by-Step Process**

#### **1. Create Preset on iPad**
- Run Pentatone app on iPad
- Tweak parameters until you have a sound you like
- Tap "Save Preset" button in UI
- Give it a descriptive name (e.g., "Ethereal Bells")
- Preset is saved to Documents with a generated UUID

#### **2. Export from iPad**
- Tap "Share" button on the preset
- Use `UIActivityViewController` to share the JSON file
- Options: AirDrop to Mac, save to Files app, email, etc.

#### **3. Add to Xcode Project (on Mac)**
- Open the exported JSON file
- **Copy the UUID** from the `id` field
- Drag the JSON file into Xcode project: `Resources/Presets/Factory/`
- Rename file to descriptive name if needed (e.g., `Ethereal Bells.json`)
- Ensure "Target Membership" is checked

#### **4. Update Factory Layout Code**
```swift
// PentatoneFactoryLayout.swift
static let factorySlots: [PentatonePresetSlot] = [
    PentatonePresetSlot(
        bank: 1, 
        position: 1, 
        presetID: UUID(uuidString: "A1B2C3D4-E5F6-...")!,  // ← Paste copied UUID here
        slotType: .factory
    ),
    // ... rest of slots
]
```

#### **5. Build and Test**
- Build app
- Factory preset now appears in F1.1 (or whichever slot you assigned)
- Preset is bundled with app and appears for all users

### **Maintaining a Preset Library**

For managing presets across multiple apps:

```
YourProjects/
├── PentatoneEngine/              ← Swift Package (future)
│   └── Sources/...
│
├── SharedPresets/                ← Central preset library
│   ├── Ethereal Bells.json
│   ├── Warm Pad.json
│   ├── Bright Lead.json
│   └── ...
│
├── PentatoneApp/                 ← iOS app project
│   └── Resources/
│       └── Presets/
│           └── Factory/          ← Copy or symlink from SharedPresets
│
├── ChromaToneApp/                ← Future app
│   └── Resources/
│       └── Presets/
│           └── Factory/          ← Copy or symlink from SharedPresets
```

**Benefits:**
- Single source of truth for all factory presets
- Easy to add new presets to all apps
- Consistent sound library across the series

---

## Cross-Device Sync & Sharing

### **iCloud Sync (Automatic)**

To enable automatic sync across user's devices:

```swift
// Instead of Documents directory, use iCloud container
private let userPresetsURL: URL? = {
    FileManager.default.url(forUbiquityContainerIdentifier: nil)?
        .appendingPathComponent("Documents")
        .appendingPathComponent("UserPresets")
}()
```

**Requirements:**
- Enable "iCloud" capability in Xcode (select "iCloud Documents")
- User must be signed into iCloud
- Handle potential conflicts if user edits same preset on two devices

**Benefits:**
- ✅ Automatic sync across iPad, iPhone, Mac (if you make a Mac version)
- ✅ Apple handles all complexity
- ✅ Works with existing `Codable` JSON files
- ✅ No code changes needed beyond using ubiquity container URL

### **Manual Preset Sharing**

Users can share presets with others via export/import:

#### **Export Flow**
```swift
func sharePreset(_ preset: AudioParameterSet) throws {
    // Export preset to temporary file
    let fileURL = try presetManager.exportPreset(preset)
    
    // Show share sheet
    let activityVC = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
    )
    present(activityVC, animated: true)
}
```

User can then:
- AirDrop to nearby devices
- Save to Files app
- Share via Messages/Email/etc.

#### **Import Flow**

1. User receives `.pentatonepreset` file
2. Taps to open it
3. iOS offers to open in Pentatone (if file type is registered)
4. App imports and saves to user presets

#### **File Type Registration**

Add to `Info.plist`:

```xml
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.yourname.pentatone.preset</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.json</string>
        </array>
        <key>UTTypeDescription</key>
        <string>Pentatone Engine Preset</string>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>pentatonepreset</string>
            </array>
        </dict>
    </dict>
</array>

<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Pentatone Preset</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.yourname.pentatone.preset</string>
        </array>
    </dict>
</array>
```

**Note:** Use the same file type registration in all your apps (Pentatone, ChromaTone, etc.) so presets can be opened in any of them.

---

## Multi-App Architecture

### **Current State (Pentatone Only)**

```
PentatoneApp/
├── Engine/                          ← Will become portable
│   ├── A1 SoundParameters.swift     ← Universal preset format
│   ├── A3 VoicePool.swift
│   ├── A5 AudioEngine.swift
│   ├── A6 ModulationSystem.swift
│   └── PresetManager.swift          ← Universal load/save logic
│
├── PentatoneApp/                    ← App-specific
│   ├── PentatoneApp.swift
│   ├── PentatonePresetLayout.swift  ← 5×5 mapping
│   ├── PresetBankView.swift         ← 5×5 UI
│   ├── PentatonicKeyboard.swift     ← Keyboard UI
│   └── Views/
│
└── Resources/
    └── Presets/
        └── Factory/                  ← 25 factory preset JSON files
```

### **Future State (Multiple Apps)**

When ready to build ChromaTone or other apps:

#### **Option 1: Extract to Swift Package**

```
PentatoneEngine/                     ← Swift Package
├── Package.swift
└── Sources/
    └── PentatoneEngine/
        ├── AudioParameterSet.swift      ← Universal preset format
        ├── AudioEngine.swift
        ├── VoicePool.swift
        ├── ModulationSystem.swift
        └── UniversalPresetManager.swift  ← Load/save presets

PentatoneApp/                        ← iOS app
├── Package Dependencies:
│   └── PentatoneEngine
├── PentatonePresetLayout.swift      ← 5×5 mapping
├── PresetBankView.swift             ← 5×5 UI
└── PentatonicKeyboard.swift

ChromaToneApp/                       ← Future iOS app
├── Package Dependencies:
│   └── PentatoneEngine              ← Same engine!
├── ChromaTonePresetLayout.swift     ← 7×7 or 0-99 mapping
├── PresetGridView.swift             ← Different UI
└── ChromaticKeyboard.swift
```

#### **Option 2: Copy Engine Code**

Simpler approach: Just copy the Engine folder into each new app project. Less elegant but easier to start with.

### **Preset Compatibility**

The same preset JSON files work in all apps:

- User creates "My Cool Sound" in Pentatone
- Exports it as `My Cool Sound.pentatonepreset`
- Opens it in ChromaTone
- ChromaTone imports it → same sound, different keyboard/layout

**What's identical:**
- ✅ Sound parameters (oscillator, filter, envelope, modulation, effects)
- ✅ JSON file format
- ✅ File extension (`.pentatonepreset`)

**What's different:**
- 🎹 Keyboard layout (pentatonic vs chromatic vs microtonal)
- 🎹 Preset organization (5×5 vs 7×7 vs 0-99)
- 🎹 UI design and user experience

---

## Implementation Checklist

### **Phase 1: Basic Preset System**

- [ ] Create `PresetManager` class
- [ ] Implement `loadFactoryPresets()` from bundle
- [ ] Implement `loadUserPresets()` from Documents
- [ ] Implement `savePreset()` to Documents
- [ ] Implement `deletePreset()` from Documents
- [ ] Create UUID → Preset lookup dictionary
- [ ] Test saving and loading presets

### **Phase 2: Pentatone Layout System**

- [ ] Create `PentatonePresetSlot` struct
- [ ] Create `PentatoneFactoryLayout` with hardcoded 5×5 grid
- [ ] Create `PentatoneUserLayout` with 25 empty slots
- [ ] Implement `preset(forBank:position:type:)` lookup
- [ ] Implement `assignPresetToSlot()` for user presets
- [ ] Save/load user layout to/from Documents

### **Phase 3: Factory Preset Creation**

- [ ] Create 25 factory presets on iPad
- [ ] Export each preset and copy UUID
- [ ] Add JSON files to Xcode project (`Resources/Presets/Factory/`)
- [ ] Update `PentatoneFactoryLayout` with all 25 UUIDs
- [ ] Test that all factory presets load correctly

### **Phase 4: UI Integration**

- [ ] Create preset browser view (list factory + user presets)
- [ ] Create 5×5 preset bank view (F1.1 - F5.5, U1.1 - U5.5)
- [ ] Add "Save Preset" dialog (name input)
- [ ] Add "Share Preset" button (export via share sheet)
- [ ] Add "Delete Preset" functionality (user presets only)
- [ ] Show preset name when loaded

### **Phase 5: Sharing & Import**

- [ ] Register `.pentatonepreset` file type in Info.plist
- [ ] Implement `exportPreset()` for sharing
- [ ] Implement `importPreset()` from file URL
- [ ] Handle app launch with preset file (import on open)
- [ ] Test AirDrop, Files app, email workflows

### **Phase 6: iCloud Sync (Optional)**

- [ ] Enable iCloud capability in Xcode
- [ ] Switch user presets to iCloud container URL
- [ ] Test sync between devices
- [ ] Handle conflicts (last-write-wins or user prompt)

---

## Key Technical Notes

### **No Database/Framework Needed**

- ✅ Use `FileManager` + `Codable` (built into Foundation)
- ✅ No SwiftData, Core Data, or other database frameworks
- ✅ JSON files are simple, portable, human-readable

### **UUID-Based Mapping**

- ✅ Use `UUID` from `AudioParameterSet.id` for mapping
- ✅ Never use names for mapping (names can duplicate/change)
- ✅ UUIDs are stable, unique identifiers

### **Name Conflicts Are Fine**

- ✅ Factory and user presets can have the same name
- ✅ Different UUIDs = no conflict in lookup
- ✅ UI can differentiate by context (Factory/User badge)

### **File Naming**

- ✅ Factory presets: Human-readable names (`Ethereal Bells.json`)
- ✅ User presets: UUID-based names (`A1B2C3D4-....json`)
- ✅ File extension: `.pentatonepreset` for sharing

### **Separation of Concerns**

- ✅ Keep `AudioParameterSet` universal (no app-specific fields)
- ✅ Keep layout/organization app-specific (separate structs)
- ✅ This enables multi-app preset compatibility

---

## Common Pitfalls to Avoid

### **❌ Don't Add App-Specific Fields to AudioParameterSet**

```swift
// BAD - breaks multi-app compatibility
struct AudioParameterSet {
    var bank: Int        // ❌ Pentatone-specific
    var position: Int    // ❌ Pentatone-specific
    var isFactory: Bool  // ❌ Context-dependent
}
```

### **❌ Don't Use Names for Mapping**

```swift
// BAD - breaks on rename/duplicates
func preset(named: String) -> AudioParameterSet? {
    return presets.first(where: { $0.name == named })  // ❌
}
```

### **❌ Don't Store All Presets in One File**

```swift
// BAD - harder to manage, worse for sync
struct PresetCollection: Codable {
    var presets: [AudioParameterSet]  // ❌ Single file with array
}
```

### **❌ Don't Hardcode File Paths**

```swift
// BAD - breaks on iOS updates
let path = "/var/mobile/Containers/Data/Application/..."  // ❌

// GOOD - use FileManager APIs
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]  // ✅
```

---

## Summary

### **What You're Building**

- 🎵 Universal preset format that works across all your apps
- 🎹 App-specific layout system (5×5 for Pentatone)
- 💾 Simple file-based storage (no database needed)
- 🔄 Preset sharing and import/export
- ☁️ Optional iCloud sync
- 📦 Easy extraction to Swift Package for future apps

### **Key Files to Create**

1. `PresetManager.swift` - Core preset loading/saving logic
2. `PentatonePresetSlot.swift` - Slot structure for 5×5 grid
3. `PentatoneFactoryLayout.swift` - Hardcoded factory preset mapping
4. `PentatoneUserLayout.swift` - User preset mapping (saved to disk)
5. Factory preset JSON files (25 files in `Resources/Presets/Factory/`)

### **Technologies Used**

- Foundation (`FileManager`, `Codable`, `JSONEncoder/Decoder`)
- SwiftUI (`@Published`, `ObservableObject`)
- UIKit (`UIActivityViewController` for sharing)
- Standard file system APIs (no special frameworks)

---

## Ready to Implement?

You now have everything you need to build the preset system. Start with Phase 1 (basic loading/saving), then progressively add features. The architecture is designed to be simple, portable, and scalable across your app series.

Good luck! 🎹🎵
