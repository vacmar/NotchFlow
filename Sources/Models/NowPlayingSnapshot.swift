import AppKit

struct NowPlayingSnapshot {
    var title: String
    var artist: String
    var artwork: NSImage?
    var isPlaying: Bool
    var progress: Double
    var elapsedSeconds: TimeInterval
    var durationSeconds: TimeInterval

    static let placeholder = NowPlayingSnapshot(
        title: "Not Playing",
        artist: "Open Apple Music, Spotify, Safari, or Chrome",
        artwork: nil,
        isPlaying: false,
        progress: 0,
        elapsedSeconds: 0,
        durationSeconds: 0
    )
}
