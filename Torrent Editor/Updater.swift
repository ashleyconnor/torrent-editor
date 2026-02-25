import Combine
import Sparkle
import SwiftUI

final class CheckForUpdatesViewModel: ObservableObject {
  @Published var canCheckForUpdates = false
  let updater: SPUUpdater
  private var cancellables = Set<AnyCancellable>()

  init(updater: SPUUpdater) {
    self.updater = updater

    updater.publisher(for: \.canCheckForUpdates)
      .receive(on: RunLoop.main)
      .assign(to: \.canCheckForUpdates, on: self)
      .store(in: &cancellables)
  }

  func checkForUpdates() {
    updater.checkForUpdates()
  }
}

struct CheckForUpdatesView: View {
  @ObservedObject var viewModel: CheckForUpdatesViewModel

  var body: some View {
    Button("Check for Updates…") {
      viewModel.checkForUpdates()
    }
    .disabled(!viewModel.canCheckForUpdates)
  }
}

#Preview {
  @Previewable var updatesViewModel = CheckForUpdatesViewModel(
    updater: SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    ).updater
  )
  CheckForUpdatesView(viewModel: updatesViewModel)
}
