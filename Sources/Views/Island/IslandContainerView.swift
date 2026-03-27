import AppKit
import SwiftUI

struct IslandContainerView: View {
    @ObservedObject var viewModel: IslandViewModel
    @AppStorage("themeMode") private var themeModeRawValue = ThemeMode.system.rawValue
    @AppStorage("glassThemeStyle") private var glassThemeStyleRawValue = GlassThemeStyle.frosted.rawValue
    @AppStorage("waveformStyle") private var waveformStyleRawValue = WaveformStyle.solid.rawValue
    @AppStorage("timelineStyle") private var timelineStyleRawValue = TimelineStyle.solid.rawValue
    @AppStorage("islandOpacity") private var islandOpacity = 1.0
    @AppStorage("islandVisibilityMode") private var islandVisibilityModeRawValue = IslandVisibilityMode.auto.rawValue
    @AppStorage("focusAwareBehaviorEnabled") private var focusAwareBehaviorEnabled = false
    @AppStorage("dynamicArtworkTheming") private var dynamicArtworkTheming = true
    @AppStorage("enhancedArtworkThemingEnabled") private var enhancedArtworkThemingEnabled = true
    @AppStorage("idleDimEnabled") private var idleDimEnabled = true
    @StateObject private var systemAppearanceObserver = SystemAppearanceObserver()
    @State private var isExpandedContentHovering = false
    @State private var collapseWorkItem: DispatchWorkItem?
    @State private var lastInteractionDate = Date()
    @State private var currentTimestamp = Date()

    private var themeMode: ThemeMode {
        ThemeMode.from(themeModeRawValue)
    }

    private var glassThemeStyle: GlassThemeStyle {
        GlassThemeStyle.from(glassThemeStyleRawValue)
    }

    private var waveformStyle: WaveformStyle {
        WaveformStyle.from(waveformStyleRawValue)
    }

    private var timelineStyle: TimelineStyle {
        TimelineStyle.from(timelineStyleRawValue)
    }

    private var islandVisibilityMode: IslandVisibilityMode {
        IslandVisibilityMode.from(islandVisibilityModeRawValue)
    }

    private var artworkThemeColor: NSColor? {
        guard dynamicArtworkTheming,
              let artworkImage = viewModel.snapshot.artwork,
              let dominantColor = ArtworkColorExtractor.dominantColor(from: artworkImage)
        else {
            return nil
        }

        let nsColor = NSColor(dominantColor).usingColorSpace(.deviceRGB) ?? NSColor(dominantColor)
        guard enhancedArtworkThemingEnabled else {
            return nsColor
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let tunedSaturation = max(0.25, min(0.68, saturation * 0.86))
        let tunedBrightness = effectiveColorScheme == .dark
            ? max(0.34, min(0.82, brightness * 0.9))
            : max(0.5, min(0.92, brightness * 1.06))

        return NSColor(
            hue: hue,
            saturation: tunedSaturation,
            brightness: tunedBrightness,
            alpha: 1.0
        )
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
        if let artworkThemeColor {
            let opacity = enhancedArtworkThemingEnabled
                ? (effectiveColorScheme == .dark ? 0.5 : 0.38)
                : 0.6
            return Color(artworkThemeColor).opacity(opacity)
        }

        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.08)
        }

        return IslandGlassTheme.tintColor(for: effectiveColorScheme)
    }

    private var islandBorderColor: Color {
        if enhancedArtworkThemingEnabled, let artworkThemeColor {
            let rgbColor = artworkThemeColor.usingColorSpace(.deviceRGB) ?? artworkThemeColor
            let luminance = 0.2126 * rgbColor.redComponent + 0.7152 * rgbColor.greenComponent + 0.0722 * rgbColor.blueComponent
            let alpha = luminance < 0.52 ? 0.34 : 0.2
            return Color(artworkThemeColor).opacity(alpha)
        }

        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.26) : Color.black.opacity(0.16)
        }

        return IslandGlassTheme.borderColor(for: effectiveColorScheme)
    }

    private var islandGlowColor: Color {
        if enhancedArtworkThemingEnabled, let artworkThemeColor {
            return Color(artworkThemeColor).opacity(effectiveColorScheme == .dark ? 0.2 : 0.14)
        }

        if glassThemeStyle == .clear {
            return effectiveColorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.1)
        }

        return IslandGlassTheme.glowColor(for: effectiveColorScheme)
    }

    private var islandShadowColor: Color {
        if enhancedArtworkThemingEnabled, let artworkThemeColor {
            return Color(artworkThemeColor).opacity(effectiveColorScheme == .dark ? 0.28 : 0.18)
        }

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

    private var resolvedPrimaryTextColor: Color {
        guard enhancedArtworkThemingEnabled, let artworkThemeColor else {
            return IslandGlassTheme.primaryTextColor(for: effectiveColorScheme)
        }

        let rgbColor = artworkThemeColor.usingColorSpace(.deviceRGB) ?? artworkThemeColor
        let luminance = 0.2126 * rgbColor.redComponent + 0.7152 * rgbColor.greenComponent + 0.0722 * rgbColor.blueComponent
        return luminance < 0.48 ? .white : Color.black.opacity(0.86)
    }

    private var resolvedSecondaryTextColor: Color {
        guard enhancedArtworkThemingEnabled, let artworkThemeColor else {
            return IslandGlassTheme.secondaryTextColor(for: effectiveColorScheme)
        }

        let rgbColor = artworkThemeColor.usingColorSpace(.deviceRGB) ?? artworkThemeColor
        let luminance = 0.2126 * rgbColor.redComponent + 0.7152 * rgbColor.greenComponent + 0.0722 * rgbColor.blueComponent
        return luminance < 0.48 ? Color.white.opacity(0.75) : Color.black.opacity(0.58)
    }

    private var effectiveIslandOpacity: Double {
        guard idleDimEnabled else { return islandOpacity }
        guard islandVisibilityMode != .alwaysExpanded, !viewModel.isExpanded else { return islandOpacity }

        let baseIdleThreshold: TimeInterval = focusAwareBehaviorEnabled ? 3.5 : 8.0
        let idleFor = currentTimestamp.timeIntervalSince(lastInteractionDate)
        guard idleFor >= baseIdleThreshold else { return islandOpacity }

        return max(0.34, islandOpacity * 0.58)
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
                        if hovering {
                            lastInteractionDate = Date()
                        }
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
        .opacity(effectiveIslandOpacity)
        .onAppear {
            systemAppearanceObserver.refresh()
            lastInteractionDate = Date()
            currentTimestamp = Date()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { timestamp in
            currentTimestamp = timestamp
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
                    color: resolvedPrimaryTextColor,
                    fontSize: 13,
                    fontWeight: .semibold,
                    scrollSpeed: 28,
                    gap: 36
                )
                    .help(viewModel.snapshot.title)

                ScrollingSubtitleText(
                    text: viewModel.snapshot.artist,
                    color: resolvedSecondaryTextColor
                )
                .help(viewModel.snapshot.artist)

                ProgressStripView(
                    progress: viewModel.snapshot.progress,
                    timelineStyle: timelineStyle
                )

                HStack(spacing: 6) {
                    Text(formattedElapsed)
                    Text("/")
                    Text(formattedDuration)
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(resolvedSecondaryTextColor)
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
                        openSettingsWindow()
                        centerSettingsWindow()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(resolvedSecondaryTextColor)
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

    private func openSettingsWindow() {
        NotificationCenter.default.post(name: .notchFlowOpenSettingsRequested, object: nil)
    }

    private func updateHoverState() {
        if islandVisibilityMode != .auto {
            viewModel.setHovering(false)
            return
        }

        let shouldExpand = isExpandedContentHovering

        if shouldExpand {
            collapseWorkItem?.cancel()
            lastInteractionDate = Date()
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
