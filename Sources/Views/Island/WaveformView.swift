import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    let colorScheme: ColorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(barColor)
                        .frame(width: 2.5, height: barHeight(index: index, time: seconds))
                }
            }
        }
        .frame(height: 18)
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        guard isPlaying else { return 4 }
        let phase = CGFloat(time) * 5.2
        let base = sin(phase + CGFloat(index) * 0.65)
        return 6 + abs(base) * 10
    }

    private var barColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.32) : Color.black.opacity(0.28)
    }
}
