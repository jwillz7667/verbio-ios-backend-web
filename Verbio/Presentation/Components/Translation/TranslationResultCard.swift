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

    let text: String
    let language: Language
    let isOriginal: Bool
    let isPlaying: Bool
    let onPlayTapped: (() -> Void)?

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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(language.flag)
                    .font(.title2)

                Text(isOriginal ? "Original" : "Translation")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(language.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Text content
            Text(text)
                .font(.body)
                .fontWeight(isOriginal ? .regular : .medium)
                .foregroundStyle(isOriginal ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            // Play button (only for translated text)
            if !isOriginal, let onPlayTapped = onPlayTapped {
                HStack {
                    Spacer()

                    Button(action: onPlayTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.caption)

                            Text(isPlaying ? "Stop" : "Play")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isPlaying ? Color.red.opacity(0.8) : Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Translation Pair Card

struct TranslationPairCard: View {

    // MARK: - Properties

    let original: String
    let translated: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let isPlaying: Bool
    let onPlayTapped: () -> Void

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
                .fill(.white.opacity(0.1))
                .frame(width: 2, height: 16)

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
    let translation: Translation
    let isPlaying: Bool
    let onPlayTapped: () -> Void
    let onTapped: (() -> Void)?

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
            HStack(spacing: 12) {
                // Language indicators
                VStack(spacing: 4) {
                    Text(translation.sourceLanguage.flag)
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(translation.targetLanguage.flag)
                }
                .font(.title3)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(translation.originalText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(translation.translatedText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play button
                Button(action: onPlayTapped) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(isPlaying ? .red : .white)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
