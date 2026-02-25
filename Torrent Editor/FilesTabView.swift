//
//  FilesTabView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftListTreeDataSource
import SwiftUI

struct FilesTabView: View {
  @Bindable var torrent: TorrentFile
  let onAddFiles: () -> Void
  let onAlert: (String) -> Void

  @State private var dataSource = ListTreeDataSource<FileTreeNode>()
  @State private var treeItems: [TreeItem<FileTreeNode>] = []

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
      List {
        ForEach(treeItems) { item in
          FileTreeRowView(
            item: item,
            torrent: torrent,
            onToggle: {
              dataSource.toggleExpand(item: item)
              treeItems = dataSource.items
            }
          )
        }
      }
      .listStyle(.inset)
      .onChange(of: torrent.files) { _, _ in
        rebuildTree()
      }
      .onAppear {
        rebuildTree()
      }
    }
  }

  private func rebuildTree() {
    // Build tree from files
    let nodes = FileTreeNode.buildTree(from: torrent.files)

    // Create new data source
    dataSource = ListTreeDataSource<FileTreeNode>()

    // Add root nodes
    dataSource.append(nodes)

    // Recursively add children
    for node in nodes {
      addChildren(node: node, to: node)
    }

    // Expand all folders by default
    dataSource.expandAll()

    // Update displayed items
    treeItems = dataSource.items
  }

  private func addChildren(node: FileTreeNode, to parent: FileTreeNode) {
    guard case .folder(let folder) = node else { return }

    // Add this folder's children to the data source
    dataSource.append(folder.children, to: parent)

    // Recursively add children of folders
    for child in folder.children {
      addChildren(node: child, to: child)
    }
  }

  private func removeFile(node: FileTreeNode) {
    let pathToRemove = node.path
    let fullPath = pathToRemove.joined(separator: "/")

    // Remove from torrent.files
    torrent.files.removeAll { $0.fullPath == fullPath }

    // Rebuild tree
    rebuildTree()
  }
}

// MARK: - File Tree Row View

struct FileTreeRowView: View {
  let item: TreeItem<FileTreeNode>
  @Bindable var torrent: TorrentFile
  let onToggle: () -> Void

  @State private var isHovering = false

  var body: some View {
    HStack(spacing: 4) {
      // Indentation
      ForEach(0..<item.level, id: \.self) { _ in
        Spacer()
          .frame(width: 24)
      }

      // Disclosure indicator for folders
      if item.value.isFolder {
        Button {
          onToggle()
        } label: {
          Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
            .foregroundStyle(.secondary)
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      } else {
        Spacer()
          .frame(width: 20)
      }

      // Icon
      Image(systemName: iconName(for: item.value))
        .foregroundStyle(iconColor(for: item.value))
        .frame(width: 20)

      // Name and size
      if item.value.isFolder {
        VStack(alignment: .leading, spacing: 0) {
          Text(item.value.name)
            .font(.body)
            .fontWeight(.medium)

          if case .folder(let folder) = item.value {
            Text("\(folder.fileCount) files, \(folder.formattedSize)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } else {
        Text(item.value.name)
          .font(.body)
      }

      Spacer()

      // File size (for files only)
      if !item.value.isFolder {
        if case .file(let file) = item.value {
          Text(file.formattedSize)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
    )
    .onHover { hovering in
      isHovering = hovering
    }
    .contextMenu {
      if item.value.isFolder {
        // Context menu for folders
        Button("Remove Folder", role: .destructive) {
          let folderPath = item.value.path
          let folderPathPrefix = folderPath.joined(separator: "/") + "/"

          // Remove all files that start with this folder path
          torrent.files.removeAll { file in
            let filePath = file.fullPath
            // Check if this file is within the folder
            return filePath.hasPrefix(folderPathPrefix)
              || filePath == folderPath.joined(separator: "/")
          }
        }
      } else {
        // Context menu for files
        Button("Remove", role: .destructive) {
          let pathToRemove = item.value.path
          let fullPath = pathToRemove.joined(separator: "/")
          torrent.files.removeAll { $0.fullPath == fullPath }
        }
      }
    }
  }

  private func iconName(for node: FileTreeNode) -> String {
    switch node {
    case .folder:
      return "folder.fill"
    case .file(let file):
      let ext = file.fileExtension
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
  }

  private func iconColor(for node: FileTreeNode) -> Color {
    switch node {
    case .folder:
      return .blue
    case .file(let file):
      let ext = file.fileExtension
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
}

#Preview {
  let torrent = TorrentFile()
  FilesTabView(torrent: torrent, onAddFiles: {}, onAlert: { _ in })
}
