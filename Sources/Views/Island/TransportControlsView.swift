import AppKit
import SwiftUI

struct TransportControlsView: View {
    let isPlaying: Bool
    let colorScheme: ColorScheme
    let onPrevious: () -> Void
    let onToggle: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ControlButton(symbol: "backward.fill", colorScheme: colorScheme, action: onPrevious)
            ControlButton(symbol: isPlaying ? "pause.fill" : "play.fill", colorScheme: colorScheme, action: onToggle)
            ControlButton(symbol: "forward.fill", colorScheme: colorScheme, action: onNext)
        }
    }
}

private struct ControlButton: View {
    let symbol: String
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 26, height: 26)
                .background(Circle().fill(backgroundColor))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering ? 1.06 : 1)
        .opacity(hovering ? 1 : 0.92)
        .animation(IslandAnimation.controlsFade, value: hovering)
        .onHover { hovering in
            self.hovering = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    private var iconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.75)
    }

    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(hovering ? 0.16 : 0.08)
        }
        return Color.black.opacity(hovering ? 0.12 : 0.06)
    }
}
