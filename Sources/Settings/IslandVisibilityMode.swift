import Foundation

enum IslandVisibilityMode: String, CaseIterable, Identifiable {
    case auto
    case alwaysVisible
    case alwaysExpanded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            return "Auto"
        case .alwaysVisible:
            return "Always Visible"
        case .alwaysExpanded:
            return "Always Expanded"
        }
    }

    static func from(_ rawValue: String) -> IslandVisibilityMode {
        IslandVisibilityMode(rawValue: rawValue) ?? .auto
    }
}
