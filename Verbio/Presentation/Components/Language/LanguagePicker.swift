//
//  LanguagePicker.swift
//  Verbio
//
//  Language selection component
//

import SwiftUI

// MARK: - Language Picker

struct LanguagePicker: View {

    // MARK: - Properties

    @Binding var selectedLanguage: Language
    let label: String
    let showFlag: Bool

    @State private var isExpanded = false

    // MARK: - Initialization

    init(
        selectedLanguage: Binding<Language>,
        label: String = "Language",
        showFlag: Bool = true
    ) {
        self._selectedLanguage = selectedLanguage
        self.label = label
        self.showFlag = showFlag
    }

    // MARK: - Body

    var body: some View {
        Menu {
            ForEach(Language.allCases.sorted()) { language in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLanguage = language
                    }
                } label: {
                    HStack {
                        if showFlag {
                            Text(language.flag)
                        }
                        Text(language.displayName)

                        if language == selectedLanguage {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            LanguageButton(
                language: selectedLanguage,
                showFlag: showFlag
            )
        }
    }
}

// MARK: - Language Button

struct LanguageButton: View {
    let language: Language
    let showFlag: Bool
    let style: LanguageButtonStyle

    enum LanguageButtonStyle {
        case standard
        case compact
        case expanded
    }

    init(
        language: Language,
        showFlag: Bool = true,
        style: LanguageButtonStyle = .standard
    ) {
        self.language = language
        self.showFlag = showFlag
        self.style = style
    }

    var body: some View {
        HStack(spacing: 8) {
            if showFlag {
                Text(language.flag)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 2) {
                switch style {
                case .standard:
                    Text(language.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                case .compact:
                    Text(language.shortCode)
                        .font(.caption)
                        .fontWeight(.bold)

                case .expanded:
                    Text(language.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(language.nativeName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if style != .compact {
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, style == .compact ? 12 : 16)
        .padding(.vertical, style == .compact ? 8 : 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Language Swap Button

struct LanguageSwapButton: View {

    // MARK: - Properties

    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language

    @State private var rotation: Double = 0

    // MARK: - Body

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let temp = sourceLanguage
                sourceLanguage = targetLanguage
                targetLanguage = temp
                rotation += 180
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .rotationEffect(.degrees(rotation))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Language Pair Selector

struct LanguagePairSelector: View {
    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language

    var body: some View {
        HStack(spacing: 16) {
            LanguagePicker(
                selectedLanguage: $sourceLanguage,
                label: "From"
            )

            LanguageSwapButton(
                sourceLanguage: $sourceLanguage,
                targetLanguage: $targetLanguage
            )

            LanguagePicker(
                selectedLanguage: $targetLanguage,
                label: "To"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var source = Language.en
        @State private var target = Language.es

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [VerbioColors.Gradient.charcoalLight.opacity(0.9), VerbioColors.Gradient.brandDark.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    // Standard picker
                    LanguagePicker(selectedLanguage: $source)

                    // Pair selector
                    LanguagePairSelector(
                        sourceLanguage: $source,
                        targetLanguage: $target
                    )

                    // Button styles
                    HStack(spacing: 20) {
                        LanguageButton(language: .en, style: .compact)
                        LanguageButton(language: .es, style: .standard)
                        LanguageButton(language: .fr, style: .expanded)
                    }

                    // Swap button
                    LanguageSwapButton(
                        sourceLanguage: $source,
                        targetLanguage: $target
                    )
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
