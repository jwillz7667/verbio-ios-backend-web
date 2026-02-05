//
//  Translation.swift
//  Verbio
//
//  Translation result model
//

import Foundation

// MARK: - Translation

struct Translation: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let audioUrl: String
    let confidence: Double
    let durationMs: Int
    let usage: TranslationUsage

    // MARK: - Computed Properties

    /// Duration formatted as mm:ss
    var formattedDuration: String {
        let seconds = durationMs / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// Audio URL as URL type
    var audioURL: URL? {
        URL(string: audioUrl)
    }

    /// Confidence percentage (0-100)
    var confidencePercent: Int {
        Int(confidence * 100)
    }
}

// MARK: - Translation Usage

struct TranslationUsage: Codable, Sendable, Equatable {
    let dailyRemaining: Int
    let dailyLimit: Int
    let tier: SubscriptionTier

    /// Percentage of daily limit used
    var usagePercent: Double {
        guard dailyLimit > 0 else { return 0 }
        let used = dailyLimit - dailyRemaining
        return Double(used) / Double(dailyLimit)
    }

    /// Whether user is approaching limit (>80% used)
    var isNearingLimit: Bool {
        usagePercent > 0.8
    }

    /// Whether user has exceeded limit
    var isAtLimit: Bool {
        dailyRemaining <= 0
    }
}

// MARK: - Speaker

enum Speaker: String, Codable, Sendable, Equatable {
    case user = "USER"
    case other = "OTHER"
}
