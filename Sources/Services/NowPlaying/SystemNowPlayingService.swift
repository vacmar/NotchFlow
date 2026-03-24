import AppKit
import MediaPlayer

struct SystemNowPlayingService {
    func currentSnapshot(previous: NowPlayingSnapshot) -> NowPlayingSnapshot {
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return NowPlayingSnapshot.placeholder
        }

        let title = (info[MPMediaItemPropertyTitle] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = (info[MPMediaItemPropertyArtist] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        let duration = (info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval) ?? previous.durationSeconds
        let elapsed = (info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval) ?? previous.elapsedSeconds
        let playbackRate = (info[MPNowPlayingInfoPropertyPlaybackRate] as? Double) ?? 0
        let isPlaying = playbackRate > 0

        let progress: Double
        if duration > 0 {
            progress = min(max(elapsed / duration, 0), 1)
        } else {
            progress = previous.progress
        }

        let artwork = artworkImage(from: info, fallback: previous.artwork)

        return NowPlayingSnapshot(
            title: (title?.isEmpty == false ? title : previous.title) ?? "Not Playing",
            artist: (artist?.isEmpty == false ? artist : previous.artist) ?? "Open Apple Music, Spotify, Safari, or Chrome",
            artwork: artwork,
            isPlaying: isPlaying,
            progress: progress,
            elapsedSeconds: elapsed,
            durationSeconds: duration
        )
    }

    func togglePlayPause() {
        runScript("""
        tell application "Music"
            if running then
                playpause
            end if
        end tell
        """)

        runScript("""
        tell application "Spotify"
            if running then
                playpause
            end if
        end tell
        """)
    }

    func nextTrack() {
        runScript("""
        tell application "Music"
            if running then
                next track
            end if
        end tell
        """)

        runScript("""
        tell application "Spotify"
            if running then
                next track
            end if
        end tell
        """)
    }

    func previousTrack() {
        runScript("""
        tell application "Music"
            if running then
                previous track
            end if
        end tell
        """)

        runScript("""
        tell application "Spotify"
            if running then
                previous track
            end if
        end tell
        """)
    }

    private func artworkImage(from info: [String: Any], fallback: NSImage?) -> NSImage? {
        guard let mediaArtwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork else {
            return fallback
        }

        let requestedSize = NSSize(width: 128, height: 128)
        return mediaArtwork.image(at: requestedSize) ?? fallback
    }

    private func runScript(_ source: String) {
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(nil)
    }
}
