import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    let colorScheme: ColorScheme
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(barColor)
                    .frame(width: 2.5, height: barHeight(index: index))
            }
        }
        .frame(height: 18)
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        guard isPlaying else { return 4 }
        let base = sin(phase + CGFloat(index) * 0.6)
        return 6 + abs(base) * 10
    }

    private var barColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.32) : Color.black.opacity(0.28)
    }
}
