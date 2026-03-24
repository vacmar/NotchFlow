import AppKit
import SwiftUI

struct IslandContainerView: View {
    @ObservedObject var viewModel: IslandViewModel
    @Environment(\.openSettings) private var openSettings
    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue
    @AppStorage("glassThemeStyle") private var glassThemeStyleRawValue = GlassThemeStyle.frosted.rawValue
    @AppStorage("waveformStyle") private var waveformStyleRawValue = WaveformStyle.solid.rawValue
    @StateObject private var systemAppearanceObserver = SystemAppearanceObserver()
    @State private var isExpandedContentHovering = false
    @State private var collapseWorkItem: DispatchWorkItem?

    private var themeMode: ThemeMode {
        ThemeMode.from(themeModeRawValue)
    }

    private var glassThemeStyle: GlassThemeStyle {
        GlassThemeStyle.from(glassThemeStyleRawValue)
    }

    private var waveformStyle: WaveformStyle {
        WaveformStyle.from(waveformStyleRawValue)
    }

    private var islandBaseFillStyle: AnyShapeStyle {
        if glassThemeStyle == .clear {
            if effectiveColorScheme == .dark {
                return AnyShapeStyle(Color.white.opacity(0.025))
            }
            return AnyShapeStyle(Color.white.opacity(0.12))
        }

        return AnyShapeStyle(.ultraThinMaterial)
    }

    private var islandTintColor: Color {
        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.08)
        }

        return IslandGlassTheme.tintColor(for: effectiveColorScheme)
    }

    private var islandBorderColor: Color {
        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.26) : Color.black.opacity(0.16)
        }

        return IslandGlassTheme.borderColor(for: effectiveColorScheme)
    }

    private var islandGlowColor: Color {
        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.1)
        }

        return IslandGlassTheme.glowColor(for: effectiveColorScheme)
    }

    private var islandShadowColor: Color {
        if glassThemeStyle == .clear {
            return IslandGlassTheme.shadowColor(for: effectiveColorScheme).opacity(0.35)
        }

        return IslandGlassTheme.shadowColor(for: effectiveColorScheme)
    }

    private var effectiveColorScheme: ColorScheme {
        switch themeMode {
        case .system:
            return systemAppearanceObserver.colorScheme
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    var body: some View {
        let size = viewModel.isExpanded ? IslandGlassTheme.expandedSize : IslandGlassTheme.collapsedSize
        let islandShape = UnevenRoundedRectangle(
            topLeadingRadius: IslandGlassTheme.topCornerRadius,
            bottomLeadingRadius: IslandGlassTheme.bottomCornerRadius,
            bottomTrailingRadius: IslandGlassTheme.bottomCornerRadius,
            topTrailingRadius: IslandGlassTheme.topCornerRadius,
            style: .continuous
        )

        ZStack {
            islandShape
                .fill(islandBaseFillStyle)
                .overlay(
                    islandShape.fill(islandTintColor)
                )
                .overlay(
                    islandShape
                        .stroke(islandBorderColor, lineWidth: 1)
                )
                .background(
                    islandShape
                        .fill(islandGlowColor)
                        .blur(radius: 14)
                )
                .shadow(color: islandShadowColor, radius: 24, y: 6)
                .allowsHitTesting(viewModel.isExpanded)

            if viewModel.isExpanded {
                expandedBody
                    .padding(10)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isExpandedContentHovering = hovering
                        updateHoverState()
                    }
                    .allowsHitTesting(true)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                collapsedBody
                    .allowsHitTesting(true)
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(IslandAnimation.expand, value: viewModel.isExpanded)
        .preferredColorScheme(effectiveColorScheme)
        .onAppear {
            systemAppearanceObserver.refresh()
        }
    }

    private var collapsedBody: some View {
        Capsule(style: .continuous)
            .fill(IslandGlassTheme.collapsedPillColor(for: effectiveColorScheme))
            .frame(width: 72, height: 12)
    }

    private var expandedBody: some View {
        let albumShiftX: CGFloat = 20
        let albumShiftY: CGFloat = 5.5
        let textColumnMaxWidth: CGFloat = 182
        let controlsColumnWidth: CGFloat = 136

        return HStack(alignment: .center, spacing: 12) {
            Button {
                viewModel.openCurrentSourceApp()
            } label: {
                artwork
            }
            .buttonStyle(.plain)
            .help("Open source app")
            .frame(width: 68, alignment: .center)
            .offset(x: albumShiftX, y: albumShiftY)

            VStack(alignment: .leading, spacing: 5) {
                ScrollingLineText(
                    text: viewModel.snapshot.title,
                    color: IslandGlassTheme.primaryTextColor(for: effectiveColorScheme),
                    fontSize: 13,
                    fontWeight: .semibold,
                    scrollSpeed: 28,
                    gap: 36
                )
                    .help(viewModel.snapshot.title)

                ScrollingSubtitleText(
                    text: viewModel.snapshot.artist,
                    color: IslandGlassTheme.secondaryTextColor(for: effectiveColorScheme)
                )
                .help(viewModel.snapshot.artist)

                ProgressStripView(progress: viewModel.snapshot.progress)

                HStack(spacing: 6) {
                    Text(formattedElapsed)
                    Text("/")
                    Text(formattedDuration)
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(IslandGlassTheme.secondaryTextColor(for: effectiveColorScheme))
            }
            .padding(.top, 35)
            .frame(maxWidth: textColumnMaxWidth, alignment: .leading)
            .offset(x: 38, y: 4)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 8) {
                    WaveformView(
                        isPlaying: viewModel.snapshot.isPlaying,
                        colorScheme: effectiveColorScheme,
                        style: waveformStyle
                    )
                    Button {
                        openSettings()
                        centerSettingsWindow()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(IslandGlassTheme.secondaryTextColor(for: effectiveColorScheme))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }

                TransportControlsView(
                    isPlaying: viewModel.snapshot.isPlaying,
                    colorScheme: effectiveColorScheme,
                    onPrevious: viewModel.previous,
                    onToggle: viewModel.togglePlayPause,
                    onNext: viewModel.next
                )
            }
            .frame(width: controlsColumnWidth, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .center)
            .offset(y: 6)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    viewModel.handleHorizontalSwipe(value.translation.width)
                }
        )
    }

    private var artwork: some View {
        Group {
            if let image = viewModel.snapshot.artwork {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.8)))
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
        )
        .scaleEffect(viewModel.isExpanded ? 1 : 0.92)
    }

    private func centerSettingsWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) else {
                return
            }
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateHoverState() {
        let shouldExpand = isExpandedContentHovering

        if shouldExpand {
            collapseWorkItem?.cancel()
            viewModel.setHovering(true)
            return
        }

        collapseWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            viewModel.setHovering(false)
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private var formattedElapsed: String {
        formattedTime(viewModel.snapshot.elapsedSeconds)
    }

    private var formattedDuration: String {
        let duration = viewModel.snapshot.durationSeconds
        if duration <= 0 {
            return "--:--"
        }
        return formattedTime(duration)
    }

    private func formattedTime(_ value: TimeInterval) -> String {
        let safeValue = max(0, Int(value.rounded()))
        let minutes = safeValue / 60
        let seconds = safeValue % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct ScrollingSubtitleText: View {
    let text: String
    let color: Color

    private let fontSize: CGFloat = 11
    private let gap: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let contentWidth = measuredTextWidth
            let shouldScroll = contentWidth > availableWidth
            let travel = contentWidth + gap
            let duration = max(6, Double(travel / 22))

            Group {
                if shouldScroll {
                    TimelineView(.animation) { timeline in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                        let phase = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
                        let offset = -phase * travel

                        HStack(spacing: gap) {
                            subtitleText
                            subtitleText
                        }
                        .offset(x: offset)
                    }
                } else {
                    subtitleText
                }
            }
            .frame(width: availableWidth, alignment: .leading)
            .clipped()
        }
        .frame(height: 14)
    }

    private var subtitleText: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundStyle(color)
            .fixedSize()
    }

    private var measuredTextWidth: CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize)
        ]
        return NSString(string: text).size(withAttributes: attributes).width
    }
}

private struct ScrollingLineText: View {
    let text: String
    let color: Color
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let scrollSpeed: CGFloat
    let gap: CGFloat

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let contentWidth = measuredTextWidth
            let shouldScroll = contentWidth > availableWidth
            let travel = contentWidth + gap
            let duration = max(6, Double(travel / max(1, scrollSpeed)))

            Group {
                if shouldScroll {
                    TimelineView(.animation) { timeline in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                        let phase = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
                        let offset = -phase * travel

                        HStack(spacing: gap) {
                            lineText
                            lineText
                        }
                        .offset(x: offset)
                    }
                } else {
                    lineText
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: availableWidth, alignment: .leading)
            .clipped()
        }
        .frame(height: max(14, fontSize + 1))
    }

    private var lineText: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundStyle(color)
            .fixedSize()
    }

    private var measuredTextWidth: CGFloat {
        let nsWeight: NSFont.Weight = {
            switch fontWeight {
            case .ultraLight: return .ultraLight
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            default: return .regular
            }
        }()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: nsWeight)
        ]
        return NSString(string: text).size(withAttributes: attributes).width
    }
}
