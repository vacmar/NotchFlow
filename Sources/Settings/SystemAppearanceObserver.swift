import AppKit
import SwiftUI

@MainActor
final class SystemAppearanceObserver: ObservableObject {
    @Published private(set) var colorScheme: ColorScheme = .dark

    private var appStateObserver: NSObjectProtocol?
    private var distributedAppearanceObserver: NSObjectProtocol?

    init() {
        refresh()

        appStateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        distributedAppearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        if let appStateObserver {
            NotificationCenter.default.removeObserver(appStateObserver)
        }
        if let distributedAppearanceObserver {
            DistributedNotificationCenter.default().removeObserver(distributedAppearanceObserver)
        }
    }

    func refresh() {
        let effectiveAppearance = NSApp.effectiveAppearance
        let matchedAppearance = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        colorScheme = matchedAppearance == .darkAqua ? .dark : .light
    }
}