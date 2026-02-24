# Torrent Editor - Architecture Overview

## App Structure

```
┌─────────────────────────────────────────────┐
│         Torrent_EditorApp.swift             │
│  - Main App Entry Point                     │
│  - Menu Commands (⌘N, ⌘O, ⌘S)              │
│  - Sparkle Update Integration               │
└─────────────────────────────────────────────┘
                    │
                    ├─ Commands ──> NotificationCenter
                    │
                    └─ WindowGroup
                         │
                         ▼
         ┌───────────────────────────────────┐
         │      ContentView.swift            │
         │  - Main Container                 │
         │  - Handles Open/New               │
         │  - Manages TorrentFile State      │
         └───────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────────┐
         │   TorrentEditorView.swift         │
         │  - Form-based Editor              │
         │  - Metadata Fields                │
         │  - File List Management           │
         │  - Save Operations                │
         └───────────────────────────────────┘
                         │
                         │ Binds To
                         ▼
         ┌───────────────────────────────────┐
         │     TorrentFile.swift             │
         │  @Observable Model                │
         │  - Parse/Encode Torrents          │
         │  - File Management                │
         │  - Info Hash Calculation          │
         │  - Validation Logic               │
         └───────────────────────────────────┘
                         │
                         ├─ Contains
                         ├─> [TorrentFileEntry]
                         └─> [TorrentTracker]
```

## Data Flow

### Opening a Torrent
```
User (⌘O) 
  → ContentView.openTorrent()
    → NSOpenPanel.runModal()
      → Data(contentsOf: url)
        → TorrentFile.parse(from: data)
          → BencodeParser.decode(data)
            → TorrentFile populated
              → View updates automatically (@Observable)
```

### Creating & Saving a Torrent
```
User (⌘N)
  → ContentView.createNewTorrent()
    → torrentFile = TorrentFile()
      → User fills form
        → TorrentEditorView updates model (@Bindable)
          → User clicks "Save" (⌘S)
            → TorrentFile.encode()
              → BencodeParser.encode()
                → Data written to disk
```

### Adding Files
```
User clicks "+" button
  → TorrentEditorView.addFiles()
    → NSOpenPanel.runModal()
      → User selects files/folder
        → TorrentFile.addFile() or addDirectory()
          → FileManager enumerates files
            → TorrentFileEntry created for each
              → files array updated
                → View refreshes
                  → Info panel recalculates
```

## Model Relationships

```
TorrentFile (@Observable)
│
├── name: String
├── announceURL: String
├── comment: String
├── createdBy: String
├── creationDate: Date
├── isPrivate: Bool
├── pieceLength: Int
│
├── files: [TorrentFileEntry]
│   └── TorrentFileEntry
│       ├── id: UUID
│       ├── path: [String]
│       └── length: Int
│
└── trackers: [TorrentTracker]
    └── TorrentTracker
        ├── id: UUID
        ├── url: String
        └── tier: Int

Computed Properties:
├── totalSize: Int
├── numberOfPieces: Int
├── formattedTotalSize: String
└── isSingleFile: Bool
```

## Bencode Structure

### Parsing Flow
```
Data (bytes)
  │
  └─> BencodeParser.decode()
       │
       └─> BencodeValue (enum)
            ├─ .integer(Int)
            ├─ .string(Data)
            ├─ .list([BencodeValue])
            └─ .dictionary([String: BencodeValue])
```

### Torrent File Structure
```
Dictionary {
  "announce": String
  "announce-list": List[List[String]]  // Multi-tier trackers
  "comment": String
  "created by": String
  "creation date": Integer
  "info": Dictionary {
    "name": String
    "piece length": Integer
    "pieces": Data (SHA-1 hashes)
    "private": Integer (0 or 1)
    
    // Single file:
    "length": Integer
    
    // OR Multi-file:
    "files": List[
      Dictionary {
        "length": Integer
        "path": List[String]
      }
    ]
  }
}
```

## UI Component Hierarchy

```
TorrentEditorView (Form)
│
├── Section: "Metadata"
│   ├── TextField: name
│   ├── TextField: announceURL (with validation)
│   ├── TextField: comment
│   ├── TextField: createdBy
│   ├── DatePicker: creationDate
│   └── Toggle: isPrivate
│
├── Section: "Advanced Settings"
│   └── Picker: pieceLength
│       └── Button: "Use Recommended" (conditional)
│
├── Section: "Torrent Information"
│   ├── LabeledContent: Total Size
│   ├── LabeledContent: Number of Files
│   ├── LabeledContent: Number of Pieces
│   └── LabeledContent: Info Hash
│
└── Section: "Files"
    ├── Header: Menu (+)
    │   ├── "Add Files..."
    │   └── "Add Folder..."
    │
    └── List
        └── ForEach(files)
            └── HStack
                ├── Image: doc icon
                ├── VStack
                │   ├── Text: file name
                │   └── Text: full path
                └── Text: file size
```

## Utilities & Helpers

```
TorrentUtilities (enum)
│
├── recommendedPieceSize(for:) → Int
├── formatPieceSize(_:) → String
├── isValidPieceSize(_:) → Bool
├── isValidAnnounceURL(_:) → Bool
├── generateMagnetLink(...) → String
│
├── standardPieceSizes: [Int]
└── commonTrackers: [String]
```

## State Management

### Observable Pattern
```
@Observable
class TorrentFile {
  var name: String { didSet { /* view auto-updates */ } }
  // ... other properties
}

struct TorrentEditorView: View {
  @Bindable var torrent: TorrentFile
  
  TextField("Name", text: $torrent.name)
  // Two-way binding, automatic updates
}
```

### Notification-Based Commands
```
Menu Command (⌘S)
  → NotificationCenter.post(.saveTorrent)
    → TorrentEditorView.onReceive(.saveTorrent)
      → saveTorrent()
```

## File Operations Flow

### Add Directory
```
1. User selects folder via NSOpenPanel
2. FileManager.enumerator(at: url)
3. For each file in tree:
   - Get file size via resourceValues
   - Calculate relative path from root
   - Create TorrentFileEntry
   - Append to files array
4. Set torrent name to folder name
5. View updates automatically
6. Piece size recommendation appears
```

### Save Torrent
```
1. Validation check (isValid)
2. Show NSSavePanel
3. TorrentFile.encode()
   - Build bencode dictionary
   - Add all metadata
   - Create info dictionary
   - Generate pieces placeholder
   - BencodeParser.encode()
4. Write Data to disk
5. Handle errors via alert
```

## Testing Strategy

```
BencodeParserTests (@Suite)
│
├── Parse Tests
│   ├── Integer (positive, negative)
│   ├── String (various lengths)
│   ├── List (nested, empty)
│   └── Dictionary (complex)
│
├── Encode Tests
│   ├── All types
│   └── Dictionary key sorting
│
└── Round-trip Tests
    └── Encode → Decode → Compare
```

## Error Handling

```
BencodeError (enum: LocalizedError)
├── .invalidFormat
├── .unexpectedEndOfData
├── .invalidInteger
├── .invalidString
├── .invalidDictionary
├── .missingKey(String)
└── .invalidType(expected: String)

Each error provides:
- errorDescription: String?
- Displayed to user via Alert
```

## Future Extension Points

### Phase 2 Hooks
- File tree: Use `TorrentFileEntry.path` for hierarchy
- Drag & drop: `.onDrop()` modifier target
- Multi-tracker: Expand `TorrentTracker` array editing
- Settings: Create `@AppStorage` properties

### Phase 3 Hooks
- Quick Look: `QLPreviewProvider` for .torrent type
- Magnet links: `TorrentUtilities.generateMagnetLink()`
- Piece hashing: Replace placeholder in `encode()`
- Validation: Expand `TorrentUtilities` with more checks

## Performance Considerations

### Current Bottlenecks
- Large file enumeration (addDirectory)
- Bencode parsing of huge torrents
- Info hash calculation on every change

### Optimization Opportunities (Future)
- Lazy file enumeration with progress
- Debounced info hash calculation
- Virtual/lazy list for file display
- Background parsing with async/await

---

This architecture provides a solid foundation for Phase 2 and beyond!
