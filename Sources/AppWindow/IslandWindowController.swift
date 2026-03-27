import AppKit
import Combine
import SwiftUI

final class IslandWindowController: NSWindowController {
    private let positioner = IslandWindowPositioner()
    private let viewModel: IslandViewModel
    private var expansionStateCancellable: AnyCancellable?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var trackpadSwipeAccumulatedX: CGFloat = 0
    private var visibilityTimerCancellable: AnyCancellable?
    private var activeSpaceObserver: NSObjectProtocol?

    init<Content: View>(rootView: Content, viewModel: IslandViewModel) {
        self.viewModel = viewModel

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
        panel.ignoresMouseEvents = true
        panel.contentView = hostingView

        super.init(window: panel)

        startExpansionStateObservation()
        startGlobalHoverMonitoring()
        startVisibilityContextObservation()
        updateWindowInteractivity()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }
        if let activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
        }
    }

    func positionOnActiveScreen() {
        guard let window else { return }
        let frame = positioner.topCenteredFrame(
            for: window.frame.size,
            screen: NSScreen.main
        )
        window.setFrame(frame, display: true)
    }

    private func startExpansionStateObservation() {
        expansionStateCancellable = viewModel.$isExpanded
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWindowInteractivity()
            }
    }

    private func startVisibilityContextObservation() {
        visibilityTimerCancellable = Timer
            .publish(every: 0.9, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateWindowInteractivity()
            }

        activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowInteractivity()
        }
    }

    private func startGlobalHoverMonitoring() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] _ in
            self?.updateHoverFromMouseLocation()
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .scrollWheel]
        ) { [weak self] event in
            if event.type == .scrollWheel {
                self?.handleTrackpadScrollSwipe(event)
            } else {
                self?.updateHoverFromMouseLocation()
            }
            return event
        }
    }

    private func handleTrackpadScrollSwipe(_ event: NSEvent) {
        guard viewModel.isExpanded,
              let window,
              window.frame.contains(NSEvent.mouseLocation)
        else {
            trackpadSwipeAccumulatedX = 0
            return
        }

        if event.phase == .began {
            trackpadSwipeAccumulatedX = 0
        }

        let horizontal = event.scrollingDeltaX
        let vertical = event.scrollingDeltaY
        guard abs(horizontal) > abs(vertical) else {
            if event.phase == .ended || event.phase == .cancelled {
                trackpadSwipeAccumulatedX = 0
            }
            return
        }

        trackpadSwipeAccumulatedX += horizontal
        let threshold: CGFloat = 55

        if trackpadSwipeAccumulatedX <= -threshold {
            trackpadSwipeAccumulatedX = 0
            Task { @MainActor in
                self.viewModel.next()
            }
        } else if trackpadSwipeAccumulatedX >= threshold {
            trackpadSwipeAccumulatedX = 0
            Task { @MainActor in
                self.viewModel.previous()
            }
        }

        if event.phase == .ended || event.phase == .cancelled {
            trackpadSwipeAccumulatedX = 0
        }
    }

    private func updateHoverFromMouseLocation() {
        guard let window else { return }
        if shouldHideInFullscreen(window: window) {
            Task { @MainActor in
                self.viewModel.setHovering(false)
            }
            return
        }
        guard let activationFrame = bezelActivationFrame else { return }

        let mouseLocation = NSEvent.mouseLocation
        let isInActivationZone = activationFrame.contains(mouseLocation)
        let isInsideExpandedFrame = window.frame.contains(mouseLocation)
        let shouldExpand = viewModel.isExpanded
            ? (isInsideExpandedFrame || isInActivationZone)
            : isInActivationZone

        Task { @MainActor in
            self.viewModel.setHovering(shouldExpand)
        }
    }

    private var clickThroughCollapsedEnabled: Bool {
        if UserDefaults.standard.object(forKey: "clickThroughCollapsedEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "clickThroughCollapsedEnabled")
    }

    private var autoHideFullscreenEnabled: Bool {
        if UserDefaults.standard.object(forKey: "autoHideFullscreenEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "autoHideFullscreenEnabled")
    }

    private var visibilityMode: IslandVisibilityMode {
        IslandVisibilityMode.from(
            UserDefaults.standard.string(forKey: "islandVisibilityMode") ?? IslandVisibilityMode.auto.rawValue
        )
    }

    private func shouldHideInFullscreen(window: NSWindow) -> Bool {
        guard autoHideFullscreenEnabled else { return false }
        guard let screen = window.screen else { return false }

        let visible = screen.visibleFrame
        let full = screen.frame
        return abs(visible.width - full.width) < 1 && abs(visible.height - full.height) < 1
    }

    private func updateWindowInteractivity() {
        guard let window else { return }

        if shouldHideInFullscreen(window: window) {
            window.alphaValue = 0.0
            window.ignoresMouseEvents = true
            Task { @MainActor in
                self.viewModel.setHovering(false)
            }
            return
        }

        window.alphaValue = 1.0

        let ignoresMouseEvents: Bool
        switch visibilityMode {
        case .alwaysExpanded:
            ignoresMouseEvents = false
        case .alwaysVisible, .auto:
            ignoresMouseEvents = viewModel.isExpanded ? false : clickThroughCollapsedEnabled
        }

        window.ignoresMouseEvents = ignoresMouseEvents
    }

    private var bezelActivationFrame: CGRect? {
        guard let window else { return nil }

        let windowFrame = window.frame
        let width: CGFloat = 148
        let height: CGFloat = 14
        let topOffset: CGFloat = 9

        let x = windowFrame.midX - (width / 2)
        let y = windowFrame.maxY - topOffset - height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
