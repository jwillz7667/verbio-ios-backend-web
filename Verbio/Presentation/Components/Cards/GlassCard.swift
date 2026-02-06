//
//  GlassCard.swift
//  Verbio
//
//  Liquid Glass styled card component
//

import SwiftUI

// MARK: - Glass Card Style

enum GlassCardStyle {
    case standard   // Default card with subtle warm tint
    case elevated   // More prominent glass effect with depth
    case subtle     // Minimal glass for secondary content
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: GlassCardStyle
    let cornerRadius: CGFloat
    let content: Content

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        style: GlassCardStyle = .standard,
        cornerRadius: CGFloat = VerbioSpacing.CornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .verbioCardPadding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular.tint(glassTint), in: .rect(cornerRadius: cornerRadius))
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
        } else {
            content
                .verbioCardPadding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fallbackMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
        }
    }

    private var glassTint: Color {
        switch style {
        case .standard: return VerbioGlass.warmTint
        case .elevated: return VerbioGlass.amberTint
        case .subtle: return VerbioGlass.warmTint
        }
    }

    @available(iOS, deprecated: 26.0, message: "Use glassEffect on iOS 26+")
    private var fallbackMaterial: some ShapeStyle {
        switch style {
        case .standard:
            return .thinMaterial
        case .elevated:
            return .regularMaterial
        case .subtle:
            return .ultraThinMaterial
        }
    }

    private var shadowColor: Color {
        switch style {
        case .standard:
            return Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06)
        case .elevated:
            return Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08)
        case .subtle:
            return Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .standard: return 8
        case .elevated: return 12
        case .subtle: return 4
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .standard: return 2
        case .elevated: return 4
        case .subtle: return 1
        }
    }
}

// MARK: - Interactive Glass Card

struct InteractiveGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: GlassCardStyle
    let cornerRadius: CGFloat
    let action: () -> Void
    let content: Content

    @State private var isPressed = false

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        style: GlassCardStyle = .standard,
        cornerRadius: CGFloat = VerbioSpacing.CornerRadius.lg,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            if #available(iOS 26.0, *) {
                content
                    .verbioCardPadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.tint(VerbioGlass.warmTint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .verbioCardPadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
            radius: isPressed ? 4 : 8,
            x: 0,
            y: isPressed ? 1 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(VerbioAnimations.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color?

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
    }

    var body: some View {
        GlassCard {
            HStack(spacing: VerbioSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor ?? colors.brand.primary)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: VerbioSpacing.xxs) {
                    Text(title)
                        .verbioLabelLarge()
                        .foregroundStyle(colors.text.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .verbioCaption()
                            .foregroundStyle(colors.text.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let icon: String
    let trend: Double?

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        title: String,
        value: String,
        icon: String,
        trend: Double? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.trend = trend
    }

    var body: some View {
        GlassCard(style: .elevated) {
            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(colors.brand.primary)

                    Spacer()

                    if let trend = trend {
                        TrendBadge(value: trend)
                    }
                }

                Text(value)
                    .verbioDisplaySmall()
                    .foregroundStyle(colors.text.primary)

                Text(title)
                    .verbioCaption()
                    .foregroundStyle(colors.text.secondary)
            }
        }
    }
}

// MARK: - Trend Badge

private struct TrendBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let value: Double

    var isPositive: Bool {
        value >= 0
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))

            Text("\(abs(value), specifier: "%.0f")%")
                .font(VerbioTypography.Scaled.caption2)
        }
        .foregroundStyle(isPositive ? VerbioColors.Semantic.success : VerbioColors.Semantic.error)
        .padding(.horizontal, VerbioSpacing.xs)
        .padding(.vertical, VerbioSpacing.xxs)
        .background(
            Capsule()
                .fill((isPositive ? VerbioColors.Semantic.success : VerbioColors.Semantic.error).opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview("Glass Cards - Light") {
    GlassCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Glass Cards - Dark") {
    GlassCardPreview()
        .preferredColorScheme(.dark)
}

private struct GlassCardPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.3),
                    VerbioColors.Accent.warmOrange.opacity(0.2),
                    colors.backgrounds.primary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: VerbioSpacing.xl) {
                    // Standard Card
                    VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                        Text("Standard Card")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassCard {
                            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                                Text("Recent Translation")
                                    .verbioHeadlineMedium()
                                    .foregroundStyle(colors.text.primary)

                                Text("Hello, how are you?")
                                    .verbioBodyMedium()
                                    .foregroundStyle(colors.text.secondary)

                                Text("Hola, ¿cómo estás?")
                                    .verbioBodyMedium()
                                    .foregroundStyle(colors.brand.primary)
                            }
                        }
                    }

                    // Elevated Card
                    VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                        Text("Elevated Card")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassCard(style: .elevated) {
                            HStack {
                                VStack(alignment: .leading, spacing: VerbioSpacing.xs) {
                                    Text("Pro Plan")
                                        .verbioHeadlineMedium()
                                        .foregroundStyle(colors.text.primary)

                                    Text("300 minutes/month")
                                        .verbioCaption()
                                        .foregroundStyle(colors.text.secondary)
                                }

                                Spacer()

                                Text("$9.99")
                                    .verbioDisplaySmall()
                                    .foregroundStyle(colors.brand.primary)
                            }
                        }
                    }

                    // Interactive Card
                    VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                        Text("Interactive Card")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        InteractiveGlassCard(action: {}) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 24))
                                    .foregroundStyle(colors.brand.primary)

                                VStack(alignment: .leading) {
                                    Text("Spanish")
                                        .verbioLabelLarge()
                                        .foregroundStyle(colors.text.primary)

                                    Text("Tap to change")
                                        .verbioCaption()
                                        .foregroundStyle(colors.text.tertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }
                    }

                    // Info Card
                    VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                        Text("Info Card")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        InfoCard(
                            icon: "waveform",
                            title: "Translation Complete",
                            subtitle: "3 seconds ago"
                        )
                    }

                    // Stats Cards
                    VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                        Text("Stats Cards")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        HStack(spacing: VerbioSpacing.md) {
                            StatsCard(
                                title: "Minutes Used",
                                value: "24.5",
                                icon: "clock.fill",
                                trend: 12
                            )

                            StatsCard(
                                title: "Translations",
                                value: "156",
                                icon: "text.bubble.fill",
                                trend: -5
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
}
