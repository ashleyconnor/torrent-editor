//
//  TorrentTracker.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation

struct TorrentTracker: Identifiable, Hashable {
  let id = UUID()
  var url: String
  var tier: Int  // 0 = primary, 1+ = fallback tiers

  init(url: String, tier: Int = 0) {
    self.url = url
    self.tier = tier
  }
}
