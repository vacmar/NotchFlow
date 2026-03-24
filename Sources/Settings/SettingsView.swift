import SwiftUI

struct SettingsView: View {
    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue
    @AppStorage("glassThemeStyle") private var glassThemeStyleRawValue = GlassThemeStyle.frosted.rawValue
    @AppStorage("waveformStyle") private var waveformStyleRawValue = WaveformStyle.solid.rawValue
    @State private var permissionStatuses: [PermissionStatus] = []
    @State private var refreshKey = UUID()
    @StateObject private var systemAppearanceObserver = SystemAppearanceObserver()

    private let labelColumnWidth: CGFloat = 86
    private let rowHorizontalSpacing: CGFloat = 12
    private let appearanceRowSpacing: CGFloat = 14
    private let sectionBlockSpacing: CGFloat = 16
    private let permissionGroupSpacing: CGFloat = 10
    private let permissionCardRowHeight: CGFloat = 40

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

    private var themeMode: ThemeMode {
        ThemeMode.from(themeModeRawValue)
    }

    private var effectiveColorScheme: ColorScheme {
        switch themeMode {
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

    var body: some View {
        Form {
            // Theme Section
            Section {
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
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Appearance")
                    .foregroundStyle(primaryTextColor)
            }

            // Permissions Section
            Section {
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
                        let requiredApps = permissionStatuses.filter { $0.isRequired }
                        if !requiredApps.isEmpty {
                            VStack(alignment: .leading, spacing: permissionGroupSpacing) {
                                Text("Required")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(secondaryTextColor)
                                    .padding(.leading, 2)

                                permissionGroupRows(requiredApps)
                            }
                        }

                        let optionalApps = permissionStatuses.filter { !$0.isRequired }
                        if !optionalApps.isEmpty {
                            VStack(alignment: .leading, spacing: permissionGroupSpacing) {
                                Text("Detected & Optional")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(secondaryTextColor)
                                    .padding(.leading, 2)

                                permissionGroupRows(optionalApps)
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
                    }
                }

                Text("Click a toggle to open System Settings and grant permission. Only installed apps are shown.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Automation Permissions")
                    .foregroundStyle(primaryTextColor)
            }
        }
        .padding(16)
        .frame(width: 520)
        .scrollContentBackground(.hidden)
        .background(settingsBackgroundColor)
        .onAppear {
            systemAppearanceObserver.refresh()
            loadPermissions()
        }
        .onChange(of: themeModeRawValue) {
            if themeMode == .system {
                systemAppearanceObserver.refresh()
            }
        }
        .id(refreshKey)
        .environment(\.colorScheme, effectiveColorScheme)
    }

    private func loadPermissions() {
        DispatchQueue.global(qos: .userInitiated).async {
            let statuses = PermissionsChecker.shared.getPermissionStatus()
            DispatchQueue.main.async {
                permissionStatuses = statuses
            }
        }
    }

    private func refreshPermissions() {
        permissionStatuses = []
        refreshKey = UUID()
        loadPermissions()
    }

    @ViewBuilder
    private func permissionGroupRows(_ statuses: [PermissionStatus]) -> some View {
        VStack(spacing: 0) {
            ForEach(statuses.indices, id: \.self) { index in
                permissionRow(statuses[index])

                if index < statuses.count - 1 {
                    Divider()
                        .overlay(permissionCardDivider)
                        .padding(.leading, 40)
                }
            }
        }
        .background(permissionCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func permissionRow(_ status: PermissionStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .frame(width: 20)
                .foregroundColor(status.isGranted ? .blue : .gray)

            Text(status.displayName)
                .font(.system(size: 13))
                .foregroundStyle(primaryTextColor)

            Spacer(minLength: 12)

            Toggle("", isOn: Binding(
                get: { status.isGranted },
                set: { _ in
                    PermissionsChecker.shared.openAutomationSettings()
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .frame(height: permissionCardRowHeight)
        .padding(.horizontal, 12)
    }
}