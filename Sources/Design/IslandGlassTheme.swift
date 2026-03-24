import SwiftUI

enum IslandGlassTheme {
    static let collapsedSize = CGSize(width: 128, height: 34)
    static let expandedSize = CGSize(width: 438, height: 126)
    static let topCornerRadius: CGFloat = 10
    static let bottomCornerRadius: CGFloat = 24

    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.34) : Color.black.opacity(0.16)
    }

    static func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.1)
    }

    static func glowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.34)
    }

    static func tintColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.4)
    }

    static func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.86)
    }

    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.56)
    }

    static func collapsedPillColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.58) : Color.black.opacity(0.26)
    }
}
