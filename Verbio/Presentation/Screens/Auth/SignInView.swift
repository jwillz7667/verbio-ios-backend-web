//
//  SignInView.swift
//  Verbio
//
//  Sign In screen with Liquid Glass UI
//

import SwiftUI

// MARK: - Sign In View

struct SignInView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = SignInViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                // Content
                VStack(spacing: 0) {
                    Spacer()

                    // Logo and branding
                    brandingSection

                    Spacer()

                    // Sign in section
                    signInSection
                        .padding(.horizontal, VerbioSpacing.horizontalPadding)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + VerbioSpacing.xxl)
                }
            }
        }
        .task {
            await viewModel.checkExistingAuth()
        }
        .alert("Sign In Error", isPresented: showingError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            // Base background
            colors.backgrounds.primary

            // Warm gradient overlay
            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.15),
                    VerbioColors.Accent.warmOrange.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated orbs (subtle)
            Circle()
                .fill(VerbioColors.Primary.amber500.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -100, y: -200)

            Circle()
                .fill(VerbioColors.Accent.warmOrange.opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 150, y: 100)
        }
    }

    private var brandingSection: some View {
        VStack(spacing: VerbioSpacing.lg) {
            // App icon/logo placeholder
            ZStack {
                Circle()
                    .fill(colors.brand.primary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(colors.brand.primary)
            }

            VStack(spacing: VerbioSpacing.sm) {
                Text("Verbio")
                    .verbioDisplayLarge()
                    .foregroundStyle(colors.text.primary)

                Text("Real-time voice translation")
                    .verbioBodyLarge()
                    .foregroundStyle(colors.text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, VerbioSpacing.xxl)
    }

    private var signInSection: some View {
        VStack(spacing: VerbioSpacing.lg) {
            // Feature highlights
            GlassCard {
                VStack(spacing: VerbioSpacing.md) {
                    FeatureRow(
                        icon: "globe",
                        title: "50+ Languages",
                        subtitle: "Translate conversations instantly"
                    )

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    FeatureRow(
                        icon: "waveform",
                        title: "Natural Voices",
                        subtitle: "Powered by ElevenLabs AI"
                    )

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Private & Secure",
                        subtitle: "Your conversations stay yours"
                    )
                }
            }

            // Sign in button
            AppleSignInButton(isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.signInWithApple()
                }
            }

            // Terms text
            Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                .verbioCaption()
                .foregroundStyle(colors.text.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VerbioSpacing.md)
        }
    }

    // MARK: - Computed Properties

    private var showingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let subtitle: String

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: VerbioSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(colors.brand.primary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: VerbioSpacing.xxs) {
                Text(title)
                    .verbioLabelLarge()
                    .foregroundStyle(colors.text.primary)

                Text(subtitle)
                    .verbioCaption()
                    .foregroundStyle(colors.text.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Sign In - Light") {
    SignInView()
        .preferredColorScheme(.light)
}

#Preview("Sign In - Dark") {
    SignInView()
        .preferredColorScheme(.dark)
}
