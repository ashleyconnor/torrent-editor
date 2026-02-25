//
//  TorrentUtilities.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation

/// Standard piece sizes for BitTorrent files
enum PieceSize: Int, CaseIterable, Identifiable {
    case kb16 = 16_384  // 16 KB
    case kb32 = 32_768  // 32 KB
    case kb64 = 65_536  // 64 KB
    case kb128 = 131_072  // 128 KB
    case kb256 = 262_144  // 256 KB
    case kb512 = 524_288  // 512 KB
    case mb1 = 1_048_576  // 1 MB
    case mb2 = 2_097_152  // 2 MB
    case mb4 = 4_194_304  // 4 MB
    case mb8 = 8_388_608  // 8 MB
    case mb16 = 16_777_216  // 16 MB

    var id: Int { rawValue }

    /// The size in bytes
    var bytes: Int { rawValue }

    /// Human-readable description
    var description: String {
        let kb = rawValue / 1024
        if kb < 1024 {
            return "\(kb) KB"
        } else {
            let mb = kb / 1024
            return "\(mb) MB"
        }
    }

    /// Recommends an optimal piece size based on the total torrent size
    /// Following BitTorrent best practices
    static func recommended(for totalSize: Int) -> PieceSize {
        switch totalSize {
        case 0..<16_777_216:  // < 16 MB
            return .kb16
        case 16_777_216..<33_554_432:  // 16-32 MB
            return .kb32
        case 33_554_432..<67_108_864:  // 32-64 MB
            return .kb64
        case 67_108_864..<134_217_728:  // 64-128 MB
            return .kb128
        case 134_217_728..<268_435_456:  // 128-256 MB
            return .kb256
        case 268_435_456..<536_870_912:  // 256-512 MB
            return .kb512
        case 536_870_912..<1_073_741_824:  // 512 MB-1 GB
            return .mb1
        case 1_073_741_824..<2_147_483_648:  // 1-2 GB
            return .mb2
        case 2_147_483_648..<4_294_967_296:  // 2-4 GB
            return .mb4
        default:  // > 4 GB
            return .mb8
        }
    }

    /// Initialize from a raw byte value
    init?(bytes: Int) {
        self.init(rawValue: bytes)
    }
}

enum TorrentUtilities {

    /// Recommends an optimal piece size based on the total torrent size
    /// Following BitTorrent best practices
    @available(
        *,
        deprecated,
        message: "Use PieceSize.recommended(for:) instead"
    )
    static func recommendedPieceSize(for totalSize: Int) -> Int {
        return PieceSize.recommended(for: totalSize).bytes
    }

    /// Formats piece size in human-readable format
    static func formatPieceSize(_ bytes: Int) -> String {
        if let pieceSize = PieceSize(bytes: bytes) {
            return pieceSize.description
        }

        let kb = bytes / 1024
        if kb < 1024 {
            return "\(kb) KB"
        } else {
            let mb = kb / 1024
            return "\(mb) MB"
        }
    }

    /// Validates if a piece size is appropriate (must be power of 2)
    static func isValidPieceSize(_ size: Int) -> Bool {
        guard size > 0 else { return false }
        return (size & (size - 1)) == 0
    }

    /// All standard piece sizes
    @available(*, deprecated, message: "Use PieceSize.allCases instead")
    static let standardPieceSizes: [Int] = PieceSize.allCases.map(\.bytes)

    /// Validates an announce URL
    static func isValidAnnounceURL(_ url: String) -> Bool {
        guard let components = URLComponents(string: url) else {
            return false
        }

        // Must have a scheme
        guard let scheme = components.scheme?.lowercased() else {
            return false
        }

        // Must be http, https, or udp
        guard ["http", "https", "udp"].contains(scheme) else {
            return false
        }

        // Must have a host
        guard components.host != nil else {
            return false
        }

        return true
    }

    /// Generates a magnet link from torrent information
    static func generateMagnetLink(
        name: String,
        infoHash: String,
        trackers: [String]
    ) -> String {
        var magnet = "magnet:?xt=urn:btih:\(infoHash)"

        if !name.isEmpty,
            let encodedName = name.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            )
        {
            magnet += "&dn=\(encodedName)"
        }

        for tracker in trackers {
            if let encodedTracker = tracker.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) {
                magnet += "&tr=\(encodedTracker)"
            }
        }

        return magnet
    }
}
