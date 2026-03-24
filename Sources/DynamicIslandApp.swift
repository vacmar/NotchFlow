import SwiftUI

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let viewModel = IslandViewModel()
        let contentView = IslandContainerView(viewModel: viewModel)
        let controller = IslandWindowController(rootView: contentView)

        controller.showWindow(nil)
        controller.positionOnActiveScreen()

        islandWindowController = controller
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        islandWindowController?.positionOnActiveScreen()
    }
}
