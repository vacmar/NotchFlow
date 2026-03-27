import AppKit
import SwiftUI

enum GestureOnboardingStep: Int {
    case requirePreferredSource
    case hoverToExpand
    case swipeLeft
    case swipeRight
    case openSourceApp
    case completed
}

@MainActor
final class IslandViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var snapshot: NowPlayingSnapshot = .placeholder
    @Published var gestureOnboardingStep: GestureOnboardingStep = .requirePreferredSource
    @Published var gestureOnboardingCompleted = false

    private let nowPlayingService = SystemNowPlayingService()
    private var pollingTask: Task<Void, Never>?
    private var commandLockUntil: Date?
    private var lockedElapsed: TimeInterval = 0
    private var lockedDuration: TimeInterval = 0
    private var lockedProgress: Double = 0
    private var forcedPlayingState: Bool?
    private var autoCollapseTask: Task<Void, Never>?

    init() {
        startPolling()
    }

    deinit {
        pollingTask?.cancel()
        autoCollapseTask?.cancel()
    }

    var isPreferredSourceActive: Bool {
        switch snapshot.source {
        case .spotify, .music:
            return true
        case .none, .browser, .system:
            return false
        }
    }

    func setHovering(_ hovering: Bool) {
        switch visibilityMode {
        case .alwaysExpanded:
            withAnimation(IslandAnimation.expand) {
                isExpanded = true
            }
        case .alwaysVisible:
            withAnimation(IslandAnimation.collapse) {
                isExpanded = false
            }
        case .auto:
            withAnimation(hovering ? IslandAnimation.expand : IslandAnimation.collapse) {
                isExpanded = hovering
            }
        }

        if hovering, visibilityMode == .auto {
            advanceOnboardingAfterHover()
        }
    }

    func togglePlayPause() {
        lockedElapsed = snapshot.elapsedSeconds
        lockedDuration = snapshot.durationSeconds
        lockedProgress = snapshot.progress

        let supportsReliableLock: Bool
        switch snapshot.source {
        case .spotify, .music:
            supportsReliableLock = true
        case .browser, .system, .none:
            supportsReliableLock = false
        }

        if supportsReliableLock {
            let targetState = !snapshot.isPlaying
            forcedPlayingState = targetState
            commandLockUntil = Date().addingTimeInterval(0.9)
            snapshot.isPlaying = targetState

            if !targetState {
                snapshot.elapsedSeconds = lockedElapsed
                snapshot.progress = lockedProgress
            }
        } else {
            forcedPlayingState = nil
            commandLockUntil = nil
        }

        nowPlayingService.togglePlayPause(source: snapshot.source)
    }

    func next() {
        registerSwipeLeft()
        nowPlayingService.nextTrack(source: snapshot.source)
    }

    func previous() {
        registerSwipeRight()
        nowPlayingService.previousTrack(source: snapshot.source)
    }

    func handleHorizontalSwipe(_ translationWidth: CGFloat) {
        let threshold: CGFloat = 70
        if translationWidth <= -threshold {
            next()
        } else if translationWidth >= threshold {
            previous()
        }
    }

    func openCurrentSourceApp() {
        registerOpenSourceApp()
        nowPlayingService.openSourceApp(source: snapshot.source)
    }

    private func startPolling() {
        pollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let previousSnapshot = self.snapshot
                var latest = await self.nowPlayingService.currentSnapshot(previous: previousSnapshot)

                if let lockUntil = self.commandLockUntil,
                   let forcedState = self.forcedPlayingState,
                   Date() < lockUntil
                {
                    latest.isPlaying = forcedState

                    if !forcedState {
                        latest.elapsedSeconds = self.lockedElapsed
                        latest.durationSeconds = self.lockedDuration
                        latest.progress = self.lockedProgress
                    }
                } else {
                    self.commandLockUntil = nil
                    self.forcedPlayingState = nil
                }

                self.snapshot = latest
                self.handleSmartAutoExpand(previous: previousSnapshot, latest: latest)
                self.refreshOnboardingStepFromCurrentSource()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private var visibilityMode: IslandVisibilityMode {
        IslandVisibilityMode.from(UserDefaults.standard.string(forKey: "islandVisibilityMode") ?? IslandVisibilityMode.auto.rawValue)
    }

    private var smartAutoExpandEnabled: Bool {
        if UserDefaults.standard.object(forKey: "smartAutoExpandEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "smartAutoExpandEnabled")
    }

    private var focusAwareBehaviorEnabled: Bool {
        UserDefaults.standard.bool(forKey: "focusAwareBehaviorEnabled")
    }

    private func handleSmartAutoExpand(previous: NowPlayingSnapshot, latest: NowPlayingSnapshot) {
        guard smartAutoExpandEnabled else { return }
        guard visibilityMode != .alwaysExpanded else {
            isExpanded = true
            return
        }

        if focusAwareBehaviorEnabled, shouldSuppressAttentionExpansion {
            return
        }

        let titleChanged = !latest.title.isEmpty && previous.title != latest.title
        let sourceChanged = previous.source != latest.source && latest.source != .none
        let playbackChanged = previous.isPlaying != latest.isPlaying

        guard titleChanged || sourceChanged || playbackChanged else { return }

        withAnimation(IslandAnimation.expand) {
            isExpanded = true
        }

        autoCollapseTask?.cancel()
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.2))
            guard let self, !Task.isCancelled else { return }

            await MainActor.run {
                switch self.visibilityMode {
                case .auto, .alwaysVisible:
                    withAnimation(IslandAnimation.collapse) {
                        self.isExpanded = false
                    }
                case .alwaysExpanded:
                    withAnimation(IslandAnimation.expand) {
                        self.isExpanded = true
                    }
                }
            }
        }
    }

    private var shouldSuppressAttentionExpansion: Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }

        let mediaBundleIDs: Set<String> = [
            "com.spotify.client",
            "com.apple.Music",
            "com.apple.Safari",
            "com.google.Chrome",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "com.operasoftware.OperaGX"
        ]

        return !mediaBundleIDs.contains(bundleID)
    }

    private func refreshOnboardingStepFromCurrentSource() {
        guard !gestureOnboardingCompleted else { return }

        if !isPreferredSourceActive {
            gestureOnboardingStep = .requirePreferredSource
            return
        }

        if gestureOnboardingStep == .requirePreferredSource {
            gestureOnboardingStep = .hoverToExpand
        }
    }

    private func advanceOnboardingAfterHover() {
        guard !gestureOnboardingCompleted else { return }
        guard isPreferredSourceActive else {
            gestureOnboardingStep = .requirePreferredSource
            return
        }

        if gestureOnboardingStep == .hoverToExpand {
            gestureOnboardingStep = .swipeLeft
        }
    }

    private func registerSwipeLeft() {
        guard !gestureOnboardingCompleted else { return }
        guard isPreferredSourceActive else {
            gestureOnboardingStep = .requirePreferredSource
            return
        }

        if gestureOnboardingStep == .swipeLeft {
            gestureOnboardingStep = .swipeRight
        }
    }

    private func registerSwipeRight() {
        guard !gestureOnboardingCompleted else { return }
        guard isPreferredSourceActive else {
            gestureOnboardingStep = .requirePreferredSource
            return
        }

        if gestureOnboardingStep == .swipeRight {
            gestureOnboardingStep = .openSourceApp
        }
    }

    private func registerOpenSourceApp() {
        guard !gestureOnboardingCompleted else { return }
        guard isPreferredSourceActive else {
            gestureOnboardingStep = .requirePreferredSource
            return
        }

        if gestureOnboardingStep == .openSourceApp {
            gestureOnboardingStep = .completed
            gestureOnboardingCompleted = true
        }
    }
}
