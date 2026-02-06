//
//  TierComparisonCard.swift
//  Verbio
//
//  Subscription tier comparison card for paywall
//

import SwiftUI

// MARK: - Tier Comparison Card

struct TierComparisonCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let tierName: String
    let price: String
    let period: String
    let features: [TierFeatures.Feature]
    let badge: String?
    let badgeColor: Color?
    let isSelected: Bool
    let action: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        tierName: String,
        price: String,
        period: String,
        features: [TierFeatures.Feature],
        badge: String? = nil,
        badgeColor: Color? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.tierName = tierName
        self.price = price
        self.period = period
        self.features = features
        self.badge = badge
        self.badgeColor = badgeColor
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        GlassCard(style: isSelected ? .elevated : .standard) {
            VStack(alignment: .leading, spacing: VerbioSpacing.md) {
                // Header with badge
                HStack {
                    Text(tierName)
                        .verbioHeadlineLarge()
                        .foregroundStyle(colors.text.primary)

                    Spacer()

                    if let badge = badge {
                        FeatureBadge(badge, color: badgeColor)
                    }
                }

                // Price
                HStack(alignment: .firstTextBaseline, spacing: VerbioSpacing.xxs) {
                    Text(price)
                        .verbioDisplayMedium()
                        .foregroundStyle(colors.brand.primary)

                    Text("/ \(period)")
                        .verbioBodySmall()
                        .foregroundStyle(colors.text.tertiary)
                }

                Divider()
                    .background(colors.text.tertiary.opacity(0.3))

                // Features
                VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                    ForEach(features) { feature in
                        HStack(spacing: VerbioSpacing.sm) {
                            Image(systemName: feature.included ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(feature.included ? VerbioColors.Semantic.success : colors.text.disabled)

                            Text(feature.name)
                                .verbioBodySmall()
                                .foregroundStyle(feature.included ? colors.text.primary : colors.text.disabled)
                        }
                    }
                }

                // Selection indicator
                if isSelected {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(colors.brand.primary)
                        Spacer()
                    }
                    .padding(.top, VerbioSpacing.xs)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.lg)
                .stroke(isSelected ? colors.brand.primary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview("Tier Card") {
    ZStack {
        Color.black.opacity(0.05).ignoresSafeArea()

        HStack(spacing: 12) {
            TierComparisonCard(
                tierName: "Pro",
                price: "$4.99",
                period: "month",
                features: TierFeatures.pro.features,
                badge: "Most Popular",
                isSelected: true
            ) {}

            TierComparisonCard(
                tierName: "Premium",
                price: "$9.99",
                period: "month",
                features: TierFeatures.premium.features,
                badge: "Best Value",
                badgeColor: VerbioColors.Semantic.success
            ) {}
        }
        .padding()
    }
}
