import SwiftUI

struct PermissionsSetupView: View {
    @State private var currentStep = 0
    @State private var installedBrowsers: [String] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color(nsColor: .controlBackgroundColor)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("NotchFlow Setup")
                        .font(.system(size: 20, weight: .bold))

                    Text("Grant permissions to access your media across browsers")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                if currentStep == 0 {
                    setupStep0
                } else if currentStep == 1 {
                    setupStep1
                } else {
                    setupStep2
                }

                Spacer()

                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .keyboardShortcut(.cancelAction)
                    }

                    Spacer()

                    if currentStep < 2 {
                        Button("Next") {
                            currentStep += 1
                        }
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button("Done") {
                            UserDefaults.standard.set(true, forKey: "PermissionsSetupCompleted")
                            dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(.horizontal)
            }
            .padding(32)
        }
        .frame(minWidth: 500, minHeight: 550)
        .onAppear {
            currentStep = 0
            detectInstalledBrowsers()
        }
    }
    
    private func detectInstalledBrowsers() {
        let allBrowsers = [
            ("Safari", "com.apple.Safari"),
            ("Google Chrome", "com.google.Chrome"),
            ("Brave Browser", "com.brave.Browser"),
            ("Opera", "com.operasoftware.Opera"),
            ("Opera GX", "com.operasoftware.OperaGX")
        ]
        
        installedBrowsers = allBrowsers.filter { name, bundleId in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil
        }.map { $0.0 }
    }

    // Step 0: Overview
    var setupStep0: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Now-Playing")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Show what's playing in Spotify, Apple Music, YouTube, and more")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Controls")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Play, pause, next, and previous from the menu bar")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cross-App Support")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Spotify, Apple Music, Safari, Chrome, Brave, Opera, and more")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .separatorColor).opacity(0.3))
            .cornerRadius(8)

            Text("To enable these features, we need automation permissions for Safari and Apple Music (required), plus any other browsers you've installed.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(nil)

            Spacer()
        }
    }

    // Step 1: Browsers List
    var setupStep1: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installed Browsers")
                .font(.system(size: 14, weight: .semibold))

            if installedBrowsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No supported browsers detected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Safari is always available and will work out of the box.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(20)
            } else {
                VStack(spacing: 8) {
                    ForEach(installedBrowsers, id: \.self) { browser in
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            Text(browser)
                                .font(.system(size: 13))

                            Spacer()

                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                        .padding(10)
                        .background(Color(nsColor: .separatorColor).opacity(0.2))
                        .cornerRadius(6)
                    }
                }
            }

            Text("These browsers are installed on your system. Permission will be requested when you click Next.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(nil)

            Spacer()
        }
    }

    // Step 2: How to Grant Permissions
    var setupStep2: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Grant Permissions")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)

                        Text("Open System Settings > Privacy & Security")
                            .font(.system(size: 13))
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            openSystemSettingsAutomation()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Open Settings")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.leading, 32)
                }
                .padding(12)
                .background(Color(nsColor: .separatorColor).opacity(0.2))
                .cornerRadius(6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("2")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)

                        Text("Click \"Automation\" in the sidebar")
                            .font(.system(size: 13))
                    }
                }
                .padding(12)
                .background(Color(nsColor: .separatorColor).opacity(0.2))
                .cornerRadius(6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("3")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)

                        Text("Enable Dynamic Island for each browser")
                            .font(.system(size: 13))
                    }
                }
                .padding(12)
                .background(Color(nsColor: .separatorColor).opacity(0.2))
                .cornerRadius(6)
            }

            Text("After granting permissions, Dynamic Island will automatically detect what's playing in each app.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(nil)

            Spacer()
        }
    }

    private func openSystemSettingsAutomation() {
        // Open System Settings to Privacy & Security > Automation
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        
        // Small delay, then try to navigate to Automation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let script = """
            tell application "System Settings"
                activate
                delay 1
                tell application "System Events"
                    click menu item "Privacy & Security" of menu "View" of menu bar 1
                end tell
            end tell
            """
            let script_obj = NSAppleScript(source: script)
            script_obj?.executeAndReturnError(nil)
        }
    }
}
