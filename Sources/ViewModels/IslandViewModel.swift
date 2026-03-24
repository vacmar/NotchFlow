import SwiftUI

@MainActor
final class IslandViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var snapshot: NowPlayingSnapshot = .placeholder

    private let nowPlayingService = SystemNowPlayingService()
    private var pollingTask: Task<Void, Never>?

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
        nowPlayingService.togglePlayPause()
        snapshot.isPlaying.toggle()
    }

    func next() {
        nowPlayingService.nextTrack()
    }

    func previous() {
        nowPlayingService.previousTrack()
    }

    private func startPolling() {
        pollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                self.snapshot = self.nowPlayingService.currentSnapshot(previous: self.snapshot)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
