//
//  FeatureBadge.swift
//  Verbio
//
//  Capsule badge for subscription labels
//

import SwiftUI

// MARK: - Feature Badge

struct FeatureBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let color: Color

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color ?? VerbioColors.Primary.amber500
    }

    var body: some View {
        Text(text)
            .font(VerbioTypography.Scaled.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, VerbioSpacing.sm)
            .padding(.vertical, VerbioSpacing.xxs)
            .background(
                Capsule()
                    .fill(color.gradient)
            )
    }
}

// MARK: - Preview

#Preview("Feature Badges") {
    VStack(spacing: 16) {
        FeatureBadge("Most Popular")
        FeatureBadge("Best Value", color: VerbioColors.Semantic.success)
        FeatureBadge("Save 33%", color: VerbioColors.Accent.warmOrange)
    }
    .padding()
}
