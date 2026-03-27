import SwiftUI

struct SettingsView: View {
    private enum SettingsPanel: String, CaseIterable, Identifiable {
        case appearance
        case islandBehavior
        case islandTheming
        case gestures
        case automationPermissions

        var id: String { rawValue }

        var title: String {
            switch self {
            case .appearance:
                return "Appearance"
            case .islandBehavior:
                return "Island Behavior"
            case .islandTheming:
                return "Island Theming"
            case .gestures:
                return "Gestures"
            case .automationPermissions:
                return "Automation Permissions"
            }
        }

        var icon: String {
            switch self {
            case .appearance:
                return "paintbrush"
            case .islandBehavior:
                return "slider.horizontal.3"
            case .islandTheming:
                return "photo.artframe"
            case .gestures:
                return "hand.draw"
            case .automationPermissions:
                return "lock.shield"
            }
        }
    }

    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue
    @AppStorage("settingsThemeMode") private var settingsThemeModeRawValue = ThemeMode.system.rawValue
    @AppStorage("glassThemeStyle") private var glassThemeStyleRawValue = GlassThemeStyle.frosted.rawValue
    @AppStorage("waveformStyle") private var waveformStyleRawValue = WaveformStyle.solid.rawValue
    @AppStorage("timelineStyle") private var timelineStyleRawValue = TimelineStyle.solid.rawValue
    @AppStorage("islandOpacity") private var islandOpacity = 1.0
    @AppStorage("islandVisibilityMode") private var islandVisibilityModeRawValue = IslandVisibilityMode.auto.rawValue
    @AppStorage("smartAutoExpandEnabled") private var smartAutoExpandEnabled = true
    @AppStorage("focusAwareBehaviorEnabled") private var focusAwareBehaviorEnabled = false
    @AppStorage("dynamicArtworkTheming") private var dynamicArtworkTheming = true
    @AppStorage("enhancedArtworkThemingEnabled") private var enhancedArtworkThemingEnabled = true
    @AppStorage("idleDimEnabled") private var idleDimEnabled = true
    @AppStorage("clickThroughCollapsedEnabled") private var clickThroughCollapsedEnabled = true
    @AppStorage("autoHideFullscreenEnabled") private var autoHideFullscreenEnabled = true
    @State private var permissionStatuses: [PermissionStatus] = []
    @State private var refreshKey = UUID()
    @State private var lastRefreshedAt = Date()
    @State private var selectedPanel: SettingsPanel = .appearance
    @StateObject private var systemAppearanceObserver = SystemAppearanceObserver()

    private let labelColumnWidth: CGFloat = 135
    private let rowHorizontalSpacing: CGFloat = 12
    private let appearanceRowSpacing: CGFloat = 16
    private let sectionBlockSpacing: CGFloat = 16
    private let permissionGroupSpacing: CGFloat = 12
    private let permissionCardRowHeight: CGFloat = 40
    private let gestureRowSpacing: CGFloat = 14
    private let segmentedControlWidth: CGFloat = 300

    private var selectedThemeMode: Binding<ThemeMode> {
        Binding {
            ThemeMode.from(themeModeRawValue)
        } set: { newValue in
            themeModeRawValue = newValue.rawValue
        }
    }

    private var selectedGlassThemeStyle: Binding<GlassThemeStyle> {
        Binding {
            GlassThemeStyle.from(glassThemeStyleRawValue)
        } set: { newValue in
            glassThemeStyleRawValue = newValue.rawValue
        }
    }

    private var selectedWaveformStyle: Binding<WaveformStyle> {
        Binding {
            WaveformStyle.from(waveformStyleRawValue)
        } set: { newValue in
            waveformStyleRawValue = newValue.rawValue
        }
    }

    private var selectedSettingsThemeMode: Binding<ThemeMode> {
        Binding {
            ThemeMode.from(settingsThemeModeRawValue)
        } set: { newValue in
            settingsThemeModeRawValue = newValue.rawValue
        }
    }

    private var selectedTimelineStyle: Binding<TimelineStyle> {
        Binding {
            TimelineStyle.from(timelineStyleRawValue)
        } set: { newValue in
            timelineStyleRawValue = newValue.rawValue
        }
    }

    private var selectedIslandVisibilityMode: Binding<IslandVisibilityMode> {
        Binding {
            IslandVisibilityMode.from(islandVisibilityModeRawValue)
        } set: { newValue in
            islandVisibilityModeRawValue = newValue.rawValue
        }
    }

    private var themeMode: ThemeMode {
        ThemeMode.from(themeModeRawValue)
    }

    private var settingsThemeMode: ThemeMode {
        ThemeMode.from(settingsThemeModeRawValue)
    }

    private var waveformStyle: WaveformStyle {
        WaveformStyle.from(waveformStyleRawValue)
    }

    private var effectiveColorScheme: ColorScheme {
        switch settingsThemeMode {
        case .system:
            return systemAppearanceObserver.colorScheme
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    private var primaryTextColor: Color {
        IslandGlassTheme.primaryTextColor(for: effectiveColorScheme)
    }

    private var secondaryTextColor: Color {
        IslandGlassTheme.secondaryTextColor(for: effectiveColorScheme)
    }

    private var settingsBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.black.opacity(0.82) : Color.white
    }

    private var permissionCardBackground: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.045)
    }

    private var permissionCardDivider: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }

    private var sectionCardBackground: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }

    private var sectionCardBorder: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.11) : Color.black.opacity(0.09)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Text(selectedPanel.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(primaryTextColor)

                ScrollView(.vertical, showsIndicators: true) {
                    Group {
                        switch selectedPanel {
                        case .appearance:
                            appearancePanel
                        case .islandBehavior:
                            islandBehaviorPanel
                        case .islandTheming:
                            islandThemingPanel
                        case .gestures:
                            gesturesPanel
                        case .automationPermissions:
                            permissionsPanel
                        }
                    }
                    .id(refreshKey)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 720, height: 680)
        .background(settingsBackgroundColor)
        .onAppear {
            systemAppearanceObserver.refresh()
            loadPermissions()
        }
        .onChange(of: themeModeRawValue) {
            if settingsThemeMode == .system {
                systemAppearanceObserver.refresh()
            }
        }
        .onChange(of: settingsThemeModeRawValue) {
            if settingsThemeMode == .system {
                systemAppearanceObserver.refresh()
            }
        }
        .environment(\.colorScheme, effectiveColorScheme)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(SettingsPanel.allCases) { panel in
                Button {
                    selectedPanel = panel
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: panel.icon)
                            .frame(width: 16)
                        Text(panel.title)
                            .font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(selectedPanel == panel ? Color.white : primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedPanel == panel ? Color.accentColor.opacity(0.9) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 196)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(sectionCardBackground.opacity(0.75))
    }

    private var appearancePanel: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: appearanceRowSpacing) {
                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Theme")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedThemeMode) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .tag(mode)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                Text("System follows macOS appearance. Dark and Light force the island theme.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Settings")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedSettingsThemeMode) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .tag(mode)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("")
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Button("Copy island theme to Settings") {
                        settingsThemeModeRawValue = themeModeRawValue
                    }
                    .buttonStyle(.bordered)
                }

                Text("Settings theme is separate from island theme. Use the button to copy island theme quickly.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Glass")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedGlassThemeStyle) {
                        ForEach(GlassThemeStyle.allCases) { style in
                            Text(style.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .tag(style)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Waveform")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedWaveformStyle) {
                        ForEach(WaveformStyle.allCases) { style in
                            Text(style.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .tag(style)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Timeline")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedTimelineStyle) {
                        ForEach(TimelineStyle.allCases) { style in
                            Text(style.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .tag(style)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("")
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Button("Copy waveform style to Timeline") {
                        timelineStyleRawValue = waveformStyle == .gradient ? TimelineStyle.gradient.rawValue : TimelineStyle.solid.rawValue
                    }
                    .buttonStyle(.bordered)
                }

                Text("Choose Gradient for a gradient progress timeline, or copy waveform style with one click.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)


            }
        }
    }

    private var islandBehaviorPanel: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: appearanceRowSpacing) {
                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Island Opacity")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    HStack(spacing: 8) {
                        Slider(value: $islandOpacity, in: 0.3...1.0, step: 0.05)
                            .frame(width: 140)

                        Text(String(format: "%.0f%%", islandOpacity * 100))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(secondaryTextColor)
                            .frame(width: 45, alignment: .trailing)
                    }
                }

                Text("Adjust the transparency of the island window")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Mode")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Picker("", selection: selectedIslandVisibilityMode) {
                        ForEach(IslandVisibilityMode.allCases) { mode in
                            Text(mode.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .tag(mode)
                        }
                    }
                    .frame(width: segmentedControlWidth, alignment: .leading)
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                Text("Auto follows hover, while Always modes keep the island persistently visible.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Smart Expand")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $smartAutoExpandEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Temporarily expands on track/source/playback changes.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Focus Aware")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $focusAwareBehaviorEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Reduces intrusive auto-expansion while you are focused in non-media apps.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Idle Dim")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $idleDimEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Softly dims the island after inactivity to reduce distraction.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Click Through")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $clickThroughCollapsedEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("When collapsed, pass mouse clicks through the island region.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Hide Fullscreen")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $autoHideFullscreenEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Automatically hides the island while a fullscreen space is active.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var islandThemingPanel: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: appearanceRowSpacing) {
                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Artwork Theming")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $dynamicArtworkTheming)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Extract dominant color from album art for dynamic theming")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: rowHorizontalSpacing) {
                    Text("Better Theme")
                        .foregroundStyle(primaryTextColor)
                        .frame(width: labelColumnWidth, alignment: .leading)

                    Toggle("", isOn: $enhancedArtworkThemingEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Text("Improves artwork tint, border, glow, and text contrast automatically.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.leading, labelColumnWidth + rowHorizontalSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var gesturesPanel: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: gestureRowSpacing) {
                settingsGestureRow(
                    icon: "cursorarrow.motionlines",
                    title: "Hover near the notch to expand and collapse",
                    detail: "Move your cursor to the top center near the notch area"
                )

                settingsGestureRow(
                    icon: "arrow.left.and.right.circle",
                    title: "Swipe on the island to change track",
                    detail: "Left = next track, Right = previous track"
                )

                settingsGestureRow(
                    icon: "hand.draw",
                    title: "Two-finger horizontal swipe also works",
                    detail: "Use a trackpad swipe while the expanded island is visible"
                )

                settingsGestureRow(
                    icon: "app.badge",
                    title: "Click album artwork to open source app",
                    detail: "Launches Spotify, Apple Music, or the active browser source"
                )

                settingsGestureRow(
                    icon: "gearshape",
                    title: "Use the gear icon for quick settings",
                    detail: "Open Settings directly from the expanded island"
                )

                Text("These controls are available anytime while NotchFlow is running.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    private var permissionsPanel: some View {
        sectionCard {
            if permissionStatuses.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8, anchor: .center)
                    Text("Checking permissions...")
                        .font(.system(size: 13))
                        .foregroundStyle(secondaryTextColor)
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: sectionBlockSpacing) {
                    let requiredIndices = permissionStatuses.indices.filter { permissionStatuses[$0].isRequired }
                    if !requiredIndices.isEmpty {
                        VStack(alignment: .leading, spacing: permissionGroupSpacing) {
                            Text("Required")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .padding(.leading, 2)

                            permissionGroupRows(requiredIndices)
                        }
                    }

                    let optionalIndices = permissionStatuses.indices.filter { !permissionStatuses[$0].isRequired }
                    if !optionalIndices.isEmpty {
                        VStack(alignment: .leading, spacing: permissionGroupSpacing) {
                            Text("Detected & Optional")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .padding(.leading, 2)

                            permissionGroupRows(optionalIndices)
                        }
                    }

                    Button(action: refreshPermissions) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Status")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(primaryTextColor)
                    }
                    .buttonStyle(.bordered)

                    Text("Managed in System Settings → Privacy & Security → Automation")
                        .font(.caption2)
                        .foregroundStyle(secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Last refreshed: \(formattedLastRefresh)")
                        .font(.caption2)
                        .foregroundStyle(secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("Click a toggle to open System Settings and grant permission. Only installed apps are shown.")
                .font(.caption)
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func loadPermissions() {
        DispatchQueue.global(qos: .userInitiated).async {
            let statuses = PermissionsChecker.shared.getPermissionStatus()
            DispatchQueue.main.async {
                permissionStatuses = statuses
                lastRefreshedAt = Date()
            }
        }
    }

    private func refreshPermissions() {
        permissionStatuses = []
        refreshKey = UUID()
        loadPermissions()
    }

    private func settingsGestureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 16, alignment: .center)
                .foregroundColor(Color.blue.opacity(0.92))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func permissionGroupRows(_ indices: [Int]) -> some View {
        VStack(spacing: 0) {
            ForEach(indices.indices, id: \.self) { groupIndex in
                let sourceIndex = indices[groupIndex]
                permissionRow(sourceIndex)

                if groupIndex < indices.count - 1 {
                    Divider()
                        .overlay(permissionCardDivider)
                        .padding(.leading, 44)
                }
            }
        }
        .background(permissionCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(sectionCardBorder.opacity(0.75), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func permissionRow(_ index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: permissionStatuses[index].icon)
                .frame(width: 20)
                .foregroundColor(permissionStatuses[index].isGranted ? .blue : .gray)

            Text(permissionStatuses[index].displayName)
                .font(.system(size: 13))
                .foregroundStyle(primaryTextColor)

            Spacer(minLength: 12)

            Toggle("", isOn: Binding(
                get: { permissionStatuses[index].isGranted },
                set: { newValue in
                    permissionStatuses[index].isGranted = newValue
                    PermissionsChecker.shared.openAutomationSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        refreshPermissions()
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .frame(height: permissionCardRowHeight)
        .padding(.horizontal, 12)
    }

    private var formattedLastRefresh: String {
        lastRefreshedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(sectionCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(sectionCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}