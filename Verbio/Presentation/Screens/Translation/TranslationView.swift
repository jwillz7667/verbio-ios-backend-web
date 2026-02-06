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

    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = TranslationViewModel()

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

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
                        .padding(.top, VerbioSpacing.lg)
                        .padding(.horizontal, VerbioSpacing.xxl)

                    Spacer()

                    // Translation results
                    if let translation = viewModel.currentTranslation {
                        translationResult(translation)
                            .padding(.horizontal, VerbioSpacing.xxl)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    Spacer()

                    // Recording controls
                    recordingSection
                        .padding(.bottom, geometry.safeAreaInsets.bottom + VerbioSpacing.xxl)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Translate")
                    .verbioHeadlineMedium()
                    .foregroundStyle(colors.text.primary)
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
        ZStack {
            colors.backgrounds.primary

            // State-aware gradient overlay
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.5), value: viewModel.state)

            // Subtle radial glow centered on mic button
            RadialGradient(
                colors: [
                    accentGlowColor.opacity(0.15),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 250
            )
            .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
    }

    private var gradientColors: [Color] {
        switch viewModel.state {
        case .idle, .translated:
            return [
                VerbioColors.Gradient.brandDark.opacity(0.08),
                VerbioColors.Gradient.charcoalLight.opacity(0.04),
                Color.clear
            ]
        case .recording:
            return [
                VerbioColors.Semantic.error.opacity(0.12),
                VerbioColors.Gradient.warmGold.opacity(0.08),
                Color.clear
            ]
        case .processing:
            return [
                VerbioColors.Primary.amber600.opacity(0.1),
                VerbioColors.Gradient.charcoalLight.opacity(0.06),
                Color.clear
            ]
        case .playing:
            return [
                VerbioColors.Gradient.brandLight.opacity(0.08),
                VerbioColors.Gradient.brandDark.opacity(0.04),
                Color.clear
            ]
        case .error:
            return [
                VerbioColors.Semantic.error.opacity(0.1),
                VerbioColors.Gradient.charcoalDark.opacity(0.05),
                Color.clear
            ]
        }
    }

    private var accentGlowColor: Color {
        switch viewModel.state {
        case .idle, .translated: return VerbioColors.Primary.amber500
        case .recording: return VerbioColors.Semantic.error
        case .processing: return VerbioColors.Primary.amber600
        case .playing: return VerbioColors.Gradient.brandLight
        case .error: return VerbioColors.Semantic.error
        }
    }

    private var languageSelector: some View {
        HStack(spacing: VerbioSpacing.lg) {
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
        VStack(spacing: VerbioSpacing.lg) {
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
        VStack(spacing: VerbioSpacing.xxl) {
            // Processing indicator
            if viewModel.isProcessing {
                GlassCard(style: .subtle) {
                    HStack(spacing: VerbioSpacing.md) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(colors.brand.primary)

                        Text("Translating...")
                            .verbioBodyMedium()
                            .foregroundStyle(colors.text.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, VerbioSpacing.xxl)
                .transition(.opacity)
            }

            // Waveform during recording
            if viewModel.isRecording {
                VStack(spacing: VerbioSpacing.md) {
                    AudioWaveformView(
                        level: viewModel.audioLevel,
                        isRecording: true
                    )
                    .frame(height: 40)

                    Text(viewModel.formattedDuration)
                        .verbioDisplaySmall()
                        .foregroundStyle(colors.text.primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, VerbioSpacing.xxl)
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
                // Outer glass ring
                Circle()
                    .stroke(colors.brand.primary.opacity(0.3), lineWidth: 4)
                    .frame(width: 88, height: 88)

                // Level indicator ring
                if viewModel.isRecording {
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.audioLevel))
                        .stroke(
                            VerbioColors.Semantic.error,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)
                }

                // Inner button with glass effect
                Circle()
                    .fill(viewModel.isRecording ? VerbioColors.Semantic.error : colors.brand.primary)
                    .frame(width: 72, height: 72)
                    .overlay {
                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                    .shadow(
                        color: (viewModel.isRecording ? VerbioColors.Semantic.error : colors.brand.primary).opacity(0.3),
                        radius: viewModel.isRecording ? 16 : 8,
                        x: 0,
                        y: 4
                    )
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
            .verbioBodySmall()
            .foregroundStyle(colors.text.tertiary)
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
        HStack(spacing: VerbioSpacing.xs) {
            Text("\(viewModel.dailyRemaining)")
                .verbioLabelSmall()
                .foregroundStyle(viewModel.isNearingLimit ? VerbioColors.Semantic.warning : colors.text.primary)

            Text("/\(viewModel.dailyLimit)")
                .verbioCaption()
                .foregroundStyle(colors.text.tertiary)
        }
        .padding(.horizontal, VerbioSpacing.sm)
        .padding(.vertical, VerbioSpacing.xs)
        .modifier(CapsuleGlassModifier())
    }
}

private struct CapsuleGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(VerbioGlass.warmTint), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TranslationView()
    }
}
