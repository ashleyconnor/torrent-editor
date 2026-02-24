# Torrent Editor

A native macOS application for creating and editing BitTorrent (.torrent) files.

## Phase 1 - MVP Implementation ✅

### Completed Features

#### 1. **Bencode Parser** (`BencodeParser.swift`)
- Full implementation of bencode encoding/decoding
- Supports all bencode types: integers, strings, lists, and dictionaries
- Proper error handling with descriptive error messages
- Helper extensions for convenient value access
- Comprehensive test suite included

#### 2. **Core Models**
- **TorrentFile** (`TorrentFile.swift`): Main model for torrent data
  - Parse existing .torrent files
  - Create new torrents from scratch
  - Calculate info hash (SHA-1)
  - Add files and directories
  - Encode to bencode format
  - Observable using Swift's `@Observable` macro
  
- **TorrentFileEntry** (`TorrentFileEntry.swift`): Represents individual files
  - Path components for hierarchical structure
  - File size tracking
  - Formatted size display
  
- **TorrentTracker** (`TorrentTracker.swift`): Tracker information
  - URL and tier support
  - Proper multi-tracker tier management

#### 3. **User Interface**
- **ContentView**: Main app container with open/new torrent functionality
- **TorrentEditorView**: Comprehensive form-based editor with sections for:
  - Metadata (name, announce URL, comment, creation date, private flag)
  - Advanced settings (piece size selection)
  - Torrent information panel (size, file count, pieces, info hash)
  - File list with add/remove capabilities
  - Validation before saving

#### 4. **File Operations**
- Open existing .torrent files and parse all fields
- Create new torrent files
- Add individual files via file picker
- Add entire folders with recursive file enumeration
- Remove files from torrent
- Save .torrent files with proper bencode encoding

#### 5. **Menu Commands & Keyboard Shortcuts**
- ⌘N - New Torrent
- ⌘O - Open Torrent
- ⌘S - Save Torrent
- Menu bar integration for all actions

#### 6. **Testing**
- Comprehensive bencode parser tests using Swift Testing framework
- Round-trip encoding/decoding verification
- Coverage for all bencode data types

### Technical Highlights

- **Pure Swift**: No external dependencies for core functionality (except Sparkle for future updates)
- **Native SwiftUI**: Modern, declarative UI with `@Observable` and `@Bindable`
- **macOS Integration**: Uses `NSOpenPanel` and `NSSavePanel` for native file dialogs
- **Type Safety**: Strong typing throughout with proper error handling
- **Computed Properties**: Automatic calculation of info hash, total size, piece count

### File Structure

```
Torrent Editor/
├── App/
│   ├── Torrent_EditorApp.swift      # Main app with menu commands
│   ├── ContentView.swift             # Main container view
│   └── Updater.swift                 # Sparkle update integration
├── Views/
│   └── TorrentEditorView.swift       # Main editor interface
├── Models/
│   ├── TorrentFile.swift             # Core torrent model
│   ├── TorrentFileEntry.swift        # File entry model
│   └── TorrentTracker.swift          # Tracker model
├── Utilities/
│   └── BencodeParser.swift           # Bencode encoding/decoding
└── Tests/
    └── BencodeParserTests.swift      # Parser test suite
```

### Usage

#### Creating a New Torrent
1. Launch the app (or press ⌘N)
2. Fill in required fields:
   - Torrent Name
   - Announce URL (tracker)
3. Add files or folders:
   - Click the "+" button in the Files section
   - Or use "Add Files..." / "Add Folder..." from the menu
4. (Optional) Adjust piece size, add comment, set private flag
5. Click "Save Torrent..." or press ⌘S

#### Editing an Existing Torrent
1. Press ⌘O or click "Open Torrent"
2. Select a .torrent file
3. All fields will be populated automatically
4. Modify as needed
5. Save with ⌘S

### Limitations & Known Issues

- **Piece Hashes**: Currently generates empty placeholder hashes. In a future phase, actual file data will be read and hashed.
- **File Tree**: Currently a flat list view. Phase 2 will add hierarchical tree structure with drag & drop.
- **Validation**: Basic validation only. More comprehensive checks coming in Phase 2.
- **No Undo/Redo**: Will be added in Phase 3.

## Next Steps: Phase 2

Phase 2 will focus on:
1. Hierarchical file tree view with expand/collapse
2. Drag and drop support for adding files
3. Multi-tracker management with tier editor
4. File tree reordering and manipulation
5. Settings/Preferences window

## Next Steps: Phase 3

Phase 3 will add:
1. Quick Look plugin for .torrent preview
2. Advanced filtering (regex, wildcard, prefix/suffix)
3. Search within torrent contents
4. Comprehensive validation with warnings
5. Magnet link generation

## Requirements

- macOS 14.0 or later
- Xcode 16.0 or later
- Swift 6.0

## License

[Add your license here]
