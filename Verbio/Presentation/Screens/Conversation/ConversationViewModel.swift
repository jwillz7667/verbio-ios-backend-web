//
//  ConversationViewModel.swift
//  Verbio
//
//  ViewModel for active conversation screen
//

import Foundation
import SwiftUI

// MARK: - Conversation State

enum ConversationState: Equatable {
    case loading
    case ready
    case recording(speaker: Speaker, duration: TimeInterval, level: Float)
    case processing(speaker: Speaker)
    case playing(messageId: String)
    case error(String)

    static func == (lhs: ConversationState, rhs: ConversationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.ready, .ready):
            return true
        case (.recording(let s1, let d1, let l1), .recording(let s2, let d2, let l2)):
            return s1 == s2 && d1 == d2 && l1 == l2
        case (.processing(let s1), .processing(let s2)):
            return s1 == s2
        case (.playing(let id1), .playing(let id2)):
            return id1 == id2
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

// MARK: - Conversation ViewModel

@MainActor
@Observable
final class ConversationViewModel {

    // MARK: - Properties

    private(set) var state: ConversationState = .loading
    private(set) var conversation: Conversation?
    private(set) var messages: [Message] = []
    var activeSpeaker: Speaker = .user

    // Usage info
    private(set) var dailyRemaining: Int = 10
    private(set) var dailyLimit: Int = 10

    // Error presentation
    var showError: Bool = false
    var errorMessage: String = ""

    // MARK: - Dependencies

    private let conversationId: String
    private let conversationService: ConversationServiceProtocol
    private let audioService: AudioServiceProtocol

    // Private state
    private var levelMonitorTask: Task<Void, Never>?
    private var recordingTimer: Task<Void, Never>?

    // MARK: - Initialization

    init(
        conversationId: String,
        conversationService: ConversationServiceProtocol? = nil,
        audioService: AudioServiceProtocol? = nil
    ) {
        self.conversationId = conversationId
        self.conversationService = conversationService ?? DependencyContainer.shared.resolve(ConversationServiceProtocol.self)
        self.audioService = audioService ?? DependencyContainer.shared.resolve(AudioServiceProtocol.self)
    }

    // MARK: - Public Methods

    /// Load conversation and messages
    func loadConversation() async {
        state = .loading

        do {
            let conv = try await conversationService.getConversation(id: conversationId)
            conversation = conv

            let response = try await conversationService.getMessages(
                conversationId: conversationId,
                limit: 100,
                offset: 0
            )
            messages = response.messages
            state = .ready
        } catch {
            handleError(error)
        }
    }

    /// Start recording audio for the active speaker
    func startRecording() async {
        guard state == .ready else { return }

        do {
            try await audioService.startRecording()
            state = .recording(speaker: activeSpeaker, duration: 0, level: 0)

            startLevelMonitoring()
            startRecordingTimer()

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
        guard case .recording(let speaker, _, _) = state else { return }

        levelMonitorTask?.cancel()
        recordingTimer?.cancel()

        do {
            let audioData = try await audioService.stopRecording()
            state = .processing(speaker: speaker)

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            guard let conv = conversation else { return }

            // Translate within conversation context
            let translation = try await conversationService.translateInConversation(
                conversationId: conversationId,
                audio: audioData,
                sourceLanguage: speaker == .user ? conv.sourceLanguage : conv.targetLanguage,
                targetLanguage: speaker == .user ? conv.targetLanguage : conv.sourceLanguage,
                speaker: speaker
            )

            // Update usage
            dailyRemaining = translation.usage.dailyRemaining
            dailyLimit = translation.usage.dailyLimit

            // Re-fetch messages for server-generated IDs/timestamps
            let response = try await conversationService.getMessages(
                conversationId: conversationId,
                limit: 100,
                offset: 0
            )
            messages = response.messages
            state = .ready

        } catch let error as AudioError {
            handleError(error)
        } catch let error as NetworkError {
            handleError(error.toAppError())
        } catch {
            handleError(AppError.unknown(reason: error.localizedDescription))
        }
    }

    /// Cancel the current recording
    func cancelRecording() async {
        guard case .recording = state else { return }

        levelMonitorTask?.cancel()
        recordingTimer?.cancel()
        await audioService.cancelRecording()
        state = .ready

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Toggle the active speaker
    func toggleSpeaker() {
        guard !isRecording && !isProcessing else { return }
        activeSpeaker = activeSpeaker == .user ? .other : .user

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Play translated audio for a message
    func playMessage(_ message: Message) async {
        guard let url = message.audioURL else { return }

        do {
            state = .playing(messageId: message.id)
            try await audioService.playAudio(url: url)
            state = .ready
        } catch {
            state = .ready
        }
    }

    /// Stop audio playback
    func stopPlayback() async {
        await audioService.stopPlayback()
        state = .ready
    }

    // MARK: - Private Methods

    private func startLevelMonitoring() {
        levelMonitorTask = Task {
            for await level in await audioService.audioLevelStream() {
                guard case .recording(let speaker, let duration, _) = state else { break }
                state = .recording(speaker: speaker, duration: duration, level: level)
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

                guard case .recording(let speaker, _, let level) = state else { break }
                state = .recording(speaker: speaker, duration: elapsed, level: level)

                // Auto-stop at 60 seconds
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

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .error = state {
                state = .ready
            }
        }
    }
}

// MARK: - Computed Properties

extension ConversationViewModel {

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

    var playingMessageId: String? {
        if case .playing(let id) = state { return id }
        return nil
    }

    var audioLevel: Float {
        if case .recording(_, _, let level) = state { return level }
        return 0
    }

    var recordingDuration: TimeInterval {
        if case .recording(_, let duration, _) = state { return duration }
        return 0
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var canRecord: Bool {
        state == .ready && dailyRemaining > 0
    }

    var isAtLimit: Bool {
        dailyRemaining <= 0
    }
}
