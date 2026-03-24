import SwiftUI

enum WaveformStyle: String, CaseIterable, Identifiable {
    case solid
    case gradient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid:
            return "Solid"
        case .gradient:
            return "Gradient"
        }
    }

    static func from(_ rawValue: String) -> WaveformStyle {
        WaveformStyle(rawValue: rawValue) ?? .solid
    }
}
