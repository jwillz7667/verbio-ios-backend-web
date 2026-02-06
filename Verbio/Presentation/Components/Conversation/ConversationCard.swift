//
//  ConversationCard.swift
//  Verbio
//
//  List item card for conversation history
//

import SwiftUI

// MARK: - Conversation Card

struct ConversationCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let conversation: Conversation
    let onTap: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        InteractiveGlassCard(action: onTap) {
            HStack(spacing: VerbioSpacing.md) {
                // Language pair flags
                languageFlags

                // Content
                VStack(alignment: .leading, spacing: VerbioSpacing.xs) {
                    // Title
                    Text(conversation.displayTitle)
                        .verbioLabelMedium()
                        .foregroundStyle(colors.text.primary)
                        .lineLimit(1)

                    // Last message preview
                    if let preview = conversation.lastMessagePreview {
                        Text(preview)
                            .verbioCaption()
                            .foregroundStyle(colors.text.tertiary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Right side: time + count
                VStack(alignment: .trailing, spacing: VerbioSpacing.xs) {
                    Text(conversation.relativeTime)
                        .verbioCaption()
                        .foregroundStyle(colors.text.tertiary)

                    if conversation.messageCount > 0 {
                        Text("\(conversation.messageCount)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(
                                Circle()
                                    .fill(colors.brand.primary)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var languageFlags: some View {
        VStack(spacing: 2) {
            Text(conversation.sourceLanguage.flag)
                .font(.system(size: 20))
            Text(conversation.targetLanguage.flag)
                .font(.system(size: 20))
        }
    }
}

// MARK: - Preview

#Preview("Conversation Card") {
    ZStack {
        VerbioColors.Background.cream
            .ignoresSafeArea()

        VStack(spacing: VerbioSpacing.md) {
            ConversationCard(
                conversation: Conversation(
                    id: "1",
                    userId: "user-1",
                    title: "Meeting at the cafe",
                    sourceLanguage: .en,
                    targetLanguage: .es,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: Date(),
                    messages: [
                        Message(
                            id: "m1",
                            conversationId: "1",
                            speaker: .user,
                            originalText: "Can I have a coffee please?",
                            translatedText: "Puedo tener un cafe por favor?",
                            sourceLanguage: .en,
                            targetLanguage: .es,
                            originalAudioUrl: nil,
                            translatedAudioUrl: nil,
                            durationMs: 2000,
                            confidence: 0.92,
                            createdAt: Date()
                        )
                    ]
                ),
                onTap: {}
            )

            ConversationCard(
                conversation: Conversation(
                    id: "2",
                    userId: "user-1",
                    title: nil,
                    sourceLanguage: .en,
                    targetLanguage: .fr,
                    isActive: true,
                    createdAt: Date().addingTimeInterval(-86400),
                    updatedAt: Date().addingTimeInterval(-86400),
                    messages: nil
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
