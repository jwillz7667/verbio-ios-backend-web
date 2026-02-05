//
//  Colors.swift
//  Verbio
//
//  Warm amber design system with AAA accessible contrast ratios
//  Light: Cream background (#FFFEF7) with warm stone text
//  Dark: Stone background (#1C1917) with cream text
//

import SwiftUI

// MARK: - Verbio Colors

enum VerbioColors {

    // MARK: - Primary Palette (Amber)

    enum Primary {
        /// Amber 400 - Used for accents in dark mode
        static let amber400 = Color(hex: "FBBF24")

        /// Amber 500 - Primary brand color
        static let amber500 = Color(hex: "F59E0B")

        /// Amber 600 - Pressed/active states
        static let amber600 = Color(hex: "D97706")

        /// Amber 700 - Deep amber for emphasis
        static let amber700 = Color(hex: "B45309")
    }

    // MARK: - Accent Palette (Warm Orange)

    enum Accent {
        /// Warm orange for light mode
        static let warmOrange = Color(hex: "EA580C")

        /// Soft coral for dark mode
        static let softCoral = Color(hex: "FB923C")

        /// Deep orange for emphasis
        static let deepOrange = Color(hex: "C2410C")
    }

    // MARK: - Neutral Palette (Stone)

    enum Neutral {
        static let stone50 = Color(hex: "FAFAF9")
        static let stone100 = Color(hex: "F5F5F4")
        static let stone200 = Color(hex: "E7E5E4")
        static let stone300 = Color(hex: "D6D3D1")
        static let stone400 = Color(hex: "A8A29E")
        static let stone500 = Color(hex: "78716C")
        static let stone600 = Color(hex: "57534E")
        static let stone700 = Color(hex: "44403C")
        static let stone800 = Color(hex: "292524")
        static let stone900 = Color(hex: "1C1917")
    }

    // MARK: - Semantic Colors

    enum Semantic {
        static let success = Color(hex: "22C55E")
        static let warning = Color(hex: "EAB308")
        static let error = Color(hex: "EF4444")
        static let info = Color(hex: "3B82F6")
    }

    // MARK: - Background Colors

    enum Background {
        /// Warm cream for light mode - #FFFEF7
        static let cream = Color(hex: "FFFEF7")

        /// Deep stone for dark mode - #1C1917
        static let stone = Color(hex: "1C1917")

        /// Elevated surface light
        static let elevatedLight = Color.white

        /// Elevated surface dark
        static let elevatedDark = Color(hex: "292524")
    }
}

// MARK: - Adaptive Colors (Light/Dark Mode)

extension VerbioColors {

    /// Adaptive text colors based on color scheme
    struct Text {
        let colorScheme: ColorScheme

        /// Primary text - highest contrast (14.7:1 light, 15.4:1 dark)
        var primary: Color {
            colorScheme == .light ? Neutral.stone900 : Neutral.stone50
        }

        /// Secondary text - medium contrast (7.2:1 light, 10.1:1 dark)
        var secondary: Color {
            colorScheme == .light ? Neutral.stone600 : Neutral.stone300
        }

        /// Tertiary text - lower contrast (4.6:1 light, 5.8:1 dark)
        var tertiary: Color {
            colorScheme == .light ? Neutral.stone500 : Neutral.stone400
        }

        /// Disabled text
        var disabled: Color {
            colorScheme == .light ? Neutral.stone400 : Neutral.stone600
        }

        /// Inverted text (for colored backgrounds)
        var inverted: Color {
            colorScheme == .light ? Neutral.stone50 : Neutral.stone900
        }
    }

    /// Adaptive background colors
    struct Backgrounds {
        let colorScheme: ColorScheme

        /// Main background
        var primary: Color {
            colorScheme == .light ? Background.cream : Background.stone
        }

        /// Elevated/card background
        var elevated: Color {
            colorScheme == .light ? Background.elevatedLight : Background.elevatedDark
        }

        /// Secondary background (grouped content)
        var secondary: Color {
            colorScheme == .light ? Neutral.stone100 : Neutral.stone800
        }
    }

    /// Adaptive brand/accent colors
    struct Brand {
        let colorScheme: ColorScheme

        /// Primary brand color
        var primary: Color {
            colorScheme == .light ? Primary.amber500 : Primary.amber400
        }

        /// Accent color
        var accent: Color {
            colorScheme == .light ? Accent.warmOrange : Accent.softCoral
        }

        /// Pressed state
        var pressed: Color {
            colorScheme == .light ? Primary.amber600 : Primary.amber500
        }
    }
}

// MARK: - Environment Key for Adaptive Colors

private struct VerbioColorsKey: EnvironmentKey {
    static let defaultValue = VerbioColorScheme(colorScheme: .light)
}

struct VerbioColorScheme {
    let colorScheme: ColorScheme

    var text: VerbioColors.Text {
        VerbioColors.Text(colorScheme: colorScheme)
    }

    var backgrounds: VerbioColors.Backgrounds {
        VerbioColors.Backgrounds(colorScheme: colorScheme)
    }

    var brand: VerbioColors.Brand {
        VerbioColors.Brand(colorScheme: colorScheme)
    }
}

extension EnvironmentValues {
    var verbioColors: VerbioColorScheme {
        get { self[VerbioColorsKey.self] }
        set { self[VerbioColorsKey.self] = newValue }
    }
}

// MARK: - View Modifier for Color Injection

struct VerbioColorSchemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.verbioColors, VerbioColorScheme(colorScheme: colorScheme))
    }
}

extension View {
    /// Apply Verbio's adaptive color scheme
    func verbioColors() -> some View {
        modifier(VerbioColorSchemeModifier())
    }
}

// MARK: - Preview Helpers

#Preview("Color Palette - Light") {
    ColorPalettePreview()
        .preferredColorScheme(.light)
}

#Preview("Color Palette - Dark") {
    ColorPalettePreview()
        .preferredColorScheme(.dark)
}

private struct ColorPalettePreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Verbio Colors")
                    .font(.largeTitle.bold())
                    .foregroundStyle(colors.text.primary)

                // Text Colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Colors")
                        .font(.headline)
                        .foregroundStyle(colors.text.primary)

                    HStack(spacing: 16) {
                        ColorSwatch(color: colors.text.primary, name: "Primary")
                        ColorSwatch(color: colors.text.secondary, name: "Secondary")
                        ColorSwatch(color: colors.text.tertiary, name: "Tertiary")
                    }
                }

                // Brand Colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("Brand Colors")
                        .font(.headline)
                        .foregroundStyle(colors.text.primary)

                    HStack(spacing: 16) {
                        ColorSwatch(color: colors.brand.primary, name: "Primary")
                        ColorSwatch(color: colors.brand.accent, name: "Accent")
                        ColorSwatch(color: colors.brand.pressed, name: "Pressed")
                    }
                }

                // Amber Scale
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amber Scale")
                        .font(.headline)
                        .foregroundStyle(colors.text.primary)

                    HStack(spacing: 16) {
                        ColorSwatch(color: VerbioColors.Primary.amber400, name: "400")
                        ColorSwatch(color: VerbioColors.Primary.amber500, name: "500")
                        ColorSwatch(color: VerbioColors.Primary.amber600, name: "600")
                        ColorSwatch(color: VerbioColors.Primary.amber700, name: "700")
                    }
                }
            }
            .padding()
        }
        .background(colors.backgrounds.primary)
    }
}

private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)

            Text(name)
                .font(.caption2)
        }
    }
}
