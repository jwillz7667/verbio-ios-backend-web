//
//  SavedPhrase.swift
//  Verbio
//
//  Saved phrase domain model
//

import Foundation

// MARK: - Saved Phrase

struct SavedPhrase: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let userId: String
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    var isFavorite: Bool
    let usageCount: Int
    let lastUsedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    var languagePairDisplay: String {
        "\(sourceLanguage.flag) \(sourceLanguage.displayName) → \(targetLanguage.flag) \(targetLanguage.displayName)"
    }

    var shortLanguagePair: String {
        "\(sourceLanguage.flag) → \(targetLanguage.flag)"
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Response Types

struct SavedPhraseResponse: Codable, Sendable {
    let phrase: SavedPhrase
}

struct SavedPhraseListResponse: Codable, Sendable {
    let phrases: [SavedPhrase]
    let total: Int
}

// MARK: - Request Types

struct SavedPhraseCreateRequest: Encodable, Sendable {
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let isFavorite: Bool?
}

struct SavedPhraseUpdateRequest: Encodable, Sendable {
    let isFavorite: Bool?
    let translatedText: String?
}
