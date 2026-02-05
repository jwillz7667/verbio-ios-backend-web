//
//  TranslationDTO.swift
//  Verbio
//
//  Data transfer objects for translation API
//

import Foundation

// MARK: - Translation Request

struct TranslateRequest: Encodable, Sendable {
    let audio: String           // Base64 encoded WAV
    let sourceLanguage: String? // Optional, auto-detect if nil
    let targetLanguage: String  // Required
    let conversationId: String? // For context
    let voiceId: String?        // Override default voice
    let speaker: String         // "USER" or "OTHER"

    enum CodingKeys: String, CodingKey {
        case audio
        case sourceLanguage = "sourceLanguage"
        case targetLanguage = "targetLanguage"
        case conversationId = "conversationId"
        case voiceId = "voiceId"
        case speaker
    }
}

// MARK: - Translation Response

struct TranslateResponse: Decodable, Sendable {
    let id: String
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let audioUrl: String
    let confidence: Double
    let durationMs: Int
    let usage: UsageDTO

    struct UsageDTO: Decodable, Sendable {
        let dailyRemaining: Int
        let dailyLimit: Int
        let tier: String
    }
}

// MARK: - Conversation Create Request

struct ConversationCreateRequest: Encodable, Sendable {
    let title: String?
    let sourceLanguage: String
    let targetLanguage: String
}

// MARK: - Voice Preferences

struct VoicePreferencesDTO: Codable, Sendable {
    let preferredVoiceId: String?
    let voiceName: String?
    let speechRate: Double?
    let defaultSourceLang: String?
    let defaultTargetLang: String?
    let autoDetectSource: Bool?
}

struct VoicePreferencesResponse: Decodable, Sendable {
    let preferences: VoicePreferencesDTO
}

// MARK: - Usage Stats

struct UsageStatsResponse: Decodable, Sendable {
    let current: CurrentUsage
    let total: TotalUsage
    let tier: TierInfo
    let history: [UsageHistory]

    struct CurrentUsage: Decodable, Sendable {
        let dailyTranslations: Int
        let dailyLimit: Int
        let dailyRemaining: Int
        let resetAt: Date
    }

    struct TotalUsage: Decodable, Sendable {
        let translations: Int
        let audioMinutes: Double
        let ttsCharacters: Int
        let estimatedCost: Double
    }

    struct TierInfo: Decodable, Sendable {
        let name: String
        let limits: TierLimits
    }

    struct TierLimits: Decodable, Sendable {
        let dailyTranslations: Int
        let audioMinutes: Int
        let ttsCharacters: Int
    }

    struct UsageHistory: Decodable, Sendable {
        let date: Date
        let translations: Int
        let audioMinutes: Double
        let ttsCharacters: Int
        let estimatedCost: Double
    }
}

// MARK: - DTO to Domain Mapping

extension TranslateResponse {
    func toDomain() -> Translation {
        Translation(
            id: id,
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: Language(rawValue: sourceLanguage) ?? .en,
            targetLanguage: Language(rawValue: targetLanguage) ?? .es,
            audioUrl: audioUrl,
            confidence: confidence,
            durationMs: durationMs,
            usage: TranslationUsage(
                dailyRemaining: usage.dailyRemaining,
                dailyLimit: usage.dailyLimit,
                tier: SubscriptionTier(rawValue: usage.tier) ?? .free
            )
        )
    }
}
