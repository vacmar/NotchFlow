# NotchFlow

NotchFlow is a macOS menu-bar style Dynamic Island experience for live media playback. It stays near the notch area, expands on hover, shows now-playing metadata, and gives quick transport controls.

## Highlights

- Dynamic Island style UI with collapsed and expanded states
- Live now-playing support for:
	- Spotify
	- Apple Music
	- Browser media tabs (Safari, Chrome, Brave, Opera, Opera GX)
- Source-aware playback controls (play/pause/next/previous)
- Progress strip + elapsed/duration timeline
- Animated waveform while playing
- Marquee text for long titles/artists
- Horizontal swipe gesture for next/previous
- Theme modes: System, Dark, Light
- First-run permissions setup and status panel in Settings

## Requirements

- macOS 14+
- Swift 5.10+

## Run from source

```bash
swift build
swift run NotchFlow
```

## Controls

- Hover near notch area to expand/collapse
- Click media controls in expanded view
- Swipe left/right on expanded island for next/previous
- Open Settings from gear icon
- Quit via:
	- menu bar icon → Quit NotchFlow
	- app menu → Quit NotchFlow
	- Cmd+Q

## Permissions

NotchFlow uses Apple Events automation for app and browser media access.

Grant access in:

System Settings → Privacy & Security → Automation

Required apps:
- Safari
- Apple Music

Optional (detected if installed):
- Chrome
- Brave
- Opera
- Opera GX
- Spotify

Use Settings → Automation Permissions to review and refresh permission state.

## Build .app and .dmg

Use the packaging script:

```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

For Developer ID signing (recommended for public releases):

```bash
export SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./scripts/package_dmg.sh
```

Output artifacts:

- dist/NotchFlow.app
- dist/NotchFlow.dmg

The DMG is built with drag-to-Applications layout (includes an Applications shortcut and icon positioning).

## Notarization (works with private repos)

Notarization is local-to-your-Mac and Apple Developer account. Your GitHub repo can stay private.

1) Export notarization credentials:

```bash
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="YOURTEAMID"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

2) Notarize a generated DMG:

```bash
./scripts/notarize.sh dist/NotchFlow.dmg
```

Or notarize during release build:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARIZE=1 ./scripts/release.sh 1.0.0
```

## Release process

Create a versioned release bundle:

```bash
chmod +x scripts/release.sh
./scripts/release.sh 0.1.0
```

Optional notarized release:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARIZE=1 ./scripts/release.sh 1.0.0
```

This generates:

- release/v0.1.0/NotchFlow-v0.1.0.app
- release/v0.1.0/NotchFlow-v0.1.0.dmg
- release/v0.1.0/NotchFlow-v0.1.0.dmg.sha256
- release/v0.1.0/RELEASE_NOTES.md

Then publish on GitHub Releases:

1. Push tag `v0.1.0`
2. Open the repository Releases page
3. Draft new release from tag `v0.1.0`
4. Upload the DMG and SHA-256 files
5. Paste release notes from `release/v0.1.0/RELEASE_NOTES.md`

## Project structure

- Sources/DynamicIslandApp.swift: app lifecycle, menu/status controls
- Sources/AppWindow: notch window controller + positioning
- Sources/ViewModels: island state, polling, commands
- Sources/Services/NowPlaying: media detection and control
- Sources/Services/Permissions: permissions checks
- Sources/Views/Island: island UI
- Sources/Views/Setup: first-run setup UI
- Sources/Settings: theme and permissions settings

## Known behavior notes

- Browser metadata/timeline quality depends on site/player and granted automation access.
- If multiple apps are active, NotchFlow prioritizes the frontmost source first, then other playing sources.

## Troubleshooting

- No metadata:
	- Check Automation permissions in Settings
	- Ensure source app/tab is actively playing
- Timeline shows `--:--`:
	- Some pages do not expose timing data consistently
	- Keep the media tab frontmost for best accuracy
- App does not exit:
	- Use Cmd+Q or menu bar → Quit NotchFlow

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
