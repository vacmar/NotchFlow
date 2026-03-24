# NotchFlow for Mac

Open-source macOS floating Dynamic Island widget inspired by Apple Dynamic Island + Alcove-style hover expansion.

## Current status

This repository includes an initial `M0` implementation:
- Floating, top-centered island window (always-on-top feel)
- Collapsed pill state and hover-expand state
- Apple-style frosted glass visual language
- Live now-playing metadata from system media session (title, artist, artwork, progress, timeline)
- Progress strip + subtle waveform animation
- Transport commands wired for Apple Music / Spotify fallback via AppleScript
- Horizontal swipe on expanded island for previous/next track
- Long title and subtitle lines scroll when content exceeds available width

## Tech stack

- SwiftUI + AppKit
- Swift Package (`swift build` / `swift run`)
- macOS 14+

## Run locally

```bash
swift build
swift run NotchFlow
```

## Build app and DMG

```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

Artifacts are generated in `dist/`:
- `dist/NotchFlow.app`
- `dist/NotchFlow.dmg`

## Roadmap

- `M1a`: system now-playing integration (Apple Music/Spotify/compliant apps)
- `M1b`: Apple Music fallback provider + gesture/micro-interaction polish
- `M2`: Spotify OAuth adapter, browser metadata assist, CI hardening, `v0.1.0`

## Compatibility notes

Cross-app recognition is best-effort and depends on each app/tab exposing media session metadata to macOS.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
