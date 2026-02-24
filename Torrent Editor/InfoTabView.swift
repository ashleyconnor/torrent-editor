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
                    TextField("Announce URL", text: $torrent.announceURL, prompt: Text("e.g., http://tracker.example.com:8080/announce"))
                    
                    if !torrent.announceURL.isEmpty && !TorrentUtilities.isValidAnnounceURL(torrent.announceURL) {
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
                        Text("16 KB").tag(16_384)
                        Text("32 KB").tag(32_768)
                        Text("64 KB").tag(65_536)
                        Text("128 KB").tag(131_072)
                        Text("256 KB").tag(262_144)
                        Text("512 KB").tag(524_288)
                        Text("1 MB").tag(1_048_576)
                        Text("2 MB").tag(2_097_152)
                        Text("4 MB").tag(4_194_304)
                        Text("8 MB").tag(8_388_608)
                    }
                    
                    if torrent.totalSize > 0 {
                        let recommended = TorrentUtilities.recommendedPieceSize(for: torrent.totalSize)
                        if recommended != torrent.pieceLength {
                            Button("Use Recommended") {
                                torrent.pieceLength = recommended
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .help("Recommended: \(TorrentUtilities.formatPieceSize(recommended)) for this torrent size")
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
