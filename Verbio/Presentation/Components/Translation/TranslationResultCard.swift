//
//  TranslationResultCard.swift
//  Verbio
//
//  Card displaying translation result with playback
//

import SwiftUI

// MARK: - Translation Result Card

struct TranslationResultCard: View {

    // MARK: - Properties

    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let language: Language
    let isOriginal: Bool
    let isPlaying: Bool
    let onPlayTapped: (() -> Void)?

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    // MARK: - Initialization

    init(
        text: String,
        language: Language,
        isOriginal: Bool = false,
        isPlaying: Bool = false,
        onPlayTapped: (() -> Void)? = nil
    ) {
        self.text = text
        self.language = language
        self.isOriginal = isOriginal
        self.isPlaying = isPlaying
        self.onPlayTapped = onPlayTapped
    }

    // MARK: - Body

    var body: some View {
        GlassCard(style: isOriginal ? .subtle : .standard) {
            VStack(alignment: .leading, spacing: VerbioSpacing.md) {
                // Header
                HStack {
                    Text(language.flag)
                        .font(.title2)

                    Text(isOriginal ? "Original" : "Translation")
                        .verbioCaption()
                        .foregroundStyle(colors.text.tertiary)

                    Spacer()

                    Text(language.displayName)
                        .verbioCaption()
                        .foregroundStyle(colors.text.disabled)
                }

                // Text content
                Text(text)
                    .verbioBodyMedium()
                    .foregroundStyle(isOriginal ? colors.text.secondary : colors.text.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                // Play button (only for translated text)
                if !isOriginal, let onPlayTapped = onPlayTapped {
                    HStack {
                        Spacer()

                        Button(action: onPlayTapped) {
                            HStack(spacing: VerbioSpacing.sm) {
                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 12))

                                Text(isPlaying ? "Stop" : "Play")
                                    .verbioLabelSmall()
                            }
                            .foregroundStyle(isPlaying ? .white : colors.brand.primary)
                            .padding(.horizontal, VerbioSpacing.lg)
                            .padding(.vertical, VerbioSpacing.sm)
                            .background {
                                if isPlaying {
                                    Capsule()
                                        .fill(VerbioColors.Semantic.error)
                                } else {
                                    Capsule()
                                        .fill(colors.brand.primary.opacity(0.15))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Translation Pair Card

struct TranslationPairCard: View {
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let original: String
    let translated: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let isPlaying: Bool
    let onPlayTapped: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Original text
            TranslationResultCard(
                text: original,
                language: sourceLanguage,
                isOriginal: true
            )

            // Connector
            Rectangle()
                .fill(colors.brand.primary.opacity(0.2))
                .frame(width: 2, height: VerbioSpacing.lg)

            // Translated text
            TranslationResultCard(
                text: translated,
                language: targetLanguage,
                isOriginal: false,
                isPlaying: isPlaying,
                onPlayTapped: onPlayTapped
            )
        }
    }
}

// MARK: - Compact Translation Card

struct CompactTranslationCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let translation: Translation
    let isPlaying: Bool
    let onPlayTapped: () -> Void
    let onTapped: (() -> Void)?

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(
        translation: Translation,
        isPlaying: Bool = false,
        onPlayTapped: @escaping () -> Void,
        onTapped: (() -> Void)? = nil
    ) {
        self.translation = translation
        self.isPlaying = isPlaying
        self.onPlayTapped = onPlayTapped
        self.onTapped = onTapped
    }

    var body: some View {
        Button {
            onTapped?()
        } label: {
            GlassCard(style: .subtle) {
                HStack(spacing: VerbioSpacing.md) {
                    // Language indicators
                    VStack(spacing: VerbioSpacing.xs) {
                        Text(translation.sourceLanguage.flag)
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(colors.text.tertiary)
                        Text(translation.targetLanguage.flag)
                    }
                    .font(.title3)

                    // Text content
                    VStack(alignment: .leading, spacing: VerbioSpacing.xs) {
                        Text(translation.originalText)
                            .verbioCaption()
                            .foregroundStyle(colors.text.secondary)
                            .lineLimit(1)

                        Text(translation.translatedText)
                            .verbioLabelMedium()
                            .foregroundStyle(colors.text.primary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Play button
                    Button(action: onPlayTapped) {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(isPlaying ? VerbioColors.Semantic.error : colors.brand.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VerbioColors.Background.cream
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Single cards
                TranslationResultCard(
                    text: "Hello, how are you?",
                    language: .en,
                    isOriginal: true
                )

                TranslationResultCard(
                    text: "Hola, ¿cómo estás?",
                    language: .es,
                    isOriginal: false,
                    isPlaying: false,
                    onPlayTapped: {}
                )

                // Pair card
                TranslationPairCard(
                    original: "Good morning! Nice to meet you.",
                    translated: "¡Buenos días! Mucho gusto.",
                    sourceLanguage: .en,
                    targetLanguage: .es,
                    isPlaying: false,
                    onPlayTapped: {}
                )

                // Compact card
                CompactTranslationCard(
                    translation: Translation(
                        id: "1",
                        originalText: "Where is the nearest restaurant?",
                        translatedText: "¿Dónde está el restaurante más cercano?",
                        sourceLanguage: .en,
                        targetLanguage: .es,
                        audioUrl: "https://example.com/audio.mp3",
                        confidence: 0.95,
                        durationMs: 3500,
                        usage: TranslationUsage(
                            dailyRemaining: 8,
                            dailyLimit: 10,
                            tier: .free
                        )
                    ),
                    onPlayTapped: {}
                )
            }
            .padding()
        }
    }
}
