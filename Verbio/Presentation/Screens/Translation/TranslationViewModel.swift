//
//  TranslationViewModel.swift
//  Verbio
//
//  ViewModel for translation screen
//

import Foundation
import SwiftUI

// MARK: - Translation State

enum TranslationState: Equatable {
    case idle
    case recording(duration: TimeInterval, level: Float)
    case processing
    case translated(Translation)
    case playing
    case error(String)

    static func == (lhs: TranslationState, rhs: TranslationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.recording(let d1, let l1), .recording(let d2, let l2)):
            return d1 == d2 && l1 == l2
        case (.processing, .processing):
            return true
        case (.translated(let t1), .translated(let t2)):
            return t1 == t2
        case (.playing, .playing):
            return true
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

// MARK: - Translation ViewModel

@MainActor
@Observable
final class TranslationViewModel {

    // MARK: - Properties

    private(set) var state: TranslationState = .idle
    var sourceLanguage: Language = .en
    var targetLanguage: Language = .es
    var conversationId: String?

    // Usage info
    private(set) var dailyRemaining: Int = 10
    private(set) var dailyLimit: Int = 10
    private(set) var tier: SubscriptionTier = .free

    // History of translations in current session
    private(set) var translations: [Translation] = []

    // Error presentation
    var showError: Bool = false
    var errorMessage: String = ""

    // MARK: - Dependencies

    private let audioService: AudioServiceProtocol
    private let translationService: TranslationServiceProtocol

    // Private state
    private var levelMonitorTask: Task<Void, Never>?
    private var recordingTimer: Task<Void, Never>?

    // MARK: - Initialization

    init(
        audioService: AudioServiceProtocol? = nil,
        translationService: TranslationServiceProtocol? = nil
    ) {
        self.audioService = audioService ?? DependencyContainer.shared.resolve(AudioServiceProtocol.self)
        self.translationService = translationService ?? DependencyContainer.shared.resolve(TranslationServiceProtocol.self)
    }

    // MARK: - Public Methods

    /// Start recording audio
    func startRecording() async {
        guard case .idle = state else { return }

        do {
            try await audioService.startRecording()
            state = .recording(duration: 0, level: 0)

            // Start monitoring audio level
            startLevelMonitoring()

            // Start duration timer
            startRecordingTimer()

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        } catch let error as AudioError {
            handleError(error)
        } catch {
            handleError(AudioError.from(error))
        }
    }

    /// Stop recording and translate
    func stopRecording() async {
        guard case .recording = state else { return }

        // Stop monitoring
        levelMonitorTask?.cancel()
        recordingTimer?.cancel()

        do {
            let audioData = try await audioService.stopRecording()
            state = .processing

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Translate
            await translate(audio: audioData)

        } catch let error as AudioError {
            handleError(error)
        } catch {
            handleError(AudioError.from(error))
        }
    }

    /// Cancel recording without translating
    func cancelRecording() async {
        guard case .recording = state else { return }

        levelMonitorTask?.cancel()
        recordingTimer?.cancel()
        await audioService.cancelRecording()
        state = .idle

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Play the translated audio
    func playTranslation() async {
        guard case .translated(let translation) = state else { return }
        guard let url = translation.audioURL else { return }

        do {
            state = .playing
            try await audioService.playAudio(url: url)
            state = .translated(translation)

        } catch {
            state = .translated(translation)
            handleError(AudioError.playbackFailed(reason: error.localizedDescription))
        }
    }

    /// Stop audio playback
    func stopPlayback() async {
        guard case .playing = state else { return }

        await audioService.stopPlayback()

        // Restore previous translation state
        if let lastTranslation = translations.last {
            state = .translated(lastTranslation)
        } else {
            state = .idle
        }
    }

    /// Swap source and target languages
    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Reset to idle state
    func reset() {
        state = .idle
    }

    /// Load user preferences
    func loadPreferences() async {
        do {
            let prefs = try await translationService.getPreferences()

            if let sourceLang = prefs.defaultSourceLang,
               let source = Language(rawValue: sourceLang) {
                sourceLanguage = source
            }

            if let targetLang = prefs.defaultTargetLang,
               let target = Language(rawValue: targetLang) {
                targetLanguage = target
            }

        } catch {
            // Use defaults if preferences fail to load
        }
    }

    /// Load usage stats
    func loadUsage() async {
        do {
            let usage = try await translationService.getUsage()
            dailyRemaining = usage.current.dailyRemaining
            dailyLimit = usage.current.dailyLimit
            tier = SubscriptionTier(rawValue: usage.tier.name) ?? .free

        } catch {
            // Keep existing values
        }
    }

    // MARK: - Private Methods

    private func translate(audio: Data) async {
        do {
            let translation: Translation

            if let conversationId = conversationId {
                translation = try await translationService.translateInConversation(
                    conversationId: conversationId,
                    audio: audio,
                    from: sourceLanguage,
                    to: targetLanguage,
                    speaker: .user
                )
            } else {
                translation = try await translationService.translate(
                    audio: audio,
                    from: sourceLanguage,
                    to: targetLanguage,
                    speaker: .user
                )
            }

            // Update usage
            dailyRemaining = translation.usage.dailyRemaining
            dailyLimit = translation.usage.dailyLimit
            tier = translation.usage.tier

            // Add to history
            translations.append(translation)

            // Update state
            state = .translated(translation)

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch let error as NetworkError {
            handleError(error.toAppError())
        } catch {
            handleError(AppError.unknown(reason: error.localizedDescription))
        }
    }

    private func startLevelMonitoring() {
        levelMonitorTask = Task {
            for await level in await audioService.audioLevelStream() {
                guard case .recording(let duration, _) = state else { break }
                state = .recording(duration: duration, level: level)
            }
        }
    }

    private func startRecordingTimer() {
        recordingTimer = Task {
            var elapsed: TimeInterval = 0
            let interval: TimeInterval = 0.1

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                elapsed += interval

                guard case .recording(_, let level) = state else { break }
                state = .recording(duration: elapsed, level: level)

                // Auto-stop at max duration (60 seconds)
                if elapsed >= 60 {
                    await stopRecording()
                    break
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        let message: String

        if let appError = error as? AppError {
            message = appError.errorDescription ?? "An error occurred"
        } else if let audioError = error as? AudioError {
            message = audioError.errorDescription ?? "Audio error occurred"
        } else {
            message = error.localizedDescription
        }

        errorMessage = message
        showError = true
        state = .error(message)

        // Return to idle after delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .error = state {
                state = .idle
            }
        }
    }
}

// MARK: - Computed Properties

extension TranslationViewModel {

    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }

    var isProcessing: Bool {
        if case .processing = state { return true }
        return false
    }

    var isPlaying: Bool {
        if case .playing = state { return true }
        return false
    }

    var currentTranslation: Translation? {
        if case .translated(let t) = state { return t }
        if case .playing = state { return translations.last }
        return nil
    }

    var recordingDuration: TimeInterval {
        if case .recording(let duration, _) = state { return duration }
        return 0
    }

    var audioLevel: Float {
        if case .recording(_, let level) = state { return level }
        return 0
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var usagePercent: Double {
        guard dailyLimit > 0 else { return 0 }
        return Double(dailyLimit - dailyRemaining) / Double(dailyLimit)
    }

    var isNearingLimit: Bool {
        usagePercent > 0.8
    }

    var isAtLimit: Bool {
        dailyRemaining <= 0
    }

    var canRecord: Bool {
        !isAtLimit && (state == .idle || state == .translated(translations.last ?? Translation(
            id: "", originalText: "", translatedText: "",
            sourceLanguage: .en, targetLanguage: .es, audioUrl: "",
            confidence: 0, durationMs: 0, usage: TranslationUsage(dailyRemaining: 0, dailyLimit: 0, tier: .free)
        )))
    }
}
