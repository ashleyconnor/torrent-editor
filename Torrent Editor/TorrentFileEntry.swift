//
//  TorrentFileEntry.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation

struct TorrentFileEntry: Identifiable, Hashable {
  var id: String { fullPath }  // Use path as stable identifier
  var path: [String]  // Path components (e.g., ["folder", "subfolder", "file.txt"])
  var length: Int  // File size in bytes

  var displayName: String {
    path.last ?? ""
  }

  var fullPath: String {
    path.joined(separator: "/")
  }

  var formattedSize: String {
    ByteCountFormatter.string(fromByteCount: Int64(length), countStyle: .file)
  }

  init(path: [String], length: Int) {
    self.path = path
    self.length = length
  }

  init(path: String, length: Int) {
    self.path = path.split(separator: "/").map(String.init)
    self.length = length
  }
}
