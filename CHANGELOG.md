# Changelog

All notable changes to this project are documented in this file.

## v1.0.6 - 2026-03-27

### Added
- Island visibility mode selector: Auto, Always Visible, and Always Expanded.
- Smart auto-expand for track/source/playback changes with timed recollapse.
- Focus-aware behavior option to reduce attention expansion outside media workflows.
- Enhanced artwork theming toggle with dominant-color tinting.
- Idle dim behavior for reduced visual intensity after inactivity.
- Click-through option for collapsed island mode.
- Auto-hide option while macOS fullscreen apps are active.

### Changed
- Settings UI reorganized into dedicated sections to fit fixed window constraints:
	- Appearance
	- Island Behavior
	- Island Theming
	- Gestures
	- Automation Permissions
- Settings main pane now scrolls to ensure all controls remain accessible.
- Artwork-based text contrast now adapts using luminance-aware color resolution.

### Removed
- Non-functional glass blur control and related runtime setting storage.
- Unused media-key handling remnants and dead seek code paths from earlier experiments.
- Unused Bluetooth placeholder service module.

## v1.0.5 - 2026-03-27

### Added
- Dynamic artwork theming toggle with dominant-color tinting applied to the island surface.
- Artwork color extraction utility for album art processing and caching.

### Changed
- Appearance settings spacing and layout adjusted to improve label clipping and header alignment.
- Settings window height increased to avoid top-bar text collision.

### Removed
- Non-functional glass blur control and related runtime setting storage.
- Unused media-key handling remnants and dead seek code paths from earlier experiments.
- Unused Bluetooth placeholder service module.

## v1.0.3 - 2026-03-24

### Fixed
- Setup flow now keeps action buttons visible by making setup-step content scrollable.
- Setup window minimum height increased to avoid clipped header content on first launch.
- Onboarding usability improved for end-to-end permission testing runs.

## v0.1.0 - 2026-03-24

### Added
- Initial NotchFlow release with NotchFlow style floating UI.
- Live now-playing metadata and controls for Spotify, Apple Music, and supported browsers.
- Permissions setup flow and in-settings permissions status page.
- Theme modes (System, Dark, Light) with themed settings and island surfaces.
- Horizontal swipe gestures for previous/next controls.
- Scrolling marquee text for long title/artist strings.
- DMG packaging script with drag-to-Applications installer layout.
- Status menu and app menu actions for opening settings and quitting.

### Improved
- Source-priority handling across Spotify/Music/browser contexts.
- Hover/collapse behavior around notch activation zone.
- Browser metadata, timeline fallback, and artwork resolution paths.
- App distribution readiness with release artifact scripting.
