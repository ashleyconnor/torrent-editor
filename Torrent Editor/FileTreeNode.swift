//
//  FileTreeNode.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation
import UniformTypeIdentifiers

enum FileTreeNode: Identifiable {
  case file(FileNode)
  case folder(FolderNode)

  var id: UUID {
    switch self {
    case .file(let node): return node.id
    case .folder(let node): return node.id
    }
  }

  var name: String {
    switch self {
    case .file(let node): return node.name
    case .folder(let node): return node.name
    }
  }

  var size: Int {
    switch self {
    case .file(let node): return node.size
    case .folder(let node): return node.totalSize
    }
  }

  var path: [String] {
    switch self {
    case .file(let node): return node.path
    case .folder(let node): return node.path
    }
  }

  var isFolder: Bool {
    if case .folder = self { return true }
    return false
  }
}

extension FileTreeNode: Hashable {
  static func == (lhs: FileTreeNode, rhs: FileTreeNode) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct FileNode: Identifiable, Hashable {
  let id = UUID()
  var name: String
  var size: Int
  var path: [String]
  var isIncluded: Bool = true

  var fileExtension: String {
    (name as NSString).pathExtension.lowercased()
  }

  var contentType: UTType? {
    UTType(filenameExtension: fileExtension)
  }

  var formattedSize: String {
    ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
  }
}

struct FolderNode: Identifiable, Hashable {
  let id = UUID()
  var name: String
  var path: [String]
  var children: [FileTreeNode]
  var isExpanded: Bool = true
  var isIncluded: Bool = true

  var totalSize: Int {
    children.reduce(0) { $0 + $1.size }
  }

  var formattedSize: String {
    ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
  }

  var fileCount: Int {
    children.reduce(0) { count, child in
      if case .folder(let folder) = child {
        return count + folder.fileCount
      } else {
        return count + 1
      }
    }
  }
}

// MARK: - Tree Building

extension FileTreeNode {
  static func buildTree(from entries: [TorrentFileEntry]) -> [FileTreeNode] {
    guard !entries.isEmpty else { return [] }

    // Group entries by their root folder
    var rootMap: [String: [TorrentFileEntry]] = [:]

    for entry in entries {
      guard !entry.path.isEmpty else { continue }

      let rootKey = entry.path[0]
      if rootMap[rootKey] == nil {
        rootMap[rootKey] = []
      }
      rootMap[rootKey]?.append(entry)
    }

    // Build nodes for each root item
    var nodes: [FileTreeNode] = []

    for (rootName, rootEntries) in rootMap.sorted(by: { $0.key < $1.key }) {
      if rootEntries.count == 1 && rootEntries[0].path.count == 1 {
        // Single file at root
        let entry = rootEntries[0]
        let fileNode = FileNode(
          name: entry.path[0],
          size: entry.length,
          path: entry.path
        )
        nodes.append(.file(fileNode))
      } else {
        // Folder with children
        let children = buildChildren(from: rootEntries, parentPath: [rootName])
        let folder = FolderNode(
          name: rootName,
          path: [rootName],
          children: children
        )
        nodes.append(.folder(folder))
      }
    }

    return nodes
  }

  private static func buildChildren(from entries: [TorrentFileEntry], parentPath: [String])
    -> [FileTreeNode]
  {
    // Group entries by their immediate child under parentPath
    var childMap: [String: [TorrentFileEntry]] = [:]

    let parentDepth = parentPath.count

    for entry in entries {
      guard entry.path.count > parentDepth else { continue }

      // Check if this entry is under the parent path
      let matchesParent = zip(entry.path, parentPath).allSatisfy { $0 == $1 }
      guard matchesParent else { continue }

      let childName = entry.path[parentDepth]
      if childMap[childName] == nil {
        childMap[childName] = []
      }
      childMap[childName]?.append(entry)
    }

    var children: [FileTreeNode] = []

    for (childName, childEntries) in childMap.sorted(by: { $0.key < $1.key }) {
      if childEntries.count == 1 && childEntries[0].path.count == parentDepth + 1 {
        // Single file
        let entry = childEntries[0]
        let fileNode = FileNode(
          name: childName,
          size: entry.length,
          path: entry.path
        )
        children.append(.file(fileNode))
      } else {
        // Folder with more children
        let subPath = parentPath + [childName]
        let subChildren = buildChildren(from: childEntries, parentPath: subPath)
        let folder = FolderNode(
          name: childName,
          path: subPath,
          children: subChildren
        )
        children.append(.folder(folder))
      }
    }

    return children
  }
}
