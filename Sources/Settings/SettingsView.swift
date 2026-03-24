import SwiftUI

struct SettingsView: View {
    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue
    @State private var permissionStatuses: [PermissionStatus] = []
    @State private var refreshKey = UUID()
    @StateObject private var systemAppearanceObserver = SystemAppearanceObserver()

    private var selectedThemeMode: Binding<ThemeMode> {
        Binding {
            ThemeMode.from(themeModeRawValue)
        } set: { newValue in
            themeModeRawValue = newValue.rawValue
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

    var body: some View {
        Form {
            // Theme Section
            Section {
                Picker(selection: selectedThemeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                } label: {
                    Text("Theme")
                        .foregroundStyle(primaryTextColor)
                }
                .pickerStyle(.segmented)

                Text("System follows macOS appearance. Dark and Light force the island theme.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
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
                    // Required apps
                    let requiredApps = permissionStatuses.filter { $0.isRequired }
                    if !requiredApps.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Required")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 10) {
                                ForEach(requiredApps.indices, id: \.self) { index in
                                    let status = requiredApps[index]
                                    HStack(spacing: 12) {
                                        Image(systemName: status.icon)
                                            .frame(width: 20)
                                            .foregroundColor(status.isGranted ? .blue : .gray)

                                        Text(status.displayName)
                                            .font(.system(size: 13))
                                            .foregroundStyle(primaryTextColor)

                                        Spacer()

                                        Toggle("", isOn: Binding(
                                            get: { status.isGranted },
                                            set: { _ in
                                                PermissionsChecker.shared.openAutomationSettings()
                                            }
                                        ))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    
                    // Optional installed apps
                    let optionalApps = permissionStatuses.filter { !$0.isRequired }
                    if !optionalApps.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Detected & Optional")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 10) {
                                ForEach(optionalApps.indices, id: \.self) { index in
                                    let status = optionalApps[index]
                                    HStack(spacing: 12) {
                                        Image(systemName: status.icon)
                                            .frame(width: 20)
                                            .foregroundColor(status.isGranted ? .blue : .gray)

                                        Text(status.displayName)
                                            .font(.system(size: 13))
                                            .foregroundStyle(primaryTextColor)

                                        Spacer()

                                        Toggle("", isOn: Binding(
                                            get: { status.isGranted },
                                            set: { _ in
                                                PermissionsChecker.shared.openAutomationSettings()
                                            }
                                        ))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
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
                    .padding(.top, 12)
                }

                Text("Click a toggle to open System Settings and grant permission. Only installed apps are shown.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
            } header: {
                Text("Automation Permissions")
                    .foregroundStyle(primaryTextColor)
            }
        }
        .padding(16)
        .frame(width: 420)
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
}