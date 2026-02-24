//
//  FilesTabView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftUI

struct FilesTabView: View {
    @Bindable var torrent: TorrentFile
    let onAddFiles: () -> Void
    let onAlert: (String) -> Void
    
    var body: some View {
        if torrent.files.isEmpty {
            ContentUnavailableView {
                Label("No Files Added", systemImage: "doc.badge.plus")
            } description: {
                Text("Add files or folders to include in this torrent")
            } actions: {
                Button {
                    onAddFiles()
                } label: {
                    Text("Add Files or Folders")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Hierarchical file tree
            List {
                ForEach(buildFileTree(from: torrent.files), id: \.id) { node in
                    FileTreeNodeView(
                        node: node,
                        torrent: torrent
                    )
                }
            }
            .listStyle(.inset)
        }
    }
    
    // Build a hierarchical tree structure from flat file list
    private func buildFileTree(from files: [TorrentFileEntry]) -> [FileTreeNodeItem] {
        var rootNodes: [String: FileTreeNodeItem] = [:]
        
        for file in files {
            guard !file.path.isEmpty else { continue }
            
            if file.path.count == 1 {
                // Single file at root
                let node = FileTreeNodeItem(
                    name: file.path[0],
                    isFolder: false,
                    size: file.length,
                    fileEntry: file
                )
                rootNodes[file.path[0]] = node
            } else {
                // Nested file - build folder structure
                let rootName = file.path[0]
                if rootNodes[rootName] == nil {
                    rootNodes[rootName] = FileTreeNodeItem(
                        name: rootName,
                        isFolder: true,
                        size: 0
                    )
                }
                
                insertIntoTree(file: file, pathIndex: 1, into: &rootNodes[rootName]!.children)
            }
        }
        
        return rootNodes.values.sorted { $0.name < $1.name }
    }
    
    private func insertIntoTree(file: TorrentFileEntry, pathIndex: Int, into children: inout [FileTreeNodeItem]) {
        let name = file.path[pathIndex]
        
        if pathIndex == file.path.count - 1 {
            // This is the file itself
            let node = FileTreeNodeItem(
                name: name,
                isFolder: false,
                size: file.length,
                fileEntry: file
            )
            children.append(node)
        } else {
            // This is a folder
            if let existingIndex = children.firstIndex(where: { $0.name == name && $0.isFolder }) {
                insertIntoTree(file: file, pathIndex: pathIndex + 1, into: &children[existingIndex].children)
            } else {
                var newFolder = FileTreeNodeItem(
                    name: name,
                    isFolder: true,
                    size: 0
                )
                insertIntoTree(file: file, pathIndex: pathIndex + 1, into: &newFolder.children)
                children.append(newFolder)
            }
        }
    }
    
    private func iconName(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "film"
        case "mp3", "m4a", "wav", "aac", "flac":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return "photo"
        case "pdf":
            return "doc.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "txt", "md", "rtf":
            return "doc.text"
        case "srt", "sub", "idx", "ass":
            return "text.bubble"
        default:
            return "doc"
        }
    }
    
    private func iconColor(for filename: String) -> Color {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "m4v":
            return .orange
        case "mp3", "m4a", "wav", "aac", "flac":
            return .pink
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return .blue
        case "pdf":
            return .red
        case "zip", "rar", "7z", "tar", "gz":
            return .purple
        case "srt", "sub", "idx", "ass":
            return .green
        default:
            return .secondary
        }
    }
}

// MARK: - Tree Node Model

struct FileTreeNodeItem: Identifiable {
    let id = UUID()
    let name: String
    let isFolder: Bool
    let size: Int
    var children: [FileTreeNodeItem] = []
    let fileEntry: TorrentFileEntry?
    
    init(name: String, isFolder: Bool, size: Int, fileEntry: TorrentFileEntry? = nil) {
        self.name = name
        self.isFolder = isFolder
        self.size = size
        self.fileEntry = fileEntry
    }
    
    var totalSize: Int {
        if isFolder {
            return children.reduce(0) { $0 + $1.totalSize }
        } else {
            return size
        }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    var fileCount: Int {
        if isFolder {
            return children.reduce(0) { count, child in
                count + (child.isFolder ? child.fileCount : 1)
            }
        } else {
            return 1
        }
    }
}

// MARK: - Tree Node View

struct FileTreeNodeView: View {
    let node: FileTreeNodeItem
    @Bindable var torrent: TorrentFile
    @State private var isExpanded = true
    @State private var isHovering = false
    
    var body: some View {
        if node.isFolder {
            // Folder
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children.sorted { $0.name < $1.name }, id: \.id) { child in
                    FileTreeNodeView(node: child, torrent: torrent)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(node.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("\(node.fileCount) files, \(node.formattedSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
                )
                .onHover { hovering in
                    isHovering = hovering
                }
            }
            .disclosureGroupStyle(AlignedDisclosureStyle())
        } else {
            // File
            HStack(spacing: 8) {
                Image(systemName: iconName(for: node.name))
                    .foregroundStyle(iconColor(for: node.name))
                    .frame(width: 20)
                
                Text(node.name)
                    .font(.body)
                
                Spacer()
                
                Text(node.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
            )
            .onHover { hovering in
                isHovering = hovering
            }
            .contextMenu {
                if let file = node.fileEntry {
                    Button("Remove", role: .destructive) {
                        if let index = torrent.files.firstIndex(where: { $0.id == file.id }) {
                            torrent.removeFile(at: index)
                        }
                    }
                }
            }
        }
    }
    
    private func iconName(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "film"
        case "mp3", "m4a", "wav", "aac", "flac":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return "photo"
        case "pdf":
            return "doc.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "txt", "md", "rtf":
            return "doc.text"
        case "srt", "sub", "idx", "ass":
            return "text.bubble"
        default:
            return "doc"
        }
    }
    
    private func iconColor(for filename: String) -> Color {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "m4v":
            return .orange
        case "mp3", "m4a", "wav", "aac", "flac":
            return .pink
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return .blue
        case "pdf":
            return .red
        case "zip", "rar", "7z", "tar", "gz":
            return .purple
        case "srt", "sub", "idx", "ass":
            return .green
        default:
            return .secondary
        }
    }
}

// MARK: - Aligned Disclosure Style

struct AlignedDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        configuration.isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                configuration.label
            }
            
            if configuration.isExpanded {
                configuration.content
                    .padding(.leading, 24) // Align children with parent content (20px icon + 4px spacing)
            }
        }
    }
}

#Preview {
    let torrent = TorrentFile()
    FilesTabView(torrent: torrent, onAddFiles: {}, onAlert: { _ in })
}
