//
//  TranslationView.swift
//  Verbio
//
//  Main translation screen with recording and playback
//

import SwiftUI

// MARK: - Translation View

struct TranslationView: View {

    // MARK: - Properties

    @State private var viewModel = TranslationViewModel()

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Language selector
                    languageSelector
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    Spacer()

                    // Translation results
                    if let translation = viewModel.currentTranslation {
                        translationResult(translation)
                            .padding(.horizontal, 24)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    Spacer()

                    // Recording controls
                    recordingSection
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Translate")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            ToolbarItem(placement: .topBarTrailing) {
                usageIndicator
            }
        }
        .task {
            await viewModel.loadPreferences()
            await viewModel.loadUsage()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.reset()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.5), value: viewModel.state)
    }

    private var gradientColors: [Color] {
        switch viewModel.state {
        case .idle, .translated:
            return [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
        case .recording:
            return [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
        case .processing:
            return [Color.purple.opacity(0.8), Color.indigo.opacity(0.6)]
        case .playing:
            return [Color.green.opacity(0.8), Color.teal.opacity(0.6)]
        case .error:
            return [Color.red.opacity(0.8), Color.pink.opacity(0.6)]
        }
    }

    private var languageSelector: some View {
        HStack(spacing: 16) {
            LanguagePicker(
                selectedLanguage: $viewModel.sourceLanguage,
                label: "From"
            )
            .disabled(viewModel.isRecording || viewModel.isProcessing)

            LanguageSwapButton(
                sourceLanguage: $viewModel.sourceLanguage,
                targetLanguage: $viewModel.targetLanguage
            )
            .disabled(viewModel.isRecording || viewModel.isProcessing)

            LanguagePicker(
                selectedLanguage: $viewModel.targetLanguage,
                label: "To"
            )
            .disabled(viewModel.isRecording || viewModel.isProcessing)
        }
    }

    private func translationResult(_ translation: Translation) -> some View {
        VStack(spacing: 16) {
            // Original text card
            TranslationResultCard(
                text: translation.originalText,
                language: translation.sourceLanguage,
                isOriginal: true
            )

            // Translation card with play button
            TranslationResultCard(
                text: translation.translatedText,
                language: translation.targetLanguage,
                isOriginal: false,
                isPlaying: viewModel.isPlaying,
                onPlayTapped: {
                    Task {
                        if viewModel.isPlaying {
                            await viewModel.stopPlayback()
                        } else {
                            await viewModel.playTranslation()
                        }
                    }
                }
            )
        }
    }

    private var recordingSection: some View {
        VStack(spacing: 24) {
            // Processing indicator
            if viewModel.isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Translating...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .transition(.opacity)
            }

            // Waveform during recording
            if viewModel.isRecording {
                VStack(spacing: 12) {
                    AudioWaveformView(
                        level: viewModel.audioLevel,
                        isRecording: true
                    )
                    .frame(height: 40)

                    Text(viewModel.formattedDuration)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .transition(.opacity)
            }

            // Record button
            recordButton

            // Instructions
            instructionText
        }
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
                    .stroke(.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 88, height: 88)

                // Level indicator ring
                if viewModel.isRecording {
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.audioLevel))
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)
                }

                // Inner button
                Circle()
                    .fill(viewModel.isRecording ? .red : .white)
                    .frame(width: 72, height: 72)
                    .overlay {
                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title)
                                .foregroundStyle(.black)
                        }
                    }
                    .scaleEffect(viewModel.isRecording ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3), value: viewModel.isRecording)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing || viewModel.isAtLimit)
        .opacity(viewModel.isProcessing ? 0.5 : 1.0)
    }

    private var instructionText: some View {
        Text(instructionMessage)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
    }

    private var instructionMessage: String {
        switch viewModel.state {
        case .idle:
            return viewModel.isAtLimit
                ? "Daily limit reached. Upgrade to continue."
                : "Tap to start recording"
        case .recording:
            return "Tap to stop and translate"
        case .processing:
            return "Processing your audio..."
        case .translated:
            return "Tap the play button to hear the translation"
        case .playing:
            return "Playing translation..."
        case .error(let message):
            return message
        }
    }

    private var usageIndicator: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.dailyRemaining)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(viewModel.isNearingLimit ? .orange : .white)

            Text("/\(viewModel.dailyLimit)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TranslationView()
    }
}
