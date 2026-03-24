import SwiftUI

extension Notification.Name {
    static let notchFlowOpenSettingsRequested = Notification.Name("NotchFlowOpenSettingsRequested")
}

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
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var openSettingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupAppMenu()
        setupStatusMenu()
        openSettingsObserver = NotificationCenter.default.addObserver(
            forName: .notchFlowOpenSettingsRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettingsWindow()
        }
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

    deinit {
        if let openSettingsObserver {
            NotificationCenter.default.removeObserver(openSettingsObserver)
        }
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
    func openSettingsWindow() {
        if let controller = settingsWindowController,
           let window = controller.window {
            positionWindowOnCurrentScreen(window)
            controller.showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "NotchFlow Settings"
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: settingsView)
        positionWindowOnCurrentScreen(window)

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func positionWindowOnCurrentScreen(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main

        guard let screen = targetScreen else { return }

        let visibleFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - (windowSize.width / 2),
            y: visibleFrame.midY - (windowSize.height / 2)
        )

        window.setFrameOrigin(origin)
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
