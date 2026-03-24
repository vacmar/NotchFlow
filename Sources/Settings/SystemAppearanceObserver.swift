import AppKit
import SwiftUI

final class SystemAppearanceObserver: NSObject, ObservableObject {
    @Published private(set) var colorScheme: ColorScheme = .dark

    override init() {
        super.init()
        refresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive(_:)),
            name: NSApplication.didBecomeActiveNotification,
            object: NSApp
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleAppearanceChanged(_:)),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func refresh() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            return
        }

        let effectiveAppearance = NSApp.effectiveAppearance
        let matchedAppearance = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        colorScheme = matchedAppearance == .darkAqua ? .dark : .light
    }

    @objc
    private func handleAppDidBecomeActive(_ notification: Notification) {
        refresh()
    }

    @objc
    private func handleAppearanceChanged(_ notification: Notification) {
        refresh()
    }
}