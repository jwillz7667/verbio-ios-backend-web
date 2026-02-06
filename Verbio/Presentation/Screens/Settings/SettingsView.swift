//
//  SettingsView.swift
//  Verbio
//
//  Settings screen with preferences management
//

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthState.self) private var authState

    @State private var viewModel = SettingsViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.backgrounds.primary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VerbioSpacing.xxl) {
                        // Profile Section
                        profileSection

                        // Language Preferences
                        languageSection

                        // Voice Preferences
                        voiceSection

                        // General Settings
                        generalSection

                        // Account Section
                        accountSection

                        // App Info
                        appInfoSection
                    }
                    .padding(.horizontal, VerbioSpacing.horizontalPadding)
                    .padding(.top, VerbioSpacing.md)
                    .padding(.bottom, VerbioSpacing.jumbo)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSettings()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $viewModel.showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authState.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Profile")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard(style: .elevated) {
                HStack(spacing: VerbioSpacing.lg) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(colors.brand.primary.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Text(viewModel.userInitials)
                            .verbioHeadlineLarge()
                            .foregroundStyle(colors.brand.primary)
                    }

                    VStack(alignment: .leading, spacing: VerbioSpacing.xxs) {
                        Text(viewModel.displayName)
                            .verbioHeadlineMedium()
                            .foregroundStyle(colors.text.primary)

                        Text(viewModel.email)
                            .verbioCaption()
                            .foregroundStyle(colors.text.tertiary)

                        HStack(spacing: VerbioSpacing.xs) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(colors.brand.primary)

                            Text(viewModel.tierDisplayName)
                                .verbioLabelSmall()
                                .foregroundStyle(colors.text.secondary)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Languages")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard {
                VStack(spacing: VerbioSpacing.lg) {
                    settingsRow(
                        icon: "globe",
                        title: "Source Language",
                        value: viewModel.sourceLanguage.displayName
                    ) {
                        Menu {
                            ForEach(Language.allCases) { lang in
                                Button(lang.displayName) {
                                    viewModel.sourceLanguage = lang
                                    Task { await viewModel.savePreferences() }
                                }
                            }
                        } label: {
                            HStack(spacing: VerbioSpacing.xs) {
                                Text(viewModel.sourceLanguage.flag)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }
                    }

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    settingsRow(
                        icon: "globe",
                        title: "Target Language",
                        value: viewModel.targetLanguage.displayName
                    ) {
                        Menu {
                            ForEach(Language.allCases) { lang in
                                Button(lang.displayName) {
                                    viewModel.targetLanguage = lang
                                    Task { await viewModel.savePreferences() }
                                }
                            }
                        } label: {
                            HStack(spacing: VerbioSpacing.xs) {
                                Text(viewModel.targetLanguage.flag)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }
                    }

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    settingsToggle(
                        icon: "wand.and.stars",
                        title: "Auto-detect Source",
                        isOn: $viewModel.autoDetectSource
                    )
                }
            }
        }
    }

    // MARK: - Voice Section

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Voice")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard {
                VStack(spacing: VerbioSpacing.lg) {
                    settingsRow(
                        icon: "waveform",
                        title: "Speech Rate",
                        value: String(format: "%.1fx", viewModel.speechRate)
                    ) {
                        Slider(value: $viewModel.speechRate, in: 0.5...2.0, step: 0.1)
                            .frame(width: 120)
                            .tint(colors.brand.primary)
                    }

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    settingsToggle(
                        icon: "play.circle.fill",
                        title: "Auto-play Translation",
                        isOn: $viewModel.autoPlayTranslation
                    )
                }
            }
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("General")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard {
                VStack(spacing: VerbioSpacing.lg) {
                    settingsToggle(
                        icon: "hand.tap.fill",
                        title: "Haptic Feedback",
                        isOn: $viewModel.hapticFeedbackEnabled
                    )

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    settingsToggle(
                        icon: "clock.arrow.circlepath",
                        title: "Save History",
                        isOn: $viewModel.saveConversationHistory
                    )
                }
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Account")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard {
                VStack(spacing: VerbioSpacing.lg) {
                    Button {
                        viewModel.showLogoutConfirmation = true
                    } label: {
                        HStack(spacing: VerbioSpacing.md) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                                .foregroundStyle(VerbioColors.Semantic.error)
                                .frame(width: 28)

                            Text("Sign Out")
                                .verbioBodyMedium()
                                .foregroundStyle(VerbioColors.Semantic.error)

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: VerbioSpacing.sm) {
            Text("Verbio v1.0.0")
                .verbioCaption()
                .foregroundStyle(colors.text.tertiary)

            Text("Made with care for seamless communication")
                .verbioCaption()
                .foregroundStyle(colors.text.disabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, VerbioSpacing.md)
    }

    // MARK: - Helper Views

    private func settingsRow<Trailing: View>(
        icon: String,
        title: String,
        value: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: VerbioSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(colors.brand.primary)
                .frame(width: 28)

            Text(title)
                .verbioBodyMedium()
                .foregroundStyle(colors.text.primary)

            Spacer()

            trailing()
        }
    }

    private func settingsToggle(
        icon: String,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: VerbioSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(colors.brand.primary)
                .frame(width: 28)

            Text(title)
                .verbioBodyMedium()
                .foregroundStyle(colors.text.primary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(colors.brand.primary)
        }
    }
}

// MARK: - Preview

#Preview("Settings - Light") {
    SettingsView()
        .environment(AuthState())
        .preferredColorScheme(.light)
}

#Preview("Settings - Dark") {
    SettingsView()
        .environment(AuthState())
        .preferredColorScheme(.dark)
}
