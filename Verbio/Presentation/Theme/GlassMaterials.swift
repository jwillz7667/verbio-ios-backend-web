//
//  GlassMaterials.swift
//  Verbio
//
//  iOS 26 Liquid Glass design system with warm amber tint
//

import SwiftUI

// MARK: - Glass Material Configuration

enum VerbioGlass {

    // MARK: - Glass Tints

    /// Warm amber tint for glass materials
    static var amberTint: Color {
        VerbioColors.Primary.amber500.opacity(0.1)
    }

    /// Subtle warm tint
    static var warmTint: Color {
        VerbioColors.Primary.amber400.opacity(0.05)
    }

    /// Accent tint for interactive elements
    static var accentTint: Color {
        VerbioColors.Accent.warmOrange.opacity(0.15)
    }
}

// MARK: - Glass Effect View Modifiers

extension View {
    /// Apply navigation glass effect with warm amber tint
    @ViewBuilder
    func verbioNavigationGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(VerbioGlass.amberTint))
        } else {
            self.background(.ultraThinMaterial)
        }
    }

    /// Apply card glass effect
    @ViewBuilder
    func verbioCardGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(VerbioGlass.warmTint))
        } else {
            self.background(.thinMaterial)
        }
    }

    /// Apply interactive button glass effect
    @ViewBuilder
    func verbioButtonGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(VerbioGlass.amberTint).interactive())
        } else {
            self.background(.regularMaterial)
        }
    }

    /// Apply prominent glass effect (for primary actions)
    @ViewBuilder
    func verbioProminentGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(VerbioGlass.accentTint).interactive())
        } else {
            self.background(.thickMaterial)
        }
    }

    /// Apply subtle glass effect (for secondary elements)
    @ViewBuilder
    func verbioSubtleGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(VerbioGlass.warmTint))
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}

// MARK: - Glass Container Views

/// A container that groups glass elements for coordinated transitions
/// Note: In iOS 26+, glass elements automatically coordinate when in the same container
struct GlassEffectContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

/// A glass-styled card container
struct GlassCardContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let content: Content

    init(
        cornerRadius: CGFloat = VerbioSpacing.CornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .verbioCardPadding()
            .background {
                glassBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .glassEffect(.regular.tint(VerbioGlass.warmTint))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
        }
    }
}

/// A glass-styled button container
struct GlassButtonContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let isPressed: Bool
    let content: Content

    init(
        cornerRadius: CGFloat = VerbioSpacing.CornerRadius.md,
        isPressed: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isPressed = isPressed
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, VerbioSpacing.lg)
            .padding(.vertical, VerbioSpacing.md)
            .background {
                glassBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(VerbioAnimations.buttonPress, value: isPressed)
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .glassEffect(.regular.tint(VerbioGlass.amberTint).interactive())
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)
        }
    }
}

// MARK: - Glass Navigation Bar Modifier

struct GlassNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
    }
}

extension View {
    /// Apply glass effect to navigation bar
    func verbioGlassNavigationBar() -> some View {
        modifier(GlassNavigationBarModifier())
    }
}

// MARK: - Preview

#Preview("Glass Materials - Light") {
    GlassMaterialsPreview()
        .preferredColorScheme(.light)
}

#Preview("Glass Materials - Dark") {
    GlassMaterialsPreview()
        .preferredColorScheme(.dark)
}

private struct GlassMaterialsPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background gradient
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
                VStack(spacing: VerbioSpacing.xxl) {
                    Text("Glass Materials")
                        .verbioDisplayMedium()
                        .foregroundStyle(colors.text.primary)

                    // Navigation Glass
                    VStack(spacing: VerbioSpacing.sm) {
                        Text("Navigation Glass")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        HStack {
                            Image(systemName: "arrow.left")
                            Spacer()
                            Text("Title")
                                .verbioHeadlineMedium()
                            Spacer()
                            Image(systemName: "ellipsis")
                        }
                        .padding()
                        .verbioNavigationGlass()
                        .clipShape(RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md))
                    }

                    // Card Glass
                    VStack(spacing: VerbioSpacing.sm) {
                        Text("Card Glass")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassCardContainer {
                            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                                Text("Glass Card")
                                    .verbioHeadlineMedium()
                                    .foregroundStyle(colors.text.primary)

                                Text("This is a glass card with warm amber tint. It adapts to light and dark mode.")
                                    .verbioBodyMedium()
                                    .foregroundStyle(colors.text.secondary)
                            }
                        }
                    }

                    // Button Glass
                    VStack(spacing: VerbioSpacing.sm) {
                        Text("Button Glass")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        GlassButtonContainer(isPressed: isPressed) {
                            HStack(spacing: VerbioSpacing.buttonContentSpacing) {
                                Image(systemName: "mic.fill")
                                Text("Start Recording")
                                    .verbioLabelLarge()
                            }
                            .foregroundStyle(colors.brand.primary)
                        }
                        .onTapGesture {
                            isPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isPressed = false
                            }
                        }
                    }

                    // Prominent Glass
                    VStack(spacing: VerbioSpacing.sm) {
                        Text("Prominent Glass")
                            .verbioHeadlineSmall()
                            .foregroundStyle(colors.text.secondary)

                        HStack {
                            Image(systemName: "waveform")
                                .font(.title)

                            VStack(alignment: .leading) {
                                Text("Translating...")
                                    .verbioLabelLarge()
                                Text("English to Spanish")
                                    .verbioCaption()
                                    .foregroundStyle(colors.text.tertiary)
                            }

                            Spacer()

                            ProgressView()
                        }
                        .padding()
                        .verbioProminentGlass()
                        .clipShape(RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.lg))
                    }
                }
                .padding()
            }
        }
    }
}
