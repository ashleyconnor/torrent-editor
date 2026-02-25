//
//  TorrentEditorView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct TorrentEditorView: View {
  @Bindable var torrent: TorrentFile
  @State private var showingSavePanel = false
  @State private var showingAlert = false
  @State private var alertMessage = ""
  @State private var selectedTab = 0

  var body: some View {
    VStack(spacing: 0) {
      // Tab Picker
      Picker("", selection: $selectedTab) {
        Text("Info").tag(0)
        Text("Trackers").tag(1)
        Text("Files").tag(2)
      }
      .pickerStyle(.segmented)
      .padding()

      Divider()

      // Tab Content
      Group {
        switch selectedTab {
        case 0:
          InfoTabView(torrent: torrent)
        case 1:
          TrackersTabView(torrent: torrent)
        case 2:
          FilesTabView(
            torrent: torrent,
            onAddFiles: addFilesOrFolders,
            onAlert: { message in
              alertMessage = message
              showingAlert = true
            }
          )
        default:
          InfoTabView(torrent: torrent)
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Menu {
          Button {
            createNewTorrent()
          } label: {
            Label("New Torrent", systemImage: "plus.square")
          }
          .keyboardShortcut("n", modifiers: .command)

          Button {
            NotificationCenter.default.post(name: .openTorrent, object: nil)
          } label: {
            Label("Open Torrent...", systemImage: "folder")
          }
          .keyboardShortcut("o", modifiers: .command)

          Divider()

          Button {
            saveTorrent()
          } label: {
            Label("Save Torrent...", systemImage: "square.and.arrow.down")
          }
          .keyboardShortcut("s", modifiers: .command)
          .disabled(!isValid)

          if selectedTab == 2 {
            Divider()

            Button {
              addFilesOrFolders()
            } label: {
              Label("Add Files or Folders...", systemImage: "doc.badge.plus")
            }
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .help("Actions")
      }
    }
    .alert("Error", isPresented: $showingAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(alertMessage)
    }
    .onReceive(NotificationCenter.default.publisher(for: .saveTorrent)) { _ in
      if isValid {
        saveTorrent()
      }
    }
  }

  // MARK: - Validation

  private var isValid: Bool {
    !torrent.name.isEmpty && !torrent.announceURL.isEmpty
      && TorrentUtilities.isValidAnnounceURL(torrent.announceURL) && !torrent.files.isEmpty
  }

  // MARK: - File Operations

  private func addFilesOrFolders() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = true
    panel.canChooseFiles = true
    panel.title = "Choose Files or Folders to Add"
    panel.message = "Select individual files or entire folders to add to the torrent"

    if panel.runModal() == .OK {
      for url in panel.urls {
        do {
          var isDirectory: ObjCBool = false
          FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

          if isDirectory.boolValue {
            try torrent.addDirectory(url: url)
          } else {
            try torrent.addFile(url: url)
          }
        } catch {
          alertMessage = "Failed to add: \(error.localizedDescription)"
          showingAlert = true
        }
      }
    }
  }

  private func saveTorrent() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [UTType(filenameExtension: "torrent")!]
    panel.nameFieldStringValue =
      torrent.name.isEmpty ? "untitled.torrent" : "\(torrent.name).torrent"
    panel.title = "Save Torrent File"

    if panel.runModal() == .OK, let url = panel.url {
      do {
        let data = torrent.encode()
        try data.write(to: url)
      } catch {
        alertMessage = "Failed to save torrent: \(error.localizedDescription)"
        showingAlert = true
      }
    }
  }

  private func createNewTorrent() {
    // In the future, this might need confirmation if there are unsaved changes
    torrent.name = ""
    torrent.announceURL = ""
    torrent.comment = ""
    torrent.createdBy = ""
    torrent.creationDate = Date()
    torrent.isPrivate = false
    torrent.pieceLength = 262_144
    torrent.files.removeAll()
    torrent.trackers.removeAll()
  }
}

#Preview {
  TorrentEditorView(torrent: TorrentFile())
    .frame(width: 600, height: 700)
}
