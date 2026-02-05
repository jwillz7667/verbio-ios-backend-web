//
//  Spacing.swift
//  Verbio
//
//  4pt grid spacing system
//

import SwiftUI

// MARK: - Verbio Spacing

enum VerbioSpacing {

    // MARK: - Base Unit

    /// Base spacing unit (4pt)
    static let unit: CGFloat = 4

    // MARK: - Fixed Spacing Values

    /// 2pt - Extra extra small
    static let xxs: CGFloat = 2

    /// 4pt - Extra small
    static let xs: CGFloat = 4

    /// 8pt - Small
    static let sm: CGFloat = 8

    /// 12pt - Medium small
    static let md: CGFloat = 12

    /// 16pt - Medium
    static let lg: CGFloat = 16

    /// 20pt - Medium large
    static let xl: CGFloat = 20

    /// 24pt - Large
    static let xxl: CGFloat = 24

    /// 32pt - Extra large
    static let xxxl: CGFloat = 32

    /// 40pt - Extra extra large
    static let xxxxl: CGFloat = 40

    /// 48pt - Jumbo
    static let jumbo: CGFloat = 48

    /// 64pt - Mega
    static let mega: CGFloat = 64

    // MARK: - Computed Spacing

    /// Returns spacing as a multiple of the base unit (4pt)
    static func grid(_ multiplier: CGFloat) -> CGFloat {
        unit * multiplier
    }

    // MARK: - Content Insets

    /// Standard horizontal padding for content
    static let horizontalPadding: CGFloat = 16

    /// Standard vertical padding for content
    static let verticalPadding: CGFloat = 16

    /// Screen edge insets
    static let screenInsets = EdgeInsets(
        top: 16,
        leading: 16,
        bottom: 16,
        trailing: 16
    )

    /// Card content insets
    static let cardInsets = EdgeInsets(
        top: 16,
        leading: 16,
        bottom: 16,
        trailing: 16
    )

    /// Compact card insets
    static let cardInsetsCompact = EdgeInsets(
        top: 12,
        leading: 12,
        bottom: 12,
        trailing: 12
    )

    // MARK: - Component Spacing

    /// Space between list items
    static let listItemSpacing: CGFloat = 12

    /// Space between sections
    static let sectionSpacing: CGFloat = 24

    /// Space between icon and label
    static let iconLabelSpacing: CGFloat = 8

    /// Space in button content (icon + text)
    static let buttonContentSpacing: CGFloat = 8

    // MARK: - Corner Radii

    enum CornerRadius {
        /// 4pt - Small elements
        static let xs: CGFloat = 4

        /// 8pt - Buttons, small cards
        static let sm: CGFloat = 8

        /// 12pt - Medium cards
        static let md: CGFloat = 12

        /// 16pt - Large cards
        static let lg: CGFloat = 16

        /// 20pt - Extra large cards
        static let xl: CGFloat = 20

        /// 24pt - Modal sheets
        static let xxl: CGFloat = 24

        /// Full circle
        static let full: CGFloat = 9999
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard screen edge padding
    func verbioScreenPadding() -> some View {
        padding(VerbioSpacing.screenInsets)
    }

    /// Apply card content padding
    func verbioCardPadding() -> some View {
        padding(VerbioSpacing.cardInsets)
    }

    /// Apply compact card padding
    func verbioCardPaddingCompact() -> some View {
        padding(VerbioSpacing.cardInsetsCompact)
    }

    /// Apply horizontal content padding
    func verbioHorizontalPadding() -> some View {
        padding(.horizontal, VerbioSpacing.horizontalPadding)
    }

    /// Apply vertical content padding
    func verbioVerticalPadding() -> some View {
        padding(.vertical, VerbioSpacing.verticalPadding)
    }
}

// MARK: - EdgeInsets Extensions

extension EdgeInsets {
    /// Create uniform edge insets
    init(all value: CGFloat) {
        self.init(top: value, leading: value, bottom: value, trailing: value)
    }

    /// Create horizontal edge insets
    init(horizontal: CGFloat) {
        self.init(top: 0, leading: horizontal, bottom: 0, trailing: horizontal)
    }

    /// Create vertical edge insets
    init(vertical: CGFloat) {
        self.init(top: vertical, leading: 0, bottom: vertical, trailing: 0)
    }

    /// Create symmetric edge insets
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}

// MARK: - Preview

#Preview("Spacing Scale") {
    SpacingPreview()
}

private struct SpacingPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VerbioSpacing.lg) {
                Text("Spacing Scale (4pt Grid)")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                    SpacingRow(name: "xxs", value: VerbioSpacing.xxs)
                    SpacingRow(name: "xs", value: VerbioSpacing.xs)
                    SpacingRow(name: "sm", value: VerbioSpacing.sm)
                    SpacingRow(name: "md", value: VerbioSpacing.md)
                    SpacingRow(name: "lg", value: VerbioSpacing.lg)
                    SpacingRow(name: "xl", value: VerbioSpacing.xl)
                    SpacingRow(name: "xxl", value: VerbioSpacing.xxl)
                    SpacingRow(name: "xxxl", value: VerbioSpacing.xxxl)
                    SpacingRow(name: "xxxxl", value: VerbioSpacing.xxxxl)
                    SpacingRow(name: "jumbo", value: VerbioSpacing.jumbo)
                }

                Divider()

                Text("Corner Radii")
                    .font(.headline)

                HStack(spacing: VerbioSpacing.md) {
                    RadiusPreview(name: "xs", radius: VerbioSpacing.CornerRadius.xs)
                    RadiusPreview(name: "sm", radius: VerbioSpacing.CornerRadius.sm)
                    RadiusPreview(name: "md", radius: VerbioSpacing.CornerRadius.md)
                    RadiusPreview(name: "lg", radius: VerbioSpacing.CornerRadius.lg)
                    RadiusPreview(name: "xl", radius: VerbioSpacing.CornerRadius.xl)
                }
            }
            .padding()
        }
    }
}

private struct SpacingRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            Text("\(Int(value))pt")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            Rectangle()
                .fill(Color.orange)
                .frame(width: value, height: 16)
        }
    }
}

private struct RadiusPreview: View {
    let name: String
    let radius: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.orange.opacity(0.3))
                .stroke(Color.orange, lineWidth: 1)
                .frame(width: 44, height: 44)

            Text(name)
                .font(.caption2)
        }
    }
}
