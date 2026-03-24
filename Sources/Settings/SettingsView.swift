import SwiftUI

struct SettingsView: View {
    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue

    private var selectedThemeMode: Binding<ThemeMode> {
        Binding {
            ThemeMode.from(themeModeRawValue)
        } set: { newValue in
            themeModeRawValue = newValue.rawValue
        }
    }

    var body: some View {
        Form {
            Picker("Theme", selection: selectedThemeMode) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("System follows macOS appearance. Dark and Light force the island theme.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 420)
    }
}