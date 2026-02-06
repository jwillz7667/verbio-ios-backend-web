//
//  HomeView.swift
//  Verbio
//
//  Home screen with Liquid Glass UI
//

import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedTab: AppRoute
    @State private var viewModel = HomeViewModel()
    @State private var showingLogoutConfirmation = false

    init(selectedTab: Binding<AppRoute> = .constant(.home)) {
        _selectedTab = selectedTab
    }

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()

                // Content
                ScrollView {
                    VStack(spacing: VerbioSpacing.xl) {
                        // Header
                        headerSection

                        // Quick Actions
                        quickActionsSection

                        // Usage Stats
                        usageSection

                        // Recent Activity (placeholder)
                        recentActivitySection
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
                        showingLogoutConfirmation = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.brand.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await viewModel.logout()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            colors.backgrounds.primary

            LinearGradient(
                colors: [
                    VerbioColors.Primary.amber400.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
            Text("Hello, \(viewModel.displayName)")
                .verbioDisplayMedium()
                .foregroundStyle(colors.text.primary)

            HStack(spacing: VerbioSpacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(colors.brand.primary)

                Text(viewModel.subscriptionTier.displayName)
                    .verbioLabelMedium()
                    .foregroundStyle(colors.text.secondary)

                if viewModel.subscriptionTier == .free {
                    Text("• Upgrade")
                        .verbioLabelMedium()
                        .foregroundStyle(colors.brand.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("Quick Actions")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            // Main translation button
            GlassButton(
                "Start Translation",
                icon: "mic.fill",
                style: .primary,
                size: .large
            ) {
                selectedTab = .translation
            }

            // Secondary actions
            HStack(spacing: VerbioSpacing.md) {
                InteractiveGlassCard(action: {
                    selectedTab = .history
                }) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(colors.brand.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Conversation")
                                .verbioLabelMedium()
                                .foregroundStyle(colors.text.primary)

                            Text("Two-way")
                                .verbioCaption()
                                .foregroundStyle(colors.text.tertiary)
                        }

                        Spacer()
                    }
                }

                InteractiveGlassCard(action: {
                    selectedTab = .phrases
                }) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(colors.brand.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phrases")
                                .verbioLabelMedium()
                                .foregroundStyle(colors.text.primary)

                            Text("Saved")
                                .verbioCaption()
                                .foregroundStyle(colors.text.tertiary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            Text("This Month")
                .verbioHeadlineSmall()
                .foregroundStyle(colors.text.secondary)

            GlassCard(style: .elevated) {
                VStack(spacing: VerbioSpacing.md) {
                    // Minutes remaining
                    HStack {
                        VStack(alignment: .leading, spacing: VerbioSpacing.xxs) {
                            Text("Minutes Remaining")
                                .verbioCaption()
                                .foregroundStyle(colors.text.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: VerbioSpacing.xs) {
                                Text(viewModel.minutesRemaining)
                                    .verbioDisplayMedium()
                                    .foregroundStyle(colors.text.primary)

                                Text("/ \(viewModel.subscriptionTier.monthlyMinutes) min")
                                    .verbioBodySmall()
                                    .foregroundStyle(colors.text.tertiary)
                            }
                        }

                        Spacer()

                        // Circular progress
                        ZStack {
                            Circle()
                                .stroke(colors.text.tertiary.opacity(0.2), lineWidth: 6)

                            Circle()
                                .trim(from: 0, to: viewModel.usagePercentage)
                                .stroke(colors.brand.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(viewModel.usagePercentage * 100))%")
                                .verbioLabelSmall()
                                .foregroundStyle(colors.text.secondary)
                        }
                        .frame(width: 56, height: 56)
                    }

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    // Quick stats
                    HStack {
                        StatItem(
                            value: "12",
                            label: "Translations",
                            icon: "text.bubble.fill"
                        )

                        Spacer()

                        StatItem(
                            value: "3",
                            label: "Conversations",
                            icon: "message.fill"
                        )

                        Spacer()

                        StatItem(
                            value: "5",
                            label: "Languages",
                            icon: "globe"
                        )
                    }
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.md) {
            HStack {
                Text("Recent Activity")
                    .verbioHeadlineSmall()
                    .foregroundStyle(colors.text.secondary)

                Spacer()

                Button("See All") {
                    selectedTab = .history
                }
                .verbioLabelSmall()
                .foregroundStyle(colors.brand.primary)
            }

            // Placeholder for recent translations
            GlassCard {
                VStack(spacing: VerbioSpacing.md) {
                    RecentTranslationRow(
                        sourceText: "Hello, how are you?",
                        translatedText: "Hola, ¿cómo estás?",
                        sourceLanguage: "English",
                        targetLanguage: "Spanish",
                        timeAgo: "2 min ago"
                    )

                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))

                    RecentTranslationRow(
                        sourceText: "Thank you very much",
                        translatedText: "Muchas gracias",
                        sourceLanguage: "English",
                        targetLanguage: "Spanish",
                        timeAgo: "15 min ago"
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    @Environment(\.colorScheme) private var colorScheme

    let value: String
    let label: String
    let icon: String

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: VerbioSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(colors.brand.primary)

            Text(value)
                .verbioHeadlineMedium()
                .foregroundStyle(colors.text.primary)

            Text(label)
                .verbioCaption()
                .foregroundStyle(colors.text.tertiary)
        }
    }
}

private struct RecentTranslationRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let sourceText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let timeAgo: String

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
            HStack {
                Text("\(sourceLanguage) → \(targetLanguage)")
                    .verbioCaption()
                    .foregroundStyle(colors.text.tertiary)

                Spacer()

                Text(timeAgo)
                    .verbioCaption()
                    .foregroundStyle(colors.text.tertiary)
            }

            Text(sourceText)
                .verbioBodyMedium()
                .foregroundStyle(colors.text.secondary)

            Text(translatedText)
                .verbioBodyMedium()
                .foregroundStyle(colors.brand.primary)
        }
    }
}

// MARK: - Preview

#Preview("Home - Light") {
    HomeView(selectedTab: .constant(.home))
        .preferredColorScheme(.light)
}

#Preview("Home - Dark") {
    HomeView(selectedTab: .constant(.home))
        .preferredColorScheme(.dark)
}
