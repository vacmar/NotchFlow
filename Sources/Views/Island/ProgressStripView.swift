import SwiftUI

struct ProgressStripView: View {
    let progress: Double
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                Capsule()
                    .fill(fillColor)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
            }
        }
        .frame(height: 3)
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.14)
    }

    private var fillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.58)
    }
}
