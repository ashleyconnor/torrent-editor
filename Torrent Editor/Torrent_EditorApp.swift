//
//  Torrent_EditorApp.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 07/12/2025.
//

import Combine
import Sparkle
import SwiftUI

@main
struct Torrent_EditorApp: App {

  @StateObject private var updatesViewModel = CheckForUpdatesViewModel(
    updater: SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    ).updater
  )

  @State private var showingAbout = false

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(updatesViewModel)
        .sheet(isPresented: $showingAbout) {
          AboutView()
        }
        .onOpenURL { url in
          NotificationCenter.default.post(name: .openTorrentURL, object: url)
        }
    }
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button("About Torrent Editor") {
          showingAbout = true
        }
      }
      CommandGroup(after: .appInfo) {
        CheckForUpdatesView(viewModel: updatesViewModel)
      }

      CommandGroup(replacing: .newItem) {
        Button("New Torrent") {
          NotificationCenter.default.post(name: .newTorrent, object: nil)
        }
        .keyboardShortcut("n", modifiers: .command)

        Button("Open Torrent...") {
          NotificationCenter.default.post(name: .openTorrent, object: nil)
        }
        .keyboardShortcut("o", modifiers: .command)

        Divider()

        Button("Save Torrent...") {
          NotificationCenter.default.post(name: .saveTorrent, object: nil)
        }
        .keyboardShortcut("s", modifiers: .command)
      }
    }
  }
}
// MARK: - Notification Names

extension Notification.Name {
  static let newTorrent = Notification.Name("newTorrent")
  static let openTorrent = Notification.Name("openTorrent")
  static let openTorrentURL = Notification.Name("openTorrentURL")
  static let saveTorrent = Notification.Name("saveTorrent")
}
