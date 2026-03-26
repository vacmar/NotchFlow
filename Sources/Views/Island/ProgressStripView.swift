import SwiftUI

struct ProgressStripView: View {
    let progress: Double
    let timelineStyle: TimelineStyle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                Capsule()
                    .fill(fillStyle)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
            }
        }
        .frame(height: 3)
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.14)
    }

    private var fillStyle: AnyShapeStyle {
        switch timelineStyle {
        case .solid:
            return AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.58))
        case .gradient:
            let gradient = LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.purple.opacity(0.75), Color.pink.opacity(0.75)]
                    : [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
            return AnyShapeStyle(gradient)
        }
    }
}
