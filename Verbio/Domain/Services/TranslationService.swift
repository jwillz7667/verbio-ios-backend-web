//
//  TranslationService.swift
//  Verbio
//
//  Translation orchestration service
//

import Foundation

// MARK: - Translation Service Protocol

protocol TranslationServiceProtocol: Sendable {
    /// Translate audio to target language
    func translate(
        audio: Data,
        from sourceLanguage: Language?,
        to targetLanguage: Language,
        speaker: Speaker
    ) async throws -> Translation

    /// Translate audio within a conversation context
    func translateInConversation(
        conversationId: String,
        audio: Data,
        from sourceLanguage: Language?,
        to targetLanguage: Language,
        speaker: Speaker
    ) async throws -> Translation

    /// Get current usage stats
    func getUsage() async throws -> UsageStatsResponse

    /// Get user's voice preferences
    func getPreferences() async throws -> VoicePreferencesDTO

    /// Update user's voice preferences
    func updatePreferences(_ preferences: VoicePreferencesDTO) async throws -> VoicePreferencesDTO
}

// MARK: - Translation Service Implementation

actor TranslationService: TranslationServiceProtocol {

    // MARK: - Properties

    private let translationRepository: TranslationRepositoryProtocol
    private let audioService: AudioServiceProtocol

    // Cache for preferences
    private var cachedPreferences: VoicePreferencesDTO?

    // MARK: - Initialization

    init(
        translationRepository: TranslationRepositoryProtocol,
        audioService: AudioServiceProtocol
    ) {
        self.translationRepository = translationRepository
        self.audioService = audioService
    }

    // MARK: - Translation

    func translate(
        audio: Data,
        from sourceLanguage: Language?,
        to targetLanguage: Language,
        speaker: Speaker = .user
    ) async throws -> Translation {
        // Get preferred voice if available
        let voiceId = await getPreferredVoiceId()

        return try await translationRepository.translate(
            audio: audio,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            conversationId: nil,
            voiceId: voiceId,
            speaker: speaker
        )
    }

    func translateInConversation(
        conversationId: String,
        audio: Data,
        from sourceLanguage: Language?,
        to targetLanguage: Language,
        speaker: Speaker = .user
    ) async throws -> Translation {
        let voiceId = await getPreferredVoiceId()

        return try await translationRepository.translate(
            audio: audio,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            conversationId: conversationId,
            voiceId: voiceId,
            speaker: speaker
        )
    }

    // MARK: - Usage

    func getUsage() async throws -> UsageStatsResponse {
        try await translationRepository.getUsageStats(days: 30)
    }

    // MARK: - Preferences

    func getPreferences() async throws -> VoicePreferencesDTO {
        // Return cached if available
        if let cached = cachedPreferences {
            return cached
        }

        let preferences = try await translationRepository.getPreferences()
        cachedPreferences = preferences
        return preferences
    }

    func updatePreferences(_ preferences: VoicePreferencesDTO) async throws -> VoicePreferencesDTO {
        let updated = try await translationRepository.updatePreferences(preferences)
        cachedPreferences = updated
        return updated
    }

    // MARK: - Private Helpers

    private func getPreferredVoiceId() async -> String? {
        // Try to get from cache first
        if let cached = cachedPreferences {
            return cached.preferredVoiceId
        }

        // Try to fetch preferences (don't fail if this fails)
        do {
            let prefs = try await getPreferences()
            return prefs.preferredVoiceId
        } catch {
            return nil
        }
    }

    /// Clear preferences cache (call when user logs out)
    func clearCache() {
        cachedPreferences = nil
    }
}
