//
//  SubscriptionManagementView.swift
//  Verbio
//
//  Subscription management screen in Settings
//

import SwiftUI

// MARK: - Subscription Management View

struct SubscriptionManagementView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = SubscriptionManagementViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background
            colors.backgrounds.primary
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: VerbioSpacing.xxl) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(colors.brand.primary)
                            .padding(.top, VerbioSpacing.jumbo)
                    } else {
                        // Current Plan
                        currentPlanSection

                        // Actions
                        actionsSection
                    }
                }
                .padding(.horizontal, VerbioSpacing.horizontalPadding)
                .padding(.top, VerbioSpacing.md)
                .padding(.bottom, VerbioSpacing.jumbo)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSubscription()
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .onChange(of: viewModel.showPaywall) { _, showing in
            if !showing {
                Task { await viewModel.loadSubscription() }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Subviews

    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Current Plan")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard(style: .elevated) {
                HStack(spacing: VerbioSpacing.lg) {
                    // Tier icon
                    ZStack {
                        Circle()
                            .fill(colors.brand.primary.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: viewModel.tierIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(colors.brand.primary)
                    }

                    VStack(alignment: .leading, spacing: VerbioSpacing.xxs) {
                        HStack(spacing: VerbioSpacing.sm) {
                            Text(viewModel.currentTier.displayName)
                                .verbioHeadlineMedium()
                                .foregroundStyle(colors.text.primary)

                            if viewModel.activeSubscription?.isInTrial == true {
                                FeatureBadge("Trial", color: VerbioColors.Semantic.success)
                            }
                        }

                        Text(viewModel.statusText)
                            .verbioCaption()
                            .foregroundStyle(colors.text.secondary)

                        if viewModel.isSubscribed, let sub = viewModel.activeSubscription {
                            Text(sub.period.displayName)
                                .verbioCaption()
                                .foregroundStyle(colors.text.tertiary)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Actions")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard {
                VStack(spacing: VerbioSpacing.lg) {
                    if viewModel.isSubscribed {
                        // Manage subscription
                        Button {
                            Task { await viewModel.manageSubscription() }
                        } label: {
                            HStack(spacing: VerbioSpacing.md) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(colors.brand.primary)
                                    .frame(width: 28)

                                Text("Manage Subscription")
                                    .verbioBodyMedium()
                                    .foregroundStyle(colors.text.primary)

                                Spacer()

                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 12))
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.currentTier != .premium {
                        if viewModel.isSubscribed {
                            Divider()
                                .background(colors.text.tertiary.opacity(0.3))
                        }

                        // Upgrade plan
                        Button {
                            viewModel.showPaywall = true
                        } label: {
                            HStack(spacing: VerbioSpacing.md) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(colors.brand.primary)
                                    .frame(width: 28)

                                Text(viewModel.isSubscribed ? "Upgrade Plan" : "Subscribe")
                                    .verbioBodyMedium()
                                    .foregroundStyle(colors.text.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Subscription Management") {
    NavigationStack {
        SubscriptionManagementView()
    }
}
