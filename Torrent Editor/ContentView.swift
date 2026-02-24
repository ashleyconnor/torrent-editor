//
//  ContentView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 07/12/2025.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var torrentFile = TorrentFile()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Main editor view
            TorrentEditorView(torrent: torrentFile)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTorrent)) { _ in
            openTorrent()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTorrent)) { _ in
            createNewTorrent()
        }
    }
    
    private func createNewTorrent() {
        torrentFile = TorrentFile()
    }
    
    private func openTorrent() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "torrent")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose a Torrent File"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                torrentFile = try TorrentFile.parse(from: data)
            } catch {
                errorMessage = "Failed to open torrent: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 700, height: 800)
}
