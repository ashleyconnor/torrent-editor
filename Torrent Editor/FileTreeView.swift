//
//  FileTreeView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftUI

struct FileTreeView: View {
    let nodes: [FileTreeNode]
    let onToggle: (FileTreeNode) -> Void
    let onRemove: (FileTreeNode) -> Void
    
    var body: some View {
        List {
            ForEach(nodes) { node in
                FileTreeRow(
                    node: node,
                    onToggle: onToggle,
                    onRemove: onRemove
                )
            }
        }
        .listStyle(.inset)
    }
}

struct FileTreeRow: View {
    let node: FileTreeNode
    let onToggle: (FileTreeNode) -> Void
    let onRemove: (FileTreeNode) -> Void
    @State private var isExpanded: Bool = true
    
    var body: some View {
        switch node {
        case .file(let fileNode):
            FileRowView(file: fileNode, onRemove: { onRemove(node) })
                
        case .folder(let folderNode):
            FolderRowView(
                folder: folderNode,
                isExpanded: $isExpanded,
                onToggle: onToggle,
                onRemove: onRemove
            )
        }
    }
}

struct FileRowView: View {
    let file: FileNode
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // File icon
            Image(systemName: iconName(for: file.fileExtension))
                .foregroundStyle(iconColor(for: file.fileExtension))
                .frame(width: 20)
            
            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                
                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove file")
        }
        .padding(.vertical, 2)
    }
    
    private func iconName(for ext: String) -> String {
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
    
    private func iconColor(for ext: String) -> Color {
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

struct FolderRowView: View {
    let folder: FolderNode
    @Binding var isExpanded: Bool
    let onToggle: (FileTreeNode) -> Void
    let onRemove: (FileTreeNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            HStack(spacing: 8) {
                // Disclosure indicator
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Folder icon
                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                
                // Folder name and info
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("\(folder.fileCount) files, \(folder.formattedSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Remove button
                Button(action: { onRemove(.folder(folder)) }) {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove folder")
            }
            .padding(.vertical, 4)
            
            // Children (if expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(folder.children) { child in
                        FileTreeRow(
                            node: child,
                            onToggle: onToggle,
                            onRemove: onRemove
                        )
                        .padding(.leading, 24)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var nodes: [FileTreeNode] = [
        .folder(FolderNode(
            name: "Foo",
            path: ["Foo"],
            children: [
                .file(FileNode(name: "output_2.mp4", size: 1_900_000_000, path: ["Foo", "output_2.mp4"])),
                .folder(FolderNode(
                    name: "subtitles",
                    path: ["Foo", "subtitles"],
                    children: [
                        .file(FileNode(name: "eng_new.srt", size: 47_000, path: ["Foo", "subtitles", "eng_new.srt"])),
                        .file(FileNode(name: "eng.idx", size: 35_000, path: ["Foo", "subtitles", "eng.idx"])),
                        .file(FileNode(name: "eng.srt", size: 47_000, path: ["Foo", "subtitles", "eng.srt"])),
                        .file(FileNode(name: "eng.sub", size: 2_600_000, path: ["Foo", "subtitles", "eng.sub"]))
                    ]
                ))
            ]
        ))
    ]
    
    FileTreeView(
        nodes: nodes,
        onToggle: { _ in },
        onRemove: { _ in }
    )
    .frame(width: 600, height: 400)
}
