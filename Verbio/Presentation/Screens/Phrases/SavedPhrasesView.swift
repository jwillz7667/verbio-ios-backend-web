//
//  SavedPhrasesView.swift
//  Verbio
//
//  Saved phrases view with search and favorites
//

import SwiftUI

// MARK: - Saved Phrases View

struct SavedPhrasesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = SavedPhrasesViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm background
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

                Group {
                    if viewModel.isLoading && viewModel.phrases.isEmpty {
                        loadingView
                    } else if viewModel.phrases.isEmpty {
                        emptyView
                    } else {
                        phraseList
                    }
                }
            }
            .navigationTitle("Saved Phrases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search phrases")
            .onChange(of: viewModel.searchText) {
                Task {
                    await viewModel.searchPhrases()
                }
            }
            .task {
                await viewModel.loadPhrases()
            }
            .refreshable {
                await viewModel.loadPhrases()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: VerbioSpacing.lg) {
            ProgressView()
                .tint(colors.brand.primary)

            Text("Loading phrases...")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.tertiary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: VerbioSpacing.xl) {
            Image(systemName: "bookmark")
                .font(.system(size: 60, weight: .regular))
                .foregroundStyle(colors.brand.primary.opacity(0.5))

            VStack(spacing: VerbioSpacing.sm) {
                Text("No Saved Phrases")
                    .verbioHeadlineMedium()
                    .foregroundStyle(colors.text.secondary)

                Text("Save useful translations for quick reference. Tap the bookmark icon during translation to save phrases.")
                    .verbioBodyMedium()
                    .foregroundStyle(colors.text.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VerbioSpacing.xxl)
            }
        }
    }

    // MARK: - Phrase List

    private var phraseList: some View {
        ScrollView {
            LazyVStack(spacing: VerbioSpacing.md) {
                ForEach(viewModel.phrases) { phrase in
                    PhraseCardView(
                        phrase: phrase,
                        onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(phrase)
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deletePhrase(id: phrase.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, VerbioSpacing.horizontalPadding)
            .padding(.top, VerbioSpacing.md)
            .padding(.bottom, VerbioSpacing.jumbo)
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button {
                viewModel.showFavoritesOnly = false
                Task { await viewModel.loadPhrases() }
            } label: {
                Label("All Phrases", systemImage: viewModel.showFavoritesOnly ? "" : "checkmark")
            }

            Button {
                viewModel.showFavoritesOnly = true
                Task { await viewModel.loadPhrases() }
            } label: {
                Label("Favorites Only", systemImage: viewModel.showFavoritesOnly ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 18))
                .foregroundStyle(colors.brand.primary)
        }
    }
}

// MARK: - Phrase Card View

private struct PhraseCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let phrase: SavedPhrase
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                // Header
                HStack {
                    Text(phrase.shortLanguagePair)
                        .verbioCaption()
                        .foregroundStyle(colors.text.tertiary)

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: phrase.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundStyle(phrase.isFavorite ? VerbioColors.Primary.amber500 : colors.text.tertiary)
                    }
                    .buttonStyle(.plain)
                }

                // Original text
                Text(phrase.originalText)
                    .verbioBodyMedium()
                    .foregroundStyle(colors.text.primary)
                    .lineLimit(3)

                // Translated text
                Text(phrase.translatedText)
                    .verbioBodyMedium()
                    .foregroundStyle(colors.brand.primary)
                    .lineLimit(3)

                // Footer
                HStack {
                    Text(phrase.relativeTime)
                        .verbioCaption()
                        .foregroundStyle(colors.text.disabled)

                    if phrase.usageCount > 0 {
                        Text("Used \(phrase.usageCount)x")
                            .verbioCaption()
                            .foregroundStyle(colors.text.disabled)
                    }

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(colors.text.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Saved Phrases - Light") {
    SavedPhrasesView()
        .preferredColorScheme(.light)
}

#Preview("Saved Phrases - Dark") {
    SavedPhrasesView()
        .preferredColorScheme(.dark)
}
