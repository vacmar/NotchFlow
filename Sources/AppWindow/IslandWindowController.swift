import AppKit
import SwiftUI

final class IslandWindowController: NSWindowController {
    private let positioner = IslandWindowPositioner()

    init<Content: View>(rootView: Content) {
        let centeredRoot = ZStack {
            rootView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        let hostingView = NSHostingView(rootView: centeredRoot)
        hostingView.wantsLayer = true

        let initialFrame = NSRect(x: 0, y: 0, width: 520, height: 156)
        let panel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.contentView = hostingView

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func positionOnActiveScreen() {
        guard let window else { return }
        let frame = positioner.topCenteredFrame(
            for: window.frame.size,
            screen: NSScreen.main
        )
        window.setFrame(frame, display: true)
    }
}
