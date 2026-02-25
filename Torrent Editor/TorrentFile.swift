//
//  TorrentFile.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import CryptoKit
import Foundation
import SwiftUI

@Observable
final class TorrentFile {
  // Announce URLs (trackers)
  var trackers: [TorrentTracker] = []

  // Main announce URL (first tracker in tier 0)
  var announceURL: String {
    get {
      trackers.first(where: { $0.tier == 0 })?.url ?? ""
    }
    set {
      if let index = trackers.firstIndex(where: { $0.tier == 0 }) {
        trackers[index].url = newValue
      } else {
        trackers.insert(TorrentTracker(url: newValue, tier: 0), at: 0)
      }
    }
  }

  // Optional metadata
  var comment: String = ""
  var createdBy: String = ""
  var creationDate: Date = Date()
  var isPrivate: Bool = false

  // Piece size (in bytes, must be power of 2)
  var pieceLength: Int = PieceSize.kb256.bytes  // 256 KB default

  // Files included in the torrent
  var files: [TorrentFileEntry] = []

  // Torrent name (for multi-file torrents, this is the root folder name)
  var name: String = ""

  // Source URL (if applicable)
  var sourceURL: URL?

  // Computed properties
  var totalSize: Int {
    files.reduce(0) { $0 + $1.length }
  }

  var formattedTotalSize: String {
    ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
  }

  var numberOfPieces: Int {
    guard pieceLength > 0 else { return 0 }
    return (totalSize + pieceLength - 1) / pieceLength
  }

  var isSingleFile: Bool {
    files.count == 1
  }

  init() {
    // Set default "Created By" to app name and version
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      createdBy = "Torrent Editor \(appVersion)"
    } else {
      createdBy = "Torrent Editor"
    }
  }

  // MARK: - Parsing

  static func parse(from data: Data) throws -> TorrentFile {
    let torrentFile = TorrentFile()

    let bencode = try BencodeParser.decode(data)

    guard let dict = bencode.dictionaryValue else {
      throw BencodeError.invalidFormat
    }

    // Parse announce URL
    if let announce = dict["announce"]?.stringValue {
      torrentFile.announceURL = announce
    }

    // Parse announce-list (multiple trackers with tiers)
    if let announceList = dict["announce-list"]?.listValue {
      var tier = 0
      for tierList in announceList {
        if let urls = tierList.listValue {
          for urlValue in urls {
            if let url = urlValue.stringValue {
              torrentFile.trackers.append(TorrentTracker(url: url, tier: tier))
            }
          }
          tier += 1
        }
      }
    }

    // If no announce-list, use single announce
    if torrentFile.trackers.isEmpty, !torrentFile.announceURL.isEmpty {
      torrentFile.trackers.append(TorrentTracker(url: torrentFile.announceURL, tier: 0))
    }

    // Parse optional metadata
    if let comment = dict["comment"]?.stringValue {
      torrentFile.comment = comment
    }

    if let createdBy = dict["created by"]?.stringValue {
      torrentFile.createdBy = createdBy
    }

    if let creationTimestamp = dict["creation date"]?.integerValue {
      torrentFile.creationDate = Date(timeIntervalSince1970: TimeInterval(creationTimestamp))
    }

    // Parse info dictionary
    guard let info = dict["info"]?.dictionaryValue else {
      throw BencodeError.missingKey("info")
    }

    // Parse name
    if let name = info["name"]?.stringValue {
      torrentFile.name = name
    }

    // Parse piece length
    if let pieceLength = info["piece length"]?.integerValue {
      torrentFile.pieceLength = pieceLength
    }

    // Parse private flag
    if let privateFlag = info["private"]?.integerValue {
      torrentFile.isPrivate = privateFlag == 1
    }

    // Parse files
    if let files = info["files"]?.listValue {
      // Multi-file torrent
      for fileValue in files {
        guard let fileDict = fileValue.dictionaryValue,
          let length = fileDict["length"]?.integerValue,
          let pathList = fileDict["path"]?.listValue
        else {
          continue
        }

        let pathComponents = pathList.compactMap { $0.stringValue }
        torrentFile.files.append(TorrentFileEntry(path: pathComponents, length: length))
      }
    } else if let length = info["length"]?.integerValue {
      // Single-file torrent
      torrentFile.files.append(TorrentFileEntry(path: [torrentFile.name], length: length))
    }

    return torrentFile
  }

  // MARK: - Encoding

  func encode() -> Data {
    var mainDict: [String: BencodeValue] = [:]

    // Add announce URL
    if !announceURL.isEmpty {
      mainDict["announce"] = .string(announceURL.data(using: .utf8)!)
    }

    // Add announce-list if we have multiple trackers
    let groupedByTier = Dictionary(grouping: trackers, by: { $0.tier })
    if groupedByTier.count > 1 || (groupedByTier.count == 1 && trackers.count > 1) {
      let announceList: [BencodeValue] = groupedByTier.keys.sorted().map { tier in
        let urls = groupedByTier[tier]!.map { tracker in
          BencodeValue.string(tracker.url.data(using: .utf8)!)
        }
        return .list(urls)
      }
      mainDict["announce-list"] = .list(announceList)
    }

    // Add optional metadata
    if !comment.isEmpty {
      mainDict["comment"] = .string(comment.data(using: .utf8)!)
    }

    if !createdBy.isEmpty {
      mainDict["created by"] = .string(createdBy.data(using: .utf8)!)
    }

    mainDict["creation date"] = .integer(Int(creationDate.timeIntervalSince1970))

    // Build info dictionary
    var infoDict: [String: BencodeValue] = [:]

    infoDict["name"] = .string(name.data(using: .utf8)!)
    infoDict["piece length"] = .integer(pieceLength)

    if isPrivate {
      infoDict["private"] = .integer(1)
    }

    // Add files
    if files.count == 1 {
      // Single file torrent
      infoDict["length"] = .integer(files[0].length)
    } else {
      // Multi-file torrent
      let filesArray: [BencodeValue] = files.map { file in
        var fileDict: [String: BencodeValue] = [:]
        fileDict["length"] = .integer(file.length)
        fileDict["path"] = .list(file.path.map { .string($0.data(using: .utf8)!) })
        return .dictionary(fileDict)
      }
      infoDict["files"] = .list(filesArray)
    }

    // For now, create empty pieces (this would normally contain SHA-1 hashes of each piece)
    // In a real implementation, you'd calculate these from the actual file data
    let piecesData = Data(repeating: 0, count: numberOfPieces * 20)  // 20 bytes per SHA-1 hash
    infoDict["pieces"] = .string(piecesData)

    mainDict["info"] = .dictionary(infoDict)

    return BencodeParser.encode(.dictionary(mainDict))
  }

  // MARK: - Info Hash Calculation

  func calculateInfoHash() -> String? {
    // Return nil if torrent has no files or no name
    guard !files.isEmpty, !name.isEmpty else {
      return nil
    }

    // Encode just the info dictionary
    var infoDict: [String: BencodeValue] = [:]

    guard let nameData = name.data(using: .utf8) else {
      return nil
    }

    infoDict["name"] = .string(nameData)
    infoDict["piece length"] = .integer(pieceLength)

    if isPrivate {
      infoDict["private"] = .integer(1)
    }

    if files.count == 1 {
      infoDict["length"] = .integer(files[0].length)
    } else {
      let filesArray: [BencodeValue] = files.map { file in
        var fileDict: [String: BencodeValue] = [:]
        fileDict["length"] = .integer(file.length)
        fileDict["path"] = .list(file.path.map { .string($0.data(using: .utf8)!) })
        return .dictionary(fileDict)
      }
      infoDict["files"] = .list(filesArray)
    }

    let piecesData = Data(repeating: 0, count: numberOfPieces * 20)
    infoDict["pieces"] = .string(piecesData)

    let encodedInfo = BencodeParser.encode(.dictionary(infoDict))

    // Calculate SHA-1 hash
    let hash = Insecure.SHA1.hash(data: encodedInfo)
    return hash.map { String(format: "%02x", $0) }.joined()
  }

  // MARK: - File Operations

  func addFile(url: URL) throws {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let fileSize = attributes[.size] as? Int else {
      throw NSError(
        domain: "TorrentFile", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not determine file size"])
    }

    let fileName = url.lastPathComponent
    let entry = TorrentFileEntry(path: [fileName], length: fileSize)
    files.append(entry)

    // If this is the first file and name is empty, use the filename as torrent name
    if files.count == 1 && name.isEmpty {
      name = fileName
    }
  }

  func addDirectory(url: URL) throws {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(
      at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])

    let rootName = url.lastPathComponent

    while let fileURL = enumerator?.nextObject() as? URL {
      let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])

      guard let isDirectory = resourceValues.isDirectory, !isDirectory else {
        continue  // Skip directories
      }

      guard let fileSize = resourceValues.fileSize else {
        continue
      }

      // Calculate relative path from the root directory
      let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
      let pathComponents = [rootName] + relativePath.split(separator: "/").map(String.init)

      let entry = TorrentFileEntry(path: pathComponents, length: fileSize)
      files.append(entry)
    }

    // Set torrent name to directory name
    if name.isEmpty {
      name = rootName
    }
  }

  func removeFile(at index: Int) {
    guard index < files.count else { return }
    files.remove(at: index)
  }

  func removeFiles(at offsets: IndexSet) {
    files.remove(atOffsets: offsets)
  }
}
