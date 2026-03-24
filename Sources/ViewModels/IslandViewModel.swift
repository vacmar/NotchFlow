import SwiftUI

@MainActor
final class IslandViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var snapshot: NowPlayingSnapshot = .placeholder

    private let nowPlayingService = SystemNowPlayingService()
    private var pollingTask: Task<Void, Never>?
    private var commandLockUntil: Date?
    private var lockedElapsed: TimeInterval = 0
    private var lockedDuration: TimeInterval = 0
    private var lockedProgress: Double = 0
    private var forcedPlayingState: Bool?

    init() {
        startPolling()
    }

    deinit {
        pollingTask?.cancel()
    }

    func setHovering(_ hovering: Bool) {
        withAnimation(hovering ? IslandAnimation.expand : IslandAnimation.collapse) {
            isExpanded = hovering
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
        nowPlayingService.nextTrack(source: snapshot.source)
    }

    func previous() {
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

    private func startPolling() {
        pollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                var latest = await self.nowPlayingService.currentSnapshot(previous: self.snapshot)

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
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}
