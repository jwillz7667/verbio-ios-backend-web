//
//  ConversationListView.swift
//  Verbio
//
//  List of user conversations (History tab)
//

import SwiftUI

// MARK: - Conversation List View

struct ConversationListView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = ConversationListViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.backgrounds.primary
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        loadingView
                    } else if viewModel.conversations.isEmpty {
                        emptyView
                    } else {
                        conversationList
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadConversations()
            }
            .refreshable {
                await viewModel.loadConversations()
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

            Text("Loading conversations...")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.tertiary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: VerbioSpacing.xl) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60, weight: .regular))
                .foregroundStyle(colors.brand.primary.opacity(0.5))

            VStack(spacing: VerbioSpacing.sm) {
                Text("No Conversations Yet")
                    .verbioHeadlineMedium()
                    .foregroundStyle(colors.text.secondary)

                Text("Start translating to see your conversation history here.")
                    .verbioBodyMedium()
                    .foregroundStyle(colors.text.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VerbioSpacing.xxl)
            }
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: VerbioSpacing.md) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(value: conversation.id) {
                        ConversationRowView(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteConversation(id: conversation.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, VerbioSpacing.horizontalPadding)
            .padding(.top, VerbioSpacing.md)
            .padding(.bottom, VerbioSpacing.jumbo)
        }
        .navigationDestination(for: String.self) { conversationId in
            ConversationDetailView(conversationId: conversationId)
        }
    }
}

// MARK: - Conversation Row View

private struct ConversationRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let conversation: Conversation

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: VerbioSpacing.sm) {
                HStack {
                    // Language pair badges
                    HStack(spacing: VerbioSpacing.xs) {
                        Text(conversation.sourceLanguage.flag)
                            .font(.system(size: 18))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.text.tertiary)
                        Text(conversation.targetLanguage.flag)
                            .font(.system(size: 18))
                    }

                    Spacer()

                    Text(conversation.relativeTime)
                        .verbioCaption()
                        .foregroundStyle(colors.text.tertiary)
                }

                Text(conversation.displayTitle)
                    .verbioLabelLarge()
                    .foregroundStyle(colors.text.primary)
                    .lineLimit(1)

                if let preview = conversation.lastMessagePreview {
                    Text(preview)
                        .verbioBodySmall()
                        .foregroundStyle(colors.text.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: VerbioSpacing.md) {
                    Label("\(conversation.messageCount)", systemImage: "message.fill")
                        .verbioCaption()
                        .foregroundStyle(colors.text.tertiary)

                    if !conversation.isActive {
                        Text("Archived")
                            .verbioCaption()
                            .foregroundStyle(colors.text.disabled)
                            .padding(.horizontal, VerbioSpacing.xs)
                            .padding(.vertical, VerbioSpacing.xxs)
                            .background(
                                Capsule()
                                    .fill(colors.text.disabled.opacity(0.15))
                            )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.text.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Conversations - Light") {
    ConversationListView()
        .preferredColorScheme(.light)
}

#Preview("Conversations - Dark") {
    ConversationListView()
        .preferredColorScheme(.dark)
}
