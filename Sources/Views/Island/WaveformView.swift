import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    let colorScheme: ColorScheme
    let style: WaveformStyle
    @State private var motionLevel: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(barFill(index: index))
                        .frame(width: 2.5, height: barHeight(index: index, time: seconds))
                }
            }
        }
        .frame(height: 18)
        .onAppear {
            motionLevel = isPlaying ? 1 : 0
        }
        .onChange(of: isPlaying) { _, playing in
            withAnimation(.easeOut(duration: playing ? 0.35 : 1.2)) {
                motionLevel = playing ? 1 : 0
            }
        }
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        let phase = CGFloat(time) * 5.2
        let base = sin(phase + CGFloat(index) * 0.65)
        let activeHeight: CGFloat = 6 + abs(base) * 10
        let restingHeight: CGFloat = 4
        return restingHeight + (activeHeight - restingHeight) * motionLevel
    }

    private func barFill(index: Int) -> AnyShapeStyle {
        switch style {
        case .solid:
            return AnyShapeStyle(
                colorScheme == .dark ? Color.white.opacity(0.32) : Color.black.opacity(0.28)
            )
        case .gradient:
            let start = colorScheme == .dark ? Color.purple.opacity(0.75) : Color.blue.opacity(0.7)
            let end = colorScheme == .dark ? Color.pink.opacity(0.75) : Color.purple.opacity(0.7)
            let phase = Double(index) / 12.0
            return AnyShapeStyle(
                LinearGradient(
                    colors: [start.opacity(0.8 + phase * 0.2), end.opacity(0.75 + phase * 0.2)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
    }
}
