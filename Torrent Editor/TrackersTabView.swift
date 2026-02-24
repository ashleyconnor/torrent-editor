//
//  TrackersTabView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftUI

struct TrackersTabView: View {
    @Bindable var torrent: TorrentFile
    @State private var newTrackerURL = ""
    @State private var newTrackerTier = 0
    
    var body: some View {
        Form {
            Section("Primary Tracker") {
                TextField("Announce URL", text: $torrent.announceURL, prompt: Text("e.g., http://tracker.example.com:8080/announce"))
                
                if !torrent.announceURL.isEmpty && !TorrentUtilities.isValidAnnounceURL(torrent.announceURL) {
                    Label("Invalid tracker URL", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Section {
                if torrent.trackers.isEmpty {
                    Text("No trackers configured")
                        .foregroundStyle(.secondary)
                } else {
                    List {
                        ForEach(torrent.trackers) { tracker in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tracker.url)
                                        .font(.body)
                                    Text("Tier \(tracker.tier)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    if let index = torrent.trackers.firstIndex(where: { $0.id == tracker.id }) {
                                        torrent.trackers.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .help("Remove tracker")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("All Trackers (\(torrent.trackers.count))")
                    Spacer()
                }
            }
            
            Section("Add Tracker") {
                TextField("Tracker URL", text: $newTrackerURL, prompt: Text("http://tracker.example.com:8080/announce"))
                
                Picker("Tier", selection: $newTrackerTier) {
                    ForEach(0..<10) { tier in
                        Text("Tier \(tier)").tag(tier)
                    }
                }
                
                Button {
                    addTracker()
                } label: {
                    Label("Add Tracker", systemImage: "plus.circle.fill")
                }
                .disabled(newTrackerURL.isEmpty || !TorrentUtilities.isValidAnnounceURL(newTrackerURL))
            }
        }
        .formStyle(.grouped)
    }
    
    private func addTracker() {
        guard !newTrackerURL.isEmpty else { return }
        
        let tracker = TorrentTracker(url: newTrackerURL, tier: newTrackerTier)
        torrent.trackers.append(tracker)
        
        // Update primary tracker if this is tier 0 and no primary exists
        if newTrackerTier == 0 && torrent.announceURL.isEmpty {
            torrent.announceURL = newTrackerURL
        }
        
        // Clear form
        newTrackerURL = ""
        newTrackerTier = 0
    }
}

#Preview {
    TrackersTabView(torrent: TorrentFile())
}
