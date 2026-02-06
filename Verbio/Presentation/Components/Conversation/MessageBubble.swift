//
//  MessageBubble.swift
//  Verbio
//
//  Chat bubble component for conversation messages
//

import SwiftUI

// MARK: - Message Bubble

struct MessageBubble: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: Message
    let isPlaying: Bool
    var onPlayTapped: (() -> Void)?

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 40) }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: VerbioSpacing.xs) {
                // Speaker label with flag
                speakerLabel

                // Bubble content
                bubbleContent

                // Timestamp
                Text(message.createdAt, style: .relative)
                    .verbioCaption()
                    .foregroundStyle(colors.text.tertiary)
            }

            if !message.isFromUser { Spacer(minLength: 40) }
        }
    }

    // MARK: - Subviews

    private var speakerLabel: some View {
        HStack(spacing: VerbioSpacing.xs) {
            Text(message.sourceLanguage.flag)
                .font(.caption)

            Text(message.isFromUser ? "You" : "Other")
                .verbioCaption()
                .foregroundStyle(colors.text.secondary)
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
            // Original text (secondary)
            Text(message.originalText)
                .verbioBodySmall()
                .foregroundStyle(colors.text.tertiary)

            // Translated text (primary)
            Text(message.translatedText)
                .verbioBodyMedium()
                .foregroundStyle(message.isFromUser ? colors.text.primary : colors.text.primary)

            // Bottom row: confidence + play button
            HStack(spacing: VerbioSpacing.sm) {
                if let confidence = message.confidencePercent {
                    Text("\(confidence)%")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(confidenceColor(confidence))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(confidenceColor(confidence).opacity(0.15))
                        )
                }

                Spacer()

                if message.hasAudio {
                    Button {
                        onPlayTapped?()
                    } label: {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.brand.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(VerbioSpacing.md)
        .modifier(BubbleBackgroundModifier(
            isFromUser: message.isFromUser,
            cornerRadius: VerbioSpacing.CornerRadius.lg,
            colors: colors
        ))
    }

    // MARK: - Helpers

    private func confidenceColor(_ confidence: Int) -> Color {
        switch confidence {
        case 90...100: return VerbioColors.Semantic.success
        case 70..<90: return VerbioColors.Primary.amber500
        default: return VerbioColors.Semantic.error
        }
    }
}

private struct BubbleBackgroundModifier: ViewModifier {
    let isFromUser: Bool
    let cornerRadius: CGFloat
    let colors: VerbioColorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(isFromUser ? VerbioGlass.amberTint : VerbioGlass.warmTint),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isFromUser ? colors.brand.primary.opacity(0.12) : colors.backgrounds.elevated)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Preview

#Preview("Message Bubbles") {
    ZStack {
        VerbioColors.Background.cream
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: VerbioSpacing.md) {
                MessageBubble(
                    message: Message(
                        id: "1",
                        conversationId: "conv-1",
                        speaker: .user,
                        originalText: "Hello, how are you today?",
                        translatedText: "Hola, como estas hoy?",
                        sourceLanguage: .en,
                        targetLanguage: .es,
                        originalAudioUrl: nil,
                        translatedAudioUrl: "https://example.com/audio.mp3",
                        durationMs: 3000,
                        confidence: 0.95,
                        createdAt: Date()
                    ),
                    isPlaying: false
                )

                MessageBubble(
                    message: Message(
                        id: "2",
                        conversationId: "conv-1",
                        speaker: .other,
                        originalText: "Estoy bien, gracias!",
                        translatedText: "I'm doing well, thanks!",
                        sourceLanguage: .es,
                        targetLanguage: .en,
                        originalAudioUrl: nil,
                        translatedAudioUrl: "https://example.com/audio2.mp3",
                        durationMs: 2000,
                        confidence: 0.88,
                        createdAt: Date().addingTimeInterval(-60)
                    ),
                    isPlaying: false
                )
            }
            .padding()
        }
    }
}
