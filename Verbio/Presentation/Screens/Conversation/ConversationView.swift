//
//  ConversationView.swift
//  Verbio
//
//  Active conversation screen with bidirectional translation
//

import SwiftUI

// MARK: - Conversation View

struct ConversationView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: ConversationViewModel

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    init(conversationId: String) {
        _viewModel = State(initialValue: ConversationViewModel(conversationId: conversationId))
    }

    var body: some View {
        ZStack {
            colors.backgrounds.primary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                switch viewModel.state {
                case .loading:
                    loadingView

                case .error(let message):
                    errorView(message)

                default:
                    // Message list + controls
                    messageList
                    Divider()
                        .background(colors.text.tertiary.opacity(0.3))
                    controlBar
                }
            }
        }
        .navigationTitle(viewModel.conversation?.displayTitle ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                usageIndicator
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

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: VerbioSpacing.lg) {
            Spacer()
            ProgressView()
                .tint(colors.brand.primary)
            Text("Loading conversation...")
                .verbioBodyMedium()
                .foregroundStyle(colors.text.secondary)
            Spacer()
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: VerbioSpacing.lg) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(VerbioColors.Semantic.error)
            Text(message)
                .verbioBodyMedium()
                .foregroundStyle(colors.text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VerbioSpacing.xxl)
            Button("Retry") {
                Task { await viewModel.loadConversation() }
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.brand.primary)
            Spacer()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: VerbioSpacing.md) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            isPlaying: viewModel.playingMessageId == message.id,
                            onPlayTapped: {
                                Task {
                                    if viewModel.playingMessageId == message.id {
                                        await viewModel.stopPlayback()
                                    } else {
                                        await viewModel.playMessage(message)
                                    }
                                }
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, VerbioSpacing.horizontalPadding)
                .padding(.vertical, VerbioSpacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: VerbioSpacing.md) {
            // Speaker toggle
            speakerToggle
                .padding(.top, VerbioSpacing.md)

            // Waveform during recording
            if viewModel.isRecording {
                VStack(spacing: VerbioSpacing.sm) {
                    AudioWaveformView(
                        level: viewModel.audioLevel,
                        isRecording: true,
                        primaryColor: colors.brand.primary,
                        secondaryColor: colors.brand.primary.opacity(0.5)
                    )
                    .frame(height: 32)

                    Text(viewModel.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(colors.text.primary)
                        .monospacedDigit()
                }
                .transition(.opacity)
                .padding(.horizontal, VerbioSpacing.xxl)
            }

            // Processing indicator
            if viewModel.isProcessing {
                HStack(spacing: VerbioSpacing.sm) {
                    ProgressView()
                        .tint(colors.brand.primary)
                    Text("Translating...")
                        .verbioCaption()
                        .foregroundStyle(colors.text.secondary)
                }
                .transition(.opacity)
            }

            // Record button
            recordButton
                .padding(.bottom, VerbioSpacing.lg)
        }
        .background {
            Rectangle()
                .fill(colors.backgrounds.primary)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
        }
    }

    private var speakerToggle: some View {
        HStack(spacing: 0) {
            speakerOption(
                speaker: .user,
                label: "You \(viewModel.conversation?.sourceLanguage.flag ?? "")"
            )

            speakerOption(
                speaker: .other,
                label: "Other \(viewModel.conversation?.targetLanguage.flag ?? "")"
            )
        }
        .background(colors.backgrounds.elevated)
        .clipShape(RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.md))
        .padding(.horizontal, VerbioSpacing.xxl)
        .disabled(viewModel.isRecording || viewModel.isProcessing)
        .opacity(viewModel.isRecording || viewModel.isProcessing ? 0.6 : 1.0)
    }

    private func speakerOption(speaker: Speaker, label: String) -> some View {
        Button {
            if viewModel.activeSpeaker != speaker {
                viewModel.toggleSpeaker()
            }
        } label: {
            Text(label)
                .verbioLabelMedium()
                .foregroundStyle(
                    viewModel.activeSpeaker == speaker
                        ? .white
                        : colors.text.secondary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, VerbioSpacing.sm)
                .background {
                    if viewModel.activeSpeaker == speaker {
                        RoundedRectangle(cornerRadius: VerbioSpacing.CornerRadius.sm)
                            .fill(colors.brand.primary)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var recordButton: some View {
        Button {
            Task {
                if viewModel.isRecording {
                    await viewModel.stopRecording()
                } else {
                    await viewModel.startRecording()
                }
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(colors.brand.primary.opacity(0.3), lineWidth: 3)
                    .frame(width: 56, height: 56)

                // Level indicator ring
                if viewModel.isRecording {
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.audioLevel))
                        .stroke(colors.brand.primary, lineWidth: 3)
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)
                }

                // Inner button
                Circle()
                    .fill(viewModel.isRecording ? Color.red : colors.brand.primary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(viewModel.isRecording ? 0.92 : 1.0)
                    .animation(.spring(response: 0.3), value: viewModel.isRecording)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing || viewModel.isAtLimit)
        .opacity(viewModel.isProcessing ? 0.5 : 1.0)
    }

    private var usageIndicator: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.dailyRemaining)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(viewModel.dailyRemaining <= 2 ? .orange : colors.text.secondary)

            Text("/\(viewModel.dailyLimit)")
                .font(.caption2)
                .foregroundStyle(colors.text.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Conversation View") {
    NavigationStack {
        ConversationView(conversationId: "preview-id")
    }
}
