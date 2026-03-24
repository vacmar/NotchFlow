import SwiftUI

enum GlassThemeStyle: String, CaseIterable, Identifiable {
    case frosted
    case clear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .frosted:
            return "Frosted"
        case .clear:
            return "Clear"
        }
    }

    static func from(_ rawValue: String) -> GlassThemeStyle {
        GlassThemeStyle(rawValue: rawValue) ?? .frosted
    }
}
