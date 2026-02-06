//
//  OnboardingView.swift
//  Verbio
//
//  Onboarding walkthrough with paywall integration
//

import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Warm gradient background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(viewModel.pages) { page in
                        pageView(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(VerbioAnimations.Spring.smooth, value: viewModel.currentPage)

                // Bottom buttons
                bottomButtons
                    .padding(.horizontal, VerbioSpacing.horizontalPadding)
                    .padding(.bottom, VerbioSpacing.xxl)
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .onChange(of: viewModel.showPaywall) { _, showing in
            if !showing {
                // Paywall was dismissed — complete onboarding regardless
                viewModel.completeOnboarding()
                onComplete()
            }
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            colors.backgrounds.primary

            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.12),
                    VerbioColors.Accent.warmOrange.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    VerbioColors.Primary.amber500.opacity(0.1),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: VerbioSpacing.xxl) {
            Spacer()

            // Icon with glow
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                VerbioColors.Primary.amber500.opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: page.icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [VerbioColors.Primary.amber400, VerbioColors.Accent.warmOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: VerbioColors.Primary.amber500.opacity(0.3), radius: 20, y: 8)
            }

            VStack(spacing: VerbioSpacing.md) {
                Text(page.title)
                    .verbioDisplayMedium()
                    .foregroundStyle(colors.text.primary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .verbioBodyLarge()
                    .foregroundStyle(colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VerbioSpacing.xl)
            }

            Spacer()
            Spacer()
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: VerbioSpacing.md) {
            if viewModel.isLastPage {
                // Last page — CTA to open paywall
                GlassButton(
                    "Start Free Trial",
                    icon: "sparkles",
                    style: .primary,
                    size: .large
                ) {
                    viewModel.showPaywall = true
                }

                Button {
                    viewModel.completeOnboarding()
                    onComplete()
                } label: {
                    Text("Continue without trial")
                        .verbioLabelMedium()
                        .foregroundStyle(colors.text.tertiary)
                }
                .buttonStyle(.plain)
            } else {
                // Next button
                GlassButton(
                    "Next",
                    style: .primary,
                    size: .large
                ) {
                    withAnimation {
                        viewModel.nextPage()
                    }
                }

                // Skip button
                Button {
                    withAnimation {
                        viewModel.skip()
                    }
                } label: {
                    Text("Skip")
                        .verbioLabelMedium()
                        .foregroundStyle(colors.text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView {
        print("Onboarding complete")
    }
}
