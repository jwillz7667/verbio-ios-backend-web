//
//  PaywallView.swift
//  Verbio
//
//  Subscription paywall with tier comparison
//

import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PaywallViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VerbioSpacing.xl) {
                        // Header
                        headerSection

                        // Period Toggle
                        periodToggle

                        // Tier Cards
                        tierCardsSection

                        // Trial callout
                        if viewModel.selectedPeriod == .yearly {
                            trialCallout
                        }

                        // CTA Button
                        ctaSection

                        // Restore + Legal
                        footerSection
                    }
                    .padding(.horizontal, VerbioSpacing.horizontalPadding)
                    .padding(.top, VerbioSpacing.md)
                    .padding(.bottom, VerbioSpacing.jumbo)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.text.tertiary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .alert("Notice", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.purchaseComplete) { _, complete in
            if complete { dismiss() }
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            colors.backgrounds.primary

            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.1),
                    VerbioColors.Accent.warmOrange.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    VerbioColors.Primary.amber500.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: VerbioSpacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [VerbioColors.Primary.amber400, VerbioColors.Accent.warmOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: VerbioColors.Primary.amber500.opacity(0.4), radius: 12, y: 4)

            Text("Choose Your Plan")
                .verbioDisplayMedium()
                .foregroundStyle(colors.text.primary)

            Text("Unlock the full power of Verbio")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.secondary)
        }
        .padding(.top, VerbioSpacing.md)
    }

    private var periodToggle: some View {
        GlassCard(style: .subtle) {
            HStack(spacing: 0) {
                periodButton(.monthly, label: "Monthly")
                periodButton(.yearly, label: "Yearly")
            }
        }
    }

    private func periodButton(_ period: SubscriptionPeriod, label: String) -> some View {
        Button {
            withAnimation(VerbioAnimations.Spring.smooth) {
                viewModel.selectedPeriod = period
            }
        } label: {
            HStack(spacing: VerbioSpacing.xs) {
                Text(label)
                    .verbioLabelMedium()

                if period == .yearly, let savings = viewModel.yearlySavingsText {
                    FeatureBadge(savings, color: VerbioColors.Semantic.success)
                }
            }
            .foregroundStyle(viewModel.selectedPeriod == period ? colors.text.inverted : colors.text.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VerbioSpacing.sm)
            .background(
                viewModel.selectedPeriod == period
                    ? AnyShapeStyle(colors.brand.primary)
                    : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.sm)
            )
        }
        .buttonStyle(.plain)
    }

    private var tierCardsSection: some View {
        HStack(alignment: .top, spacing: VerbioSpacing.md) {
            TierComparisonCard(
                tierName: "Pro",
                price: viewModel.proProduct?.displayPrice ?? "$4.99",
                period: viewModel.selectedPeriod == .monthly ? "month" : "year",
                features: TierFeatures.pro.features,
                badge: "Most Popular",
                isSelected: viewModel.selectedTier == .pro
            ) {
                withAnimation(VerbioAnimations.Spring.smooth) {
                    viewModel.selectedTier = .pro
                }
            }

            TierComparisonCard(
                tierName: "Premium",
                price: viewModel.premiumProduct?.displayPrice ?? "$9.99",
                period: viewModel.selectedPeriod == .monthly ? "month" : "year",
                features: TierFeatures.premium.features,
                badge: "Best Value",
                badgeColor: VerbioColors.Semantic.success,
                isSelected: viewModel.selectedTier == .premium
            ) {
                withAnimation(VerbioAnimations.Spring.smooth) {
                    viewModel.selectedTier = .premium
                }
            }
        }
    }

    private var trialCallout: some View {
        HStack(spacing: VerbioSpacing.sm) {
            Image(systemName: "gift.fill")
                .foregroundStyle(colors.brand.primary)

            Text("7-day free trial included with yearly plans")
                .verbioBodySmall()
                .foregroundStyle(colors.text.secondary)
        }
        .padding(.vertical, VerbioSpacing.sm)
        .padding(.horizontal, VerbioSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md)
                .fill(colors.brand.primary.opacity(0.1))
        )
    }

    private var ctaSection: some View {
        VStack(spacing: VerbioSpacing.md) {
            let isPurchasing: Bool = {
                if case .purchasing = viewModel.state { return true }
                return false
            }()

            GlassButton(
                viewModel.ctaText,
                icon: "sparkles",
                style: .primary,
                size: .large,
                isLoading: isPurchasing
            ) {
                Task { await viewModel.purchase() }
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: VerbioSpacing.md) {
            // Restore purchases
            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .verbioLabelMedium()
                    .foregroundStyle(colors.text.secondary)
            }
            .buttonStyle(.plain)

            // Legal
            VStack(spacing: VerbioSpacing.xxs) {
                Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
            }
            .verbioCaption()
            .foregroundStyle(colors.text.disabled)
            .multilineTextAlignment(.center)
            .padding(.horizontal, VerbioSpacing.lg)

            HStack(spacing: VerbioSpacing.lg) {
                Link("Terms of Use", destination: URL(string: "https://verbio.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://verbio.app/privacy")!)
            }
            .verbioCaption()
            .foregroundStyle(colors.text.tertiary)
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView()
}
