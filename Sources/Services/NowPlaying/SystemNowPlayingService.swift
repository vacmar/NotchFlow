import AppKit
import Foundation
import MediaPlayer

struct SystemNowPlayingService {
    func currentSnapshot(previous: NowPlayingSnapshot) async -> NowPlayingSnapshot {
        if let focusedSnapshot = await frontmostAppSnapshot(previous: previous) {
            return focusedSnapshot
        }

        // Priority: What's actually PLAYING (not paused)
        // Check Spotify first if playing
        if let spotify = await spotifySnapshot(previous: previous), spotify.isPlaying {
            return spotify
        }
        // Check Apple Music if playing
        if let music = await musicSnapshot(previous: previous), music.isPlaying {
            return music
        }
        // Check browsers next (separate from system center to avoid stale paused app snapshots)
        if let browser = await browserSnapshot(previous: previous) {
            return browser
        }

        // Then check system now playing (YouTube, etc)
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            // Final fallback: return previous paused state (could be Spotify/Music)
            if let spotify = await spotifySnapshot(previous: previous) {
                return spotify
            }
            if let music = await musicSnapshot(previous: previous) {
                return music
            }
            return NowPlayingSnapshot.placeholder
        }

        let title = (info[MPMediaItemPropertyTitle] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = (info[MPMediaItemPropertyArtist] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        if title?.isEmpty ?? true {
            if let browser = await browserSnapshot(previous: previous) {
                return browser
            }
        }

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
            durationSeconds: duration,
            source: .system
        )
    }

    private func frontmostAppSnapshot(previous: NowPlayingSnapshot) async -> NowPlayingSnapshot? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication?.localizedName else {
            return nil
        }

        switch frontmost {
        case "Spotify":
            return await spotifySnapshot(previous: previous)
        case "Music":
            return await musicSnapshot(previous: previous)
        case "Safari", "Google Chrome", "Brave Browser", "Opera", "Opera GX":
            return await browserSnapshot(previous: previous, preferredBrowserName: frontmost)
        default:
            return nil
        }
    }

    func togglePlayPause(source: NowPlayingSource) {
        switch source {
        case .spotify:
            runScript("""
            tell application "Spotify"
                if running then
                    playpause
                end if
            end tell
            """)
        case .music:
            runScript("""
            tell application "Music"
                if running then
                    playpause
                end if
            end tell
            """)
        case .browser, .system:
            if !toggleBrowserPlayback() {
                runScript("""
                tell application "System Events"
                    key code 49
                end tell
                """)
            }
        case .none:
            break
        }
    }

    func nextTrack(source: NowPlayingSource) {
        switch source {
        case .spotify:
            runScript("""
            tell application "Spotify"
                if running then
                    next track
                end if
            end tell
            """)
        case .music:
            runScript("""
            tell application "Music"
                if running then
                    next track
                end if
            end tell
            """)
        default:
            break
        }
    }

    func previousTrack(source: NowPlayingSource) {
        switch source {
        case .spotify:
            runScript("""
            tell application "Spotify"
                if running then
                    previous track
                end if
            end tell
            """)
        case .music:
            runScript("""
            tell application "Music"
                if running then
                    previous track
                end if
            end tell
            """)
        default:
            break
        }
    }

    func openSourceApp(source: NowPlayingSource) {
        switch source {
        case .spotify:
            runScript("""
            tell application "Spotify"
                activate
            end tell
            """)
        case .music:
            runScript("""
            tell application "Music"
                activate
            end tell
            """)
        case .browser:
            let browsers = ["Google Chrome", "Safari", "Brave Browser", "Opera", "Opera GX"]
            for browser in browsers {
                let script = """
                tell application "\(browser)"
                    if running then
                        activate
                        return "ok"
                    end if
                end tell
                """
                if executeScriptString(script) == "ok" {
                    break
                }
            }
        case .system:
            if executeScriptString("""
            tell application "Spotify"
                if running then
                    activate
                    return "ok"
                end if
            end tell
            """) == "ok" {
                return
            }
            if executeScriptString("""
            tell application "Music"
                if running then
                    activate
                    return "ok"
                end if
            end tell
            """) == "ok" {
                return
            }
            _ = executeScriptString("""
            tell application "Safari"
                if running then activate
            end tell
            """)
        case .none:
            break
        }
    }

    private func artworkImage(from info: [String: Any], fallback: NSImage?) -> NSImage? {
        if let mediaArtwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            let requestedSize = NSSize(width: 128, height: 128)
            if let image = mediaArtwork.image(at: requestedSize) {
                return image
            }
        }

        if let directImage = info[MPMediaItemPropertyArtwork] as? NSImage {
            return directImage
        }

        let explicitArtworkDataKeys = [
            "kMRMediaRemoteNowPlayingInfoArtworkData",
            "kMRMediaRemoteNowPlayingInfoArtworkDataHD",
            "ArtworkData"
        ]

        for key in explicitArtworkDataKeys {
            if let data = info[key] as? Data, let image = NSImage(data: data) {
                return image
            }
        }

        for value in info.values {
            if let data = value as? Data, let image = NSImage(data: data) {
                return image
            }
        }

        return fallback
    }

    private func runScript(_ source: String) {
        _ = executeScriptString(source)
    }

    private func spotifySnapshot(previous: NowPlayingSnapshot) async -> NowPlayingSnapshot? {
        let script = """
        tell application "Spotify"
            if not running then
                return ""
            end if

            if player state is stopped then
                return ""
            end if

            set trackName to name of current track
            set artistName to artist of current track
            set durationMs to duration of current track
            set currentPos to player position
            set stateText to (player state as text)
            set artworkURL to artwork url of current track

            return trackName & "|||" & artistName & "|||" & (durationMs as text) & "|||" & (currentPos as text) & "|||" & stateText & "|||" & artworkURL
        end tell
        """

        guard let raw = executeScriptString(script), !raw.isEmpty else {
            return nil
        }

        let parts = raw.components(separatedBy: "|||")
        guard parts.count >= 6 else {
            return nil
        }

        let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

        let durationMs = Double(parts[2].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let elapsedSec = Double(parts[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let state = parts[4].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let artworkURLString = parts[5].trimmingCharacters(in: .whitespacesAndNewlines)

        let durationSec = max(0, durationMs / 1000)
        let progress = durationSec > 0 ? min(max(elapsedSec / durationSec, 0), 1) : previous.progress
        let artwork = await spotifyArtwork(from: artworkURLString, fallback: previous.artwork)

        return NowPlayingSnapshot(
            title: title.isEmpty ? "Not Playing" : title,
            artist: artist.isEmpty ? "Spotify" : artist,
            artwork: artwork,
            isPlaying: state.contains("playing"),
            progress: progress,
            elapsedSeconds: elapsedSec,
            durationSeconds: durationSec,
            source: .spotify
        )
    }

    private func musicSnapshot(previous: NowPlayingSnapshot) async -> NowPlayingSnapshot? {
        let script = """
        tell application "Music"
            if not running then
                return ""
            end if

            if player state is stopped then
                return ""
            end if

            set trackName to name of current track
            set artistName to artist of current track
            set durationSec to duration of current track
            set currentPos to player position
            set stateText to (player state as text)

            return trackName & "|||" & artistName & "|||" & (durationSec as text) & "|||" & (currentPos as text) & "|||" & stateText
        end tell
        """

        guard let raw = executeScriptString(script), !raw.isEmpty else {
            return nil
        }

        let parts = raw.components(separatedBy: "|||")
        guard parts.count >= 5 else {
            return nil
        }

        let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let durationSec = Double(parts[2].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let elapsedSec = Double(parts[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let state = parts[4].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let progress = durationSec > 0 ? min(max(elapsedSec / durationSec, 0), 1) : previous.progress
        let systemArtwork = MPNowPlayingInfoCenter.default().nowPlayingInfo.flatMap { artworkImage(from: $0, fallback: nil) }
        let fallbackArtwork = systemArtwork ?? previous.artwork
        let artwork = await musicArtwork(trackName: title, artistName: artist, fallback: fallbackArtwork)

        return NowPlayingSnapshot(
            title: title.isEmpty ? "Music" : title,
            artist: artist.isEmpty ? "Apple Music" : artist,
            artwork: artwork,
            isPlaying: state.contains("playing"),
            progress: progress,
            elapsedSeconds: elapsedSec,
            durationSeconds: durationSec,
            source: .music
        )
    }

    private func musicArtwork(trackName: String, artistName: String, fallback: NSImage?) async -> NSImage? {
        let trimmedTrack = trackName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArtist = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTrack.isEmpty || !trimmedArtist.isEmpty else {
            return fallback
        }

        let cacheKey = "\(trimmedTrack.lowercased())|\(trimmedArtist.lowercased())"
        if let cached = await MusicArtworkCache.shared.image(for: cacheKey) {
            return cached
        }

        guard await MusicArtworkCache.shared.beginLoadingIfNeeded(key: cacheKey) else {
            return fallback
        }

        let query = [trimmedTrack, trimmedArtist].filter { !$0.isEmpty }.joined(separator: " ")

        Task.detached(priority: .utility) {
            defer {
                Task { await MusicArtworkCache.shared.finishLoading(key: cacheKey) }
            }

            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&entity=song&limit=1"),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = jsonObject["results"] as? [[String: Any]],
                  let first = results.first,
                  let artworkURLString = (first["artworkUrl100"] as? String) ?? (first["artworkUrl60"] as? String)
            else {
                return
            }

            let highResArtworkURLString = artworkURLString
                .replacingOccurrences(of: "100x100bb", with: "512x512bb")
                .replacingOccurrences(of: "60x60bb", with: "512x512bb")

            guard let artworkURL = URL(string: highResArtworkURLString),
                  let (artworkData, _) = try? await URLSession.shared.data(from: artworkURL),
                  let artworkImage = NSImage(data: artworkData)
            else {
                return
            }

            await MusicArtworkCache.shared.setImage(artworkImage, for: cacheKey)
        }

        return fallback
    }

    private func browserSnapshot(previous: NowPlayingSnapshot, preferredBrowserName: String? = nil) async -> NowPlayingSnapshot? {
        let allBrowsers: [(name: String, script: String)] = [
            (
                "Safari",
                """
                tell application "Safari"
                    if not running then return ""
                    if (count of documents) is 0 then return ""
                    set pageTitle to name of front document
                    set pageURL to URL of front document
                    return pageTitle & "|||" & pageURL
                end tell
                """
            ),
            (
                "Google Chrome",
                """
                tell application "Google Chrome"
                    if not running then return ""
                    if (count of windows) is 0 then return ""
                    set pageTitle to title of active tab of front window
                    set pageURL to URL of active tab of front window
                    return pageTitle & "|||" & pageURL
                end tell
                """
            ),
            (
                "Brave Browser",
                """
                tell application "Brave Browser"
                    if not running then return ""
                    if (count of windows) is 0 then return ""
                    set pageTitle to title of active tab of front window
                    set pageURL to URL of active tab of front window
                    return pageTitle & "|||" & pageURL
                end tell
                """
            ),
            (
                "Opera",
                """
                tell application "Opera"
                    if not running then return ""
                    if (count of windows) is 0 then return ""
                    set pageTitle to title of active tab of front window
                    set pageURL to URL of active tab of front window
                    return pageTitle & "|||" & pageURL
                end tell
                """
            ),
            (
                "Opera GX",
                """
                tell application "Opera GX"
                    if not running then return ""
                    if (count of windows) is 0 then return ""
                    set pageTitle to title of active tab of front window
                    set pageURL to URL of active tab of front window
                    return pageTitle & "|||" & pageURL
                end tell
                """
            )
        ]

        let browsers: [(name: String, script: String)]
        if let preferredBrowserName,
           let preferred = allBrowsers.first(where: { $0.name == preferredBrowserName }) {
            browsers = [preferred]
        } else {
            browsers = orderedBrowsersForDetection(allBrowsers)
        }

        for browser in browsers {
            guard let raw = executeScriptString(browser.script), !raw.isEmpty else {
                continue
            }

            let parts = raw.components(separatedBy: "|||")
            guard parts.count >= 2 else {
                continue
            }

            let pageTitle = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let pageURLString = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            guard isLikelyMediaPage(title: pageTitle, urlString: pageURLString) else {
                continue
            }

            let parsed = parsedTitleAndArtist(from: pageTitle)
            let sourceName = URL(string: pageURLString)?.host ?? browser.name

            let timing = browserTimingInfo(browserName: browser.name)
            let playbackState = browserPlaybackState(browserName: browser.name)
            let systemInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            let systemDuration = (systemInfo?[MPMediaItemPropertyPlaybackDuration] as? TimeInterval) ?? 0
            let systemElapsed = (systemInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval) ?? 0
            let systemPlaybackRate = (systemInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double) ?? 0
            let systemArtwork = systemInfo.flatMap { artworkImage(from: $0, fallback: nil) }
            let resolvedArtwork = await browserArtwork(urlString: pageURLString, fallback: systemArtwork)
            let youtubeDuration = await youtubeDurationFromPage(urlString: pageURLString)

            let clampedDuration = timing?.duration.isFinite == true ? max(0, timing?.duration ?? 0) : 0
            let clampedElapsed = timing?.elapsed.isFinite == true ? max(0, timing?.elapsed ?? 0) : 0

            let resolvedDuration = clampedDuration > 0
                ? clampedDuration
                : (systemDuration > 0 ? systemDuration : (youtubeDuration ?? 0))

            let sameBrowserTrack = previous.source == .browser && previous.title == parsed.title
            let playingFallback = playbackState
                ?? timing?.isPlaying
                ?? (systemPlaybackRate > 0 ? true : (sameBrowserTrack ? previous.isPlaying : false))
            let extrapolatedElapsed = sameBrowserTrack
                ? min(previous.elapsedSeconds + (playingFallback ? 0.25 : 0), resolvedDuration > 0 ? resolvedDuration : .greatestFiniteMagnitude)
                : 0

            let resolvedElapsed = resolvedDuration > 0
                ? (clampedElapsed > 0 ? clampedElapsed : (systemElapsed > 0 ? max(0, systemElapsed) : extrapolatedElapsed))
                : 0

            let progress: Double
            if resolvedDuration > 0 {
                progress = min(max(resolvedElapsed / resolvedDuration, 0), 1)
            } else {
                progress = 0
            }

            return NowPlayingSnapshot(
                title: parsed.title,
                artist: parsed.artist ?? sourceName,
                artwork: resolvedArtwork,
                isPlaying: playingFallback,
                progress: progress,
                elapsedSeconds: resolvedElapsed,
                durationSeconds: resolvedDuration,
                source: .browser
            )
        }

        return nil
    }

    private func orderedBrowsersForDetection(_ browsers: [(name: String, script: String)]) -> [(name: String, script: String)] {
        guard let frontmostName = NSWorkspace.shared.frontmostApplication?.localizedName,
              let frontmostIndex = browsers.firstIndex(where: { $0.name == frontmostName })
        else {
            return browsers
        }

        var ordered = browsers
        let frontmost = ordered.remove(at: frontmostIndex)
        ordered.insert(frontmost, at: 0)
        return ordered
    }

    private func browserArtwork(urlString: String, fallback: NSImage?) async -> NSImage? {
        guard let videoId = youtubeVideoId(from: urlString) else {
            return fallback
        }

        let key = "yt:\(videoId)"
        if let cached = await BrowserArtworkCache.shared.image(for: key) {
            return cached
        }

        guard await BrowserArtworkCache.shared.beginLoadingIfNeeded(key: key) else {
            return fallback
        }

        let url = URL(string: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg")
        Task.detached(priority: .utility) {
            defer {
                Task { await BrowserArtworkCache.shared.finishLoading(key: key) }
            }

            guard let url,
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data)
            else {
                return
            }

            await BrowserArtworkCache.shared.setImage(image, for: key)
        }

        return fallback
    }

    private func youtubeVideoId(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else {
            return nil
        }

        if let host = components.host?.lowercased(), host.contains("youtu.be") {
            let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return path.isEmpty ? nil : path
        }

        return components.queryItems?.first(where: { $0.name == "v" })?.value
    }

    private func youtubeDurationFromPage(urlString: String) async -> TimeInterval? {
        guard let videoId = youtubeVideoId(from: urlString) else {
            return nil
        }

        if let cached = await YouTubeDurationCache.shared.duration(for: videoId) {
            return cached
        }

        guard await YouTubeDurationCache.shared.beginLoadingIfNeeded(key: videoId) else {
            return nil
        }

        defer {
            Task { await YouTubeDurationCache.shared.finishLoading(key: videoId) }
        }

        guard let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") else {
            return nil
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let html = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        let patterns = [
            #"\"lengthSeconds\":\"(\d+)\""#,
            #"\"approxDurationMs\":\"(\d+)\""#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                continue
            }
            let range = NSRange(html.startIndex..., in: html)
            guard let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: html)
            else {
                continue
            }

            let raw = String(html[valueRange])
            if pattern.contains("approxDurationMs"), let ms = Double(raw), ms > 0 {
                let seconds = ms / 1000
                await YouTubeDurationCache.shared.setDuration(seconds, for: videoId)
                return seconds
            }

            if let seconds = Double(raw), seconds > 0 {
                await YouTubeDurationCache.shared.setDuration(seconds, for: videoId)
                return seconds
            }
        }

        return nil
    }

    private func browserTimingInfo(browserName: String) -> (elapsed: Double, duration: Double, isPlaying: Bool)? {
        let script: String

        if browserName == "Safari" {
            script = """
            tell application "Safari"
                if not running then return ""
                if (count of documents) is 0 then return ""
                set timingInfo to do JavaScript "(function(){const v=document.querySelector('video'); if(v){const d=(isFinite(v.duration)?v.duration:0); return String(v.currentTime)+'|||'+String(d)+'|||'+(v.paused?'0':'1');} const p=document.querySelector('#movie_player'); if(p&&typeof p.getDuration==='function'){const d=p.getDuration()||0; const t=(typeof p.getCurrentTime==='function')?p.getCurrentTime():0; const s=(typeof p.getPlayerState==='function')?p.getPlayerState():1; return String(t)+'|||'+String(d)+'|||'+(s===1?'1':'0');} return '';})();" in front document
                return timingInfo
            end tell
            """
        } else {
            script = """
            tell application "\(browserName)"
                if not running then return ""
                if (count of windows) is 0 then return ""
                set timingInfo to execute active tab of front window javascript "(function(){const v=document.querySelector('video'); if(v){const d=(isFinite(v.duration)?v.duration:0); return String(v.currentTime)+'|||'+String(d)+'|||'+(v.paused?'0':'1');} const p=document.querySelector('#movie_player'); if(p&&typeof p.getDuration==='function'){const d=p.getDuration()||0; const t=(typeof p.getCurrentTime==='function')?p.getCurrentTime():0; const s=(typeof p.getPlayerState==='function')?p.getPlayerState():1; return String(t)+'|||'+String(d)+'|||'+(s===1?'1':'0');} return '';})();"
                return timingInfo
            end tell
            """
        }

        guard let raw = executeScriptString(script), !raw.isEmpty else {
            return nil
        }

        let parts = raw.components(separatedBy: "|||")
        guard parts.count >= 3 else {
            return nil
        }

        let elapsed = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let duration = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let playing = parts[2].trimmingCharacters(in: .whitespacesAndNewlines) != "0"
        return (elapsed: elapsed, duration: duration, isPlaying: playing)
    }

    private func browserPlaybackState(browserName: String) -> Bool? {
        let script: String

        if browserName == "Safari" {
            script = """
            tell application "Safari"
                if not running then return ""
                if (count of documents) is 0 then return ""
                set stateText to do JavaScript "(function(){const v=document.querySelector('video'); if(v){return v.paused?'0':'1';} const p=document.querySelector('#movie_player'); if(p&&typeof p.getPlayerState==='function'){const s=p.getPlayerState(); return s===1?'1':'0';} return '';})();" in front document
                return stateText
            end tell
            """
        } else {
            script = """
            tell application "\(browserName)"
                if not running then return ""
                if (count of windows) is 0 then return ""
                set stateText to execute active tab of front window javascript "(function(){const v=document.querySelector('video'); if(v){return v.paused?'0':'1';} const p=document.querySelector('#movie_player'); if(p&&typeof p.getPlayerState==='function'){const s=p.getPlayerState(); return s===1?'1':'0';} return '';})();"
                return stateText
            end tell
            """
        }

        guard let raw = executeScriptString(script), !raw.isEmpty else {
            return nil
        }

        return raw.trimmingCharacters(in: .whitespacesAndNewlines) != "0"
    }

    private func toggleBrowserPlayback() -> Bool {
        let safariScript = """
        tell application "Safari"
            if not running then return ""
            if (count of documents) is 0 then return ""
            set resultText to do JavaScript "(function(){const v=document.querySelector('video'); if(!v){return '';}; if(v.paused){v.play(); return 'playing';} v.pause(); return 'paused';})();" in front document
            return resultText
        end tell
        """

        if let result = executeScriptString(safariScript), result == "playing" || result == "paused" {
            return true
        }

        let chromiumBrowsers = ["Google Chrome", "Brave Browser", "Opera", "Opera GX"]
        for browser in chromiumBrowsers {
            let script = """
            tell application "\(browser)"
                if not running then return ""
                if (count of windows) is 0 then return ""
                set resultText to execute active tab of front window javascript "(function(){const v=document.querySelector('video'); if(!v){return '';}; if(v.paused){v.play(); return 'playing';} v.pause(); return 'paused';})();"
                return resultText
            end tell
            """

            if let result = executeScriptString(script), result == "playing" || result == "paused" {
                return true
            }
        }

        return false
    }

    private func isLikelyMediaPage(title: String, urlString: String) -> Bool {
        let combined = (title + " " + urlString).lowercased()
        let markers = [
            "youtube", "youtu.be", "youtube music", "spotify", "soundcloud", "music", "podcast", "radio", "netflix", "primevideo", "hotstar", "twitch"
        ]
        return markers.contains(where: { combined.contains($0) })
    }

    private func parsedTitleAndArtist(from pageTitle: String) -> (title: String, artist: String?) {
        if let separatorRange = pageTitle.range(of: " - ") {
            let left = String(pageTitle[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let right = String(pageTitle[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !left.isEmpty {
                return (title: left, artist: right.isEmpty ? nil : right)
            }
        }
        return (title: pageTitle.isEmpty ? "Playing in Browser" : pageTitle, artist: nil)
    }

    private func spotifyArtwork(from artworkURLString: String, fallback: NSImage?) async -> NSImage? {
        guard !artworkURLString.isEmpty, let url = URL(string: artworkURLString) else {
            return fallback
        }

        let key = url.absoluteString
        if let cached = await SpotifyArtworkCache.shared.image(for: key) {
            return cached
        }

        guard await SpotifyArtworkCache.shared.beginLoadingIfNeeded(key: key) else {
            return fallback
        }

        Task.detached(priority: .utility) {
            defer {
                Task { await SpotifyArtworkCache.shared.finishLoading(key: key) }
            }

            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data)
            else {
                return
            }

            await SpotifyArtworkCache.shared.setImage(image, for: key)
        }

        return fallback
    }

    private func executeScriptString(_ source: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = []

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        if let inputData = source.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(inputData)
        }
        inputPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8) else {
            return nil
        }

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private actor SpotifyArtworkCache {
    static let shared = SpotifyArtworkCache()

    private var images: [String: NSImage] = [:]
    private var loadingKeys: Set<String> = []

    func image(for key: String) -> NSImage? {
        images[key]
    }

    func setImage(_ image: NSImage, for key: String) {
        images[key] = image
    }

    func beginLoadingIfNeeded(key: String) -> Bool {
        if loadingKeys.contains(key) {
            return false
        }

        loadingKeys.insert(key)
        return true
    }

    func finishLoading(key: String) {
        loadingKeys.remove(key)
    }
}

private actor BrowserArtworkCache {
    static let shared = BrowserArtworkCache()

    private var images: [String: NSImage] = [:]
    private var loadingKeys: Set<String> = []

    func image(for key: String) -> NSImage? {
        images[key]
    }

    func setImage(_ image: NSImage, for key: String) {
        images[key] = image
    }

    func beginLoadingIfNeeded(key: String) -> Bool {
        if loadingKeys.contains(key) {
            return false
        }

        loadingKeys.insert(key)
        return true
    }

    func finishLoading(key: String) {
        loadingKeys.remove(key)
    }
}

private actor YouTubeDurationCache {
    static let shared = YouTubeDurationCache()

    private var durations: [String: TimeInterval] = [:]
    private var loadingKeys: Set<String> = []

    func duration(for key: String) -> TimeInterval? {
        durations[key]
    }

    func setDuration(_ duration: TimeInterval, for key: String) {
        durations[key] = duration
    }

    func beginLoadingIfNeeded(key: String) -> Bool {
        if loadingKeys.contains(key) {
            return false
        }

        loadingKeys.insert(key)
        return true
    }

    func finishLoading(key: String) {
        loadingKeys.remove(key)
    }
}

private actor MusicArtworkCache {
    static let shared = MusicArtworkCache()

    private var images: [String: NSImage] = [:]
    private var loadingKeys: Set<String> = []

    func image(for key: String) -> NSImage? {
        images[key]
    }

    func setImage(_ image: NSImage, for key: String) {
        images[key] = image
    }

    func beginLoadingIfNeeded(key: String) -> Bool {
        if loadingKeys.contains(key) {
            return false
        }

        loadingKeys.insert(key)
        return true
    }

    func finishLoading(key: String) {
        loadingKeys.remove(key)
    }
}
