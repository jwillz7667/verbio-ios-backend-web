//
//  GlassButton.swift
//  Verbio
//
//  Liquid Glass styled button component
//

import SwiftUI

// MARK: - Glass Button Style

enum GlassButtonStyle {
    case primary    // Prominent amber tint
    case secondary  // Subtle glass
    case ghost      // No background
}

enum GlassButtonSize {
    case small
    case medium
    case large

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return VerbioSpacing.md
        case .medium: return VerbioSpacing.lg
        case .large: return VerbioSpacing.xl
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return VerbioSpacing.sm
        case .medium: return VerbioSpacing.md
        case .large: return VerbioSpacing.lg
        }
    }

    var font: Font {
        switch self {
        case .small: return VerbioTypography.Scaled.labelMedium
        case .medium: return VerbioTypography.Scaled.labelLarge
        case .large: return VerbioTypography.Scaled.headlineMedium
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 20
        }
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let icon: String?
    let style: GlassButtonStyle
    let size: GlassButtonSize
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        size: GlassButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: VerbioSpacing.buttonContentSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .frame(width: size.iconSize, height: size.iconSize)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background {
                buttonBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(VerbioAnimations.buttonPress, value: isPressed)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Computed Properties

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return colorScheme == .light ? colors.text.inverted : colors.text.primary
        case .secondary:
            return colors.brand.primary
        case .ghost:
            return colors.brand.primary
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return VerbioSpacing.CornerRadius.sm
        case .medium: return VerbioSpacing.CornerRadius.md
        case .large: return VerbioSpacing.CornerRadius.lg
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colors.brand.primary)
                    .glassEffect(.regular.tint(VerbioGlass.accentTint).interactive())
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colors.brand.primary)
            }

        case .secondary:
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .glassEffect(.regular.tint(VerbioGlass.warmTint).interactive())
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            }

        case .ghost:
            Color.clear
        }
    }
}

// MARK: - Sign in with Apple Button

struct AppleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void
    let isLoading: Bool

    @State private var isPressed = false

    init(isLoading: Bool = false, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: VerbioSpacing.buttonContentSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text("Sign in with Apple")
                    .font(VerbioTypography.Scaled.labelLarge)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VerbioSpacing.lg)
            .background {
                background
            }
            .clipShape(RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(VerbioAnimations.buttonPress, value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        colorScheme == .light ? .white : .black
    }

    private var backgroundColor: Color {
        colorScheme == .light ? .black : .white
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md)
                .fill(backgroundColor)
                .glassEffect(.regular.interactive())
        } else {
            RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md)
                .fill(backgroundColor)
        }
    }
}

// MARK: - Preview

#Preview("Glass Buttons - Light") {
    GlassButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Glass Buttons - Dark") {
    GlassButtonPreview()
        .preferredColorScheme(.dark)
}

private struct GlassButtonPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.3),
                    colors.backgrounds.primary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: VerbioSpacing.xxl) {
                    // Primary Buttons
                    VStack(spacing: VerbioSpacing.md) {
                        Text("Primary")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassButton("Start Translation", icon: "mic.fill", style: .primary, size: .large) {}

                        GlassButton("Continue", style: .primary, size: .medium) {}

                        GlassButton("Loading...", style: .primary, isLoading: true) {}
                    }

                    // Secondary Buttons
                    VStack(spacing: VerbioSpacing.md) {
                        Text("Secondary")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassButton("Settings", icon: "gear", style: .secondary) {}

                        GlassButton("View History", icon: "clock", style: .secondary, size: .small) {}
                    }

                    // Ghost Buttons
                    VStack(spacing: VerbioSpacing.md) {
                        Text("Ghost")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassButton("Cancel", style: .ghost) {}
                    }

                    // Apple Sign In
                    VStack(spacing: VerbioSpacing.md) {
                        Text("Apple Sign In")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        AppleSignInButton {}
                    }
                }
                .padding()
            }
        }
    }
}
