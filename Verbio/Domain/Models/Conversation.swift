//
//  Conversation.swift
//  Verbio
//
//  Conversation model for grouped translations
//

import Foundation

// MARK: - Conversation

struct Conversation: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let userId: String
    let title: String?
    let sourceLanguage: Language
    let targetLanguage: Language
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    var messages: [Message]?

    // MARK: - Computed Properties

    /// Display title (uses auto-generated title if none set)
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return "\(sourceLanguage.flag) → \(targetLanguage.flag) Conversation"
    }

    /// Formatted creation date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Message count
    var messageCount: Int {
        messages?.count ?? 0
    }

    /// Last message preview
    var lastMessagePreview: String? {
        messages?.last?.originalText
    }

    /// Whether conversation was created today
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    /// Relative time string (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Message

struct Message: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let conversationId: String
    let speaker: Speaker
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let originalAudioUrl: String?
    let translatedAudioUrl: String?
    let durationMs: Int?
    let confidence: Double?
    let createdAt: Date

    // MARK: - Computed Properties

    /// Whether this message has translated audio available
    var hasAudio: Bool {
        translatedAudioUrl != nil
    }

    /// Audio URL as URL type
    var audioURL: URL? {
        guard let urlString = translatedAudioUrl else { return nil }
        return URL(string: urlString)
    }

    /// Formatted duration
    var formattedDuration: String? {
        guard let ms = durationMs else { return nil }
        let seconds = ms / 1000
        return "\(seconds)s"
    }

    /// Confidence percentage
    var confidencePercent: Int? {
        guard let conf = confidence else { return nil }
        return Int(conf * 100)
    }

    /// Whether the message is from the user
    var isFromUser: Bool {
        speaker == .user
    }
}

// MARK: - Conversation List Response

struct ConversationListResponse: Codable, Sendable {
    let conversations: [Conversation]
}

// MARK: - Conversation Response

struct ConversationResponse: Codable, Sendable {
    let conversation: Conversation
}

// MARK: - Messages Response

struct MessagesResponse: Codable, Sendable {
    let messages: [Message]
    let total: Int
}
