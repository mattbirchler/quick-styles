import SwiftUI

@main
struct QuickStylesApp: App {
    var body: some Scene {
        Window("Quick Styles", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
