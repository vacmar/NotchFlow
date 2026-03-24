import AppKit

struct PermissionStatus {
    let appName: String
    let bundleIdentifier: String?
    let displayName: String
    let icon: String
    let isRequired: Bool  // Required apps (Safari, Apple Music)
    var isGranted: Bool = false
    var isInstalled: Bool = false
}

class PermissionsChecker {
    static let shared = PermissionsChecker()

    let allApps: [PermissionStatus] = [
        // Required apps
        PermissionStatus(appName: "Safari", bundleIdentifier: "com.apple.Safari", displayName: "Safari", icon: "safari", isRequired: true),
        PermissionStatus(appName: "Music", bundleIdentifier: "com.apple.Music", displayName: "Apple Music", icon: "music.note", isRequired: true),
        
        // Optional browsers
        PermissionStatus(appName: "Google Chrome", bundleIdentifier: "com.google.Chrome", displayName: "Chrome", icon: "globe", isRequired: false),
        PermissionStatus(appName: "Brave Browser", bundleIdentifier: "com.brave.Browser", displayName: "Brave", icon: "globe", isRequired: false),
        PermissionStatus(appName: "Opera", bundleIdentifier: "com.operasoftware.Opera", displayName: "Opera", icon: "globe", isRequired: false),
        PermissionStatus(appName: "Opera GX", bundleIdentifier: "com.operasoftware.OperaGX", displayName: "Opera GX", icon: "globe", isRequired: false),
        
        // Optional music apps
        PermissionStatus(appName: "Spotify", bundleIdentifier: "com.spotify.client", displayName: "Spotify", icon: "music.note", isRequired: false),
    ]

    func getPermissionStatus() -> [PermissionStatus] {
        var statuses = allApps
        for i in 0..<statuses.count {
            let isInstalled = appIsInstalled(bundleId: statuses[i].bundleIdentifier)
            statuses[i].isInstalled = isInstalled
            
            // Only check permission if app is installed
            if isInstalled {
                statuses[i].isGranted = checkPermission(for: statuses[i].appName)
            }
        }
        
        // Return only installed apps (required apps are always shown, optional only if installed)
        return statuses.filter { $0.isRequired || $0.isInstalled }
    }

    private func appIsInstalled(bundleId: String?) -> Bool {
        guard let bundleId = bundleId else { return false }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil
    }

    private func checkPermission(for appName: String, bundleId: String?) -> Bool {
        // Try to run a simple AppleScript as a permission check
        let script = """
        tell application "\(appName)"
            if running then
                return "granted"
            end if
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        _ = appleScript?.executeAndReturnError(&errorInfo)

        // If we can access the app's running state or get any result, permission is likely granted
        if errorInfo == nil {
            return true
        }

        // Check error code - 1743 typically means permission denied
        if let error = errorInfo as? [String: Any],
           let errorCode = error[NSAppleScript.errorNumber] as? Int {
            return errorCode != 1743
        }

        return false
    }
    
    private func checkPermission(for appName: String) -> Bool {
        return checkPermission(for: appName, bundleId: nil)
    }

    func openAutomationSettings() {
        let script = """
        tell application "System Settings"
            activate
            delay 0.5
        end tell
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)

        // Try to navigate to Automation - this might not work in all macOS versions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let systemEvents = """
            tell application "System Events"
                try
                    click menu item "Privacy & Security" of menu 1 of menu bar 1
                end try
            end tell
            """
            let navigationScript = NSAppleScript(source: systemEvents)
            navigationScript?.executeAndReturnError(nil)
        }
    }
}
