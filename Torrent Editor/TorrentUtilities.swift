//
//  TorrentUtilities.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation

enum TorrentUtilities {
    
    /// Recommends an optimal piece size based on the total torrent size
    /// Following BitTorrent best practices
    static func recommendedPieceSize(for totalSize: Int) -> Int {
        switch totalSize {
        case 0..<16_777_216:           // < 16 MB
            return 16_384               // 16 KB
        case 16_777_216..<33_554_432:  // 16-32 MB
            return 32_768               // 32 KB
        case 33_554_432..<67_108_864:  // 32-64 MB
            return 65_536               // 64 KB
        case 67_108_864..<134_217_728: // 64-128 MB
            return 131_072              // 128 KB
        case 134_217_728..<268_435_456: // 128-256 MB
            return 262_144              // 256 KB
        case 268_435_456..<536_870_912: // 256-512 MB
            return 524_288              // 512 KB
        case 536_870_912..<1_073_741_824: // 512 MB-1 GB
            return 1_048_576            // 1 MB
        case 1_073_741_824..<2_147_483_648: // 1-2 GB
            return 2_097_152            // 2 MB
        case 2_147_483_648..<4_294_967_296: // 2-4 GB
            return 4_194_304            // 4 MB
        default:                        // > 4 GB
            return 8_388_608            // 8 MB
        }
    }
    
    /// Formats piece size in human-readable format
    static func formatPieceSize(_ bytes: Int) -> String {
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
    static let standardPieceSizes: [Int] = [
        16_384,      // 16 KB
        32_768,      // 32 KB
        65_536,      // 64 KB
        131_072,     // 128 KB
        262_144,     // 256 KB
        524_288,     // 512 KB
        1_048_576,   // 1 MB
        2_097_152,   // 2 MB
        4_194_304,   // 4 MB
        8_388_608,   // 8 MB
        16_777_216   // 16 MB
    ]
    
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
    static func generateMagnetLink(name: String, infoHash: String, trackers: [String]) -> String {
        var magnet = "magnet:?xt=urn:btih:\(infoHash)"
        
        if !name.isEmpty, let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            magnet += "&dn=\(encodedName)"
        }
        
        for tracker in trackers {
            if let encodedTracker = tracker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                magnet += "&tr=\(encodedTracker)"
            }
        }
        
        return magnet
    }
    
    /// Common public tracker URLs
    static let commonTrackers: [String] = [
        "http://tracker.opentrackr.org:1337/announce",
        "udp://tracker.opentrackr.org:1337/announce",
        "udp://open.tracker.cl:1337/announce",
        "udp://9.rarbg.com:2810/announce",
        "udp://tracker.openbittorrent.com:6969/announce",
        "http://tracker.openbittorrent.com:80/announce"
    ]
}
