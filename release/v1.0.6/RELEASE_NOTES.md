# NotchFlow v1.0.6

## Highlights
- New island visibility modes: Auto, Always Visible, and Always Expanded
- Smart auto-expand with timed recollapse when track/source state changes
- Focus-aware behavior to reduce disruptive expansion outside media contexts
- Enhanced artwork theming and adaptive text contrast
- Idle dim for low-distraction presence when inactive
- Optional click-through when the island is collapsed
- Optional auto-hide during macOS fullscreen activity
- Settings reorganized into focused sections with scrollable content

## Settings Reorganization
- Appearance: visual foundation (theme mode, glass style, waveform, timeline)
- Island Behavior: opacity, visibility mode, smart/focus/idle/interactivity controls
- Island Theming: artwork-driven theming controls
- Gestures: swipe navigation controls
- Automation Permissions: permissions setup and status

## Installation
1. Download NotchFlow-v1.0.6.dmg
2. Open the DMG
3. Drag NotchFlow to Applications
4. Launch NotchFlow from Applications

### Terminal install (optional)

Install directly from a downloaded DMG:

~~~bash
hdiutil attach "$HOME/Downloads/NotchFlow-v1.0.6.dmg"
sudo ditto "/Volumes/NotchFlow/NotchFlow.app" "/Applications/NotchFlow.app"
hdiutil detach "/Volumes/NotchFlow"
~~~

If macOS quarantine blocks launch:

~~~bash
xattr -dr com.apple.quarantine "$HOME/Downloads/NotchFlow-v1.0.6.dmg"
hdiutil attach "$HOME/Downloads/NotchFlow-v1.0.6.dmg"
xattr -dr com.apple.quarantine "/Volumes/NotchFlow/NotchFlow.app"
sudo ditto "/Volumes/NotchFlow/NotchFlow.app" "/Applications/NotchFlow.app"
xattr -dr com.apple.quarantine "/Applications/NotchFlow.app"
hdiutil detach "/Volumes/NotchFlow"
~~~

## Integrity
- SHA-256: see NotchFlow-v1.0.6.dmg.sha256
