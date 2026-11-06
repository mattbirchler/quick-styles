import SafariServices
import SwiftUI

let extensionBundleIdentifier = "birchtree.quick-styles.Extension"

struct ContentView: View {
    @State private var isEnabled: Bool?

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Quick Styles")
                .font(.largeTitle.bold())

            Text("Add your own CSS to any website. Click the Quick Styles button in Safari's toolbar, type some CSS, and it applies right away.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            statusLabel

            Button("Open Safari Extension Settings", action: openSafariSettings)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            Text("Tip: allow Quick Styles on every website so your styles load automatically.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 420)
        .task { await refreshState() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshState() }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch isEnabled {
        case .some(true):
            Label("The extension is on in Safari.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .some(false):
            Label("The extension is off. Turn it on in Safari Settings.", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        case .none:
            Label("Checking the extension...", systemImage: "circle.dotted")
                .foregroundStyle(.secondary)
        }
    }

    private func refreshState() async {
        let enabled = await withCheckedContinuation { continuation in
            SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, _ in
                continuation.resume(returning: state?.isEnabled ?? false)
            }
        }
        isEnabled = enabled
    }

    private func openSafariSettings() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { _ in }
    }
}
