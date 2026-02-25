//
//  InfoTabView.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import SwiftUI

struct InfoTabView: View {
  @Bindable var torrent: TorrentFile

  var body: some View {
    Form {
      Section("Metadata") {
        TextField("Torrent Name", text: $torrent.name, prompt: Text("Required"))

        VStack(alignment: .leading, spacing: 4) {
          TextField(
            "Announce URL", text: $torrent.announceURL,
            prompt: Text("e.g., http://tracker.example.com:8080/announce"))

          if !torrent.announceURL.isEmpty
            && !TorrentUtilities.isValidAnnounceURL(torrent.announceURL)
          {
            Label("Invalid tracker URL", systemImage: "exclamationmark.triangle.fill")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }

        TextField("Comment", text: $torrent.comment, prompt: Text("Optional"), axis: .vertical)
          .lineLimit(3...6)

        TextField("Created By", text: $torrent.createdBy, prompt: Text("Your name or app name"))

        DatePicker("Creation Date", selection: $torrent.creationDate)

        Toggle("Private Torrent", isOn: $torrent.isPrivate)
      }

      Section("Advanced Settings") {
        HStack {
          Picker("Piece Size", selection: $torrent.pieceLength) {
            ForEach(PieceSize.allCases) { pieceSize in
              Text(pieceSize.description).tag(pieceSize.bytes)
            }
          }

          if torrent.totalSize > 0 {
            let recommended = PieceSize.recommended(for: torrent.totalSize)
            if recommended.bytes != torrent.pieceLength {
              Button("Use Recommended") {
                torrent.pieceLength = recommended.bytes
              }
              .buttonStyle(.borderless)
              .controlSize(.small)
              .help("Recommended: \(recommended.description) for this torrent size")
            }
          }
        }
      }

      Section("Torrent Information") {
        LabeledContent("Content Size", value: torrent.formattedTotalSize)
        LabeledContent("Torrent File Size", value: torrentFileSize)
        LabeledContent("Number of Files", value: "\(torrent.files.count)")
        LabeledContent("Number of Pieces", value: "\(torrent.numberOfPieces)")
        if let infoHash = torrent.calculateInfoHash() {
          LabeledContent("Info Hash") {
            Text(infoHash)
              .font(.system(.caption, design: .monospaced))
              .textSelection(.enabled)
          }
        }
      }
    }
    .formStyle(.grouped)
  }

  private var torrentFileSize: String {
    let encodedData = torrent.encode()
    return ByteCountFormatter.string(fromByteCount: Int64(encodedData.count), countStyle: .file)
  }
}

#Preview {
  InfoTabView(torrent: TorrentFile())
}
