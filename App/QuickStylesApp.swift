import Sparkle
import SwiftUI

@main
struct QuickStylesApp: App {
    // Checks for updates in the background once a day (SUEnableAutomaticChecks
    // in Info.plist) and powers the Check for Updates menu item.
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        Window("Quick Styles", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updaterController.updater)
            }
        }
    }
}

struct CheckForUpdatesButton: View {
    @ObservedObject private var model: UpdaterModel

    init(updater: SPUUpdater) {
        model = UpdaterModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") { model.updater.checkForUpdates() }
            .disabled(!model.canCheckForUpdates)
    }
}

@MainActor
final class UpdaterModel: ObservableObject {
    let updater: SPUUpdater
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }
}
