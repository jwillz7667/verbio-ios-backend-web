//
//  Typography.swift
//  Verbio
//
//  SF Pro type scale with dynamic type support
//

import SwiftUI

// MARK: - Verbio Typography

enum VerbioTypography {

    // MARK: - Display Styles

    /// Large display text - 34pt Bold
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)

    /// Medium display text - 28pt Bold
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)

    /// Small display text - 22pt Bold
    static let displaySmall = Font.system(size: 22, weight: .bold, design: .default)

    // MARK: - Headline Styles

    /// Large headline - 20pt Semibold
    static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .default)

    /// Medium headline - 17pt Semibold
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .default)

    /// Small headline - 15pt Semibold
    static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: - Body Styles

    /// Large body text - 17pt Regular
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Medium body text - 15pt Regular
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// Small body text - 13pt Regular
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Label Styles

    /// Large label - 15pt Medium
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)

    /// Medium label - 13pt Medium
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)

    /// Small label - 11pt Medium
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Caption Styles

    /// Caption - 12pt Regular
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption 2 - 11pt Regular
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Monospaced (for numbers/codes)

    /// Monospaced body
    static let monoBody = Font.system(size: 15, weight: .regular, design: .monospaced)

    /// Monospaced small
    static let monoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Dynamic Type Aware Typography

extension VerbioTypography {

    /// Returns fonts that scale with Dynamic Type
    struct Scaled {
        /// Display Large - scales from .title to .largeTitle
        static var displayLarge: Font {
            .largeTitle.weight(.bold)
        }

        /// Display Medium - scales with .title
        static var displayMedium: Font {
            .title.weight(.bold)
        }

        /// Display Small - scales with .title2
        static var displaySmall: Font {
            .title2.weight(.bold)
        }

        /// Headline Large - scales with .title3
        static var headlineLarge: Font {
            .title3.weight(.semibold)
        }

        /// Headline Medium - scales with .headline
        static var headlineMedium: Font {
            .headline
        }

        /// Headline Small - scales with .subheadline weight semibold
        static var headlineSmall: Font {
            .subheadline.weight(.semibold)
        }

        /// Body Large - scales with .body
        static var bodyLarge: Font {
            .body
        }

        /// Body Medium - scales with .callout
        static var bodyMedium: Font {
            .callout
        }

        /// Body Small - scales with .footnote
        static var bodySmall: Font {
            .footnote
        }

        /// Label Large - scales with .callout weight medium
        static var labelLarge: Font {
            .callout.weight(.medium)
        }

        /// Label Medium - scales with .footnote weight medium
        static var labelMedium: Font {
            .footnote.weight(.medium)
        }

        /// Label Small - scales with .caption weight medium
        static var labelSmall: Font {
            .caption.weight(.medium)
        }

        /// Caption - scales with .caption
        static var caption: Font {
            .caption
        }

        /// Caption 2 - scales with .caption2
        static var caption2: Font {
            .caption2
        }
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply display large style
    func verbioDisplayLarge() -> some View {
        font(VerbioTypography.Scaled.displayLarge)
    }

    /// Apply display medium style
    func verbioDisplayMedium() -> some View {
        font(VerbioTypography.Scaled.displayMedium)
    }

    /// Apply display small style
    func verbioDisplaySmall() -> some View {
        font(VerbioTypography.Scaled.displaySmall)
    }

    /// Apply headline large style
    func verbioHeadlineLarge() -> some View {
        font(VerbioTypography.Scaled.headlineLarge)
    }

    /// Apply headline medium style
    func verbioHeadlineMedium() -> some View {
        font(VerbioTypography.Scaled.headlineMedium)
    }

    /// Apply headline small style
    func verbioHeadlineSmall() -> some View {
        font(VerbioTypography.Scaled.headlineSmall)
    }

    /// Apply body large style
    func verbioBodyLarge() -> some View {
        font(VerbioTypography.Scaled.bodyLarge)
    }

    /// Apply body medium style
    func verbioBodyMedium() -> some View {
        font(VerbioTypography.Scaled.bodyMedium)
    }

    /// Apply body small style
    func verbioBodySmall() -> some View {
        font(VerbioTypography.Scaled.bodySmall)
    }

    /// Apply label large style
    func verbioLabelLarge() -> some View {
        font(VerbioTypography.Scaled.labelLarge)
    }

    /// Apply label medium style
    func verbioLabelMedium() -> some View {
        font(VerbioTypography.Scaled.labelMedium)
    }

    /// Apply label small style
    func verbioLabelSmall() -> some View {
        font(VerbioTypography.Scaled.labelSmall)
    }

    /// Apply caption style
    func verbioCaption() -> some View {
        font(VerbioTypography.Scaled.caption)
    }
}

// MARK: - Preview

#Preview("Typography Scale") {
    TypographyPreview()
}

private struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Display Large")
                        .verbioDisplayLarge()

                    Text("Display Medium")
                        .verbioDisplayMedium()

                    Text("Display Small")
                        .verbioDisplaySmall()
                }

                Divider()

                Group {
                    Text("Headline Large")
                        .verbioHeadlineLarge()

                    Text("Headline Medium")
                        .verbioHeadlineMedium()

                    Text("Headline Small")
                        .verbioHeadlineSmall()
                }

                Divider()

                Group {
                    Text("Body Large - The quick brown fox jumps over the lazy dog.")
                        .verbioBodyLarge()

                    Text("Body Medium - The quick brown fox jumps over the lazy dog.")
                        .verbioBodyMedium()

                    Text("Body Small - The quick brown fox jumps over the lazy dog.")
                        .verbioBodySmall()
                }

                Divider()

                Group {
                    Text("Label Large")
                        .verbioLabelLarge()

                    Text("Label Medium")
                        .verbioLabelMedium()

                    Text("Label Small")
                        .verbioLabelSmall()
                }

                Divider()

                Group {
                    Text("Caption text for supplementary information")
                        .verbioCaption()
                }
            }
            .padding()
        }
    }
}
