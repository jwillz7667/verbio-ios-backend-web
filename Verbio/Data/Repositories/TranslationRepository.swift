//
//  TranslationRepository.swift
//  Verbio
//
//  Repository for translation API calls
//

import Foundation

// MARK: - Translation Repository Protocol

protocol TranslationRepositoryProtocol: Sendable {
    /// Translate audio to target language
    func translate(
        audio: Data,
        sourceLanguage: Language?,
        targetLanguage: Language,
        conversationId: String?,
        voiceId: String?,
        speaker: Speaker
    ) async throws -> Translation

    /// Get user's voice preferences
    func getPreferences() async throws -> VoicePreferencesDTO

    /// Update user's voice preferences
    func updatePreferences(_ preferences: VoicePreferencesDTO) async throws -> VoicePreferencesDTO

    /// Get usage statistics
    func getUsageStats(days: Int) async throws -> UsageStatsResponse
}

// MARK: - Translation Repository Implementation

final class TranslationRepository: TranslationRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClientProtocol

    // MARK: - Initialization

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Translation

    func translate(
        audio: Data,
        sourceLanguage: Language?,
        targetLanguage: Language,
        conversationId: String?,
        voiceId: String?,
        speaker: Speaker
    ) async throws -> Translation {
        // Encode audio to base64
        let base64Audio = audio.base64EncodedString()

        let request = TranslateRequest(
            audio: base64Audio,
            sourceLanguage: sourceLanguage?.rawValue,
            targetLanguage: targetLanguage.rawValue,
            conversationId: conversationId,
            voiceId: voiceId,
            speaker: speaker.rawValue
        )

        let response = try await networkClient.request(
            endpoint: TranslationEndpoint.translate,
            body: request,
            responseType: TranslateResponse.self
        )

        return response.toDomain()
    }

    // MARK: - Preferences

    func getPreferences() async throws -> VoicePreferencesDTO {
        let response = try await networkClient.request(
            endpoint: UserEndpoint.preferences,
            body: nil as EmptyBody?,
            responseType: VoicePreferencesResponse.self
        )

        return response.preferences
    }

    func updatePreferences(_ preferences: VoicePreferencesDTO) async throws -> VoicePreferencesDTO {
        let response = try await networkClient.request(
            endpoint: UserEndpoint.updatePreferences,
            body: preferences,
            responseType: VoicePreferencesResponse.self
        )

        return response.preferences
    }

    // MARK: - Usage Stats

    func getUsageStats(days: Int = 30) async throws -> UsageStatsResponse {
        // Note: Query params would be added to the endpoint
        let response = try await networkClient.request(
            endpoint: UserEndpoint.usage,
            body: nil as EmptyBody?,
            responseType: UsageStatsResponse.self
        )

        return response
    }
}

// MARK: - Empty Body

private struct EmptyBody: Encodable {}
