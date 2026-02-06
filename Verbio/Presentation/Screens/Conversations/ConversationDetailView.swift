//
//  ConversationDetailView.swift
//  Verbio
//
//  Detail view for a single conversation with messages
//

import SwiftUI

// MARK: - Conversation Detail View

struct ConversationDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: ConversationDetailViewModel

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(conversationId: String) {
        _viewModel = State(initialValue: ConversationDetailViewModel(conversationId: conversationId))
    }

    var body: some View {
        ZStack {
            colors.backgrounds.primary
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    loadingView
                } else if viewModel.messages.isEmpty {
                    emptyView
                } else {
                    messageList
                }
            }
        }
        .navigationTitle(viewModel.conversationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                languagePairBadge
            }
        }
        .task {
            await viewModel.loadConversation()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: VerbioSpacing.lg) {
            ProgressView()
                .tint(colors.brand.primary)

            Text("Loading messages...")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.tertiary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: VerbioSpacing.xl) {
            Image(systemName: "message")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(colors.brand.primary.opacity(0.5))

            Text("No messages in this conversation")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.tertiary)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: VerbioSpacing.md) {
                ForEach(viewModel.messages) { message in
                    MessageBubbleView(
                        message: message,
                        onSavePhrase: {
                            Task {
                                await viewModel.savePhrase(from: message)
                            }
                        },
                        onPlayAudio: {
                            Task {
                                await viewModel.playMessageAudio(message)
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

    // MARK: - Language Pair Badge

    private var languagePairBadge: some View {
        HStack(spacing: VerbioSpacing.xs) {
            Text(viewModel.sourceLanguageFlag)
            Image(systemName: "arrow.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(colors.text.tertiary)
            Text(viewModel.targetLanguageFlag)
        }
        .verbioCaption()
        .padding(.horizontal, VerbioSpacing.sm)
        .padding(.vertical, VerbioSpacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Message Bubble View

private struct MessageBubbleView: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: Message
    let onSavePhrase: () -> Void
    let onPlayAudio: () -> Void

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: VerbioSpacing.xs) {
            // Speaker label
            HStack(spacing: VerbioSpacing.xs) {
                if !message.isFromUser {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(colors.text.tertiary)
                }

                Text(message.isFromUser ? "You" : "Other")
                    .verbioCaption()
                    .foregroundStyle(colors.text.tertiary)

                if message.isFromUser {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(colors.text.tertiary)
                }
            }

            // Message bubble
            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                // Original text
                Text(message.originalText)
                    .verbioBodyMedium()
                    .foregroundStyle(colors.text.primary)

                Divider()
                    .background(colors.text.tertiary.opacity(0.3))

                // Translated text
                Text(message.translatedText)
                    .verbioBodyMedium()
                    .foregroundStyle(colors.brand.primary)

                // Action bar
                HStack(spacing: VerbioSpacing.md) {
                    if message.hasAudio {
                        Button(action: onPlayAudio) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(colors.brand.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onSavePhrase) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 14))
                            .foregroundStyle(colors.text.tertiary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let confidence = message.confidencePercent {
                        Text("\(confidence)%")
                            .verbioCaption()
                            .foregroundStyle(colors.text.disabled)
                    }

                    if let duration = message.formattedDuration {
                        Text(duration)
                            .verbioCaption()
                            .foregroundStyle(colors.text.disabled)
                    }
                }
            }
            .verbioCardPadding()
            .background {
                RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.lg)
                    .fill(message.isFromUser ? colors.brand.primary.opacity(0.1) : colors.backgrounds.elevated)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
    }
}

// MARK: - Preview

#Preview("Conversation Detail") {
    NavigationStack {
        ConversationDetailView(conversationId: "test-id")
    }
}
