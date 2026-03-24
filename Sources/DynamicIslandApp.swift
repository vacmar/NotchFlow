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
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupAppMenu()
        setupStatusMenu()
        NSApp.activate(ignoringOtherApps: true)

        let viewModel = IslandViewModel()

        // Check if setup has been completed
        let setupCompleted = UserDefaults.standard.bool(forKey: "PermissionsSetupCompleted")
        
        if !setupCompleted {
            showPermissionsSetup(viewModel: viewModel)
        }

        let contentView = IslandContainerView(viewModel: viewModel)
        let controller = IslandWindowController(rootView: contentView, viewModel: viewModel)

        controller.showWindow(nil)
        controller.positionOnActiveScreen()

        islandWindowController = controller
    }

    private func setupAppMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Open Settings", action: #selector(openSettingsWindow), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit NotchFlow", action: #selector(quitApp), keyEquivalent: "q"))
        appMenu.items.forEach { $0.target = self }

        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "NotchFlow")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(openSettingsWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchFlow", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        item.menu = menu
        statusItem = item
    }

    @objc
    private func openSettingsWindow() {
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showPermissionsSetup(viewModel: IslandViewModel) {
        let setupView = PermissionsSetupView(viewModel: viewModel)
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
