import SwiftUI

@main
struct NotchFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?
    private var setupWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Check if setup has been completed
        let setupCompleted = UserDefaults.standard.bool(forKey: "PermissionsSetupCompleted")
        
        if !setupCompleted {
            showPermissionsSetup()
        }

        let viewModel = IslandViewModel()
        let contentView = IslandContainerView(viewModel: viewModel)
        let controller = IslandWindowController(rootView: contentView, viewModel: viewModel)

        controller.showWindow(nil)
        controller.positionOnActiveScreen()

        islandWindowController = controller
    }

    private func showPermissionsSetup() {
        let setupView = PermissionsSetupView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "NotchFlow Setup"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: setupView)
        window.center()
        
        setupWindowController = NSWindowController(window: window)
        setupWindowController?.showWindow(nil)
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        islandWindowController?.positionOnActiveScreen()
    }
}
