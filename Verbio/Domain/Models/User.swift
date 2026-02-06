//
//  User.swift
//  Verbio
//
//  User domain model
//

import Foundation

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free = "FREE"
    case pro = "PRO"
    case premium = "PREMIUM"

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .pro:
            return "Pro"
        case .premium:
            return "Premium"
        }
    }

    var monthlyMinutes: Int {
        switch self {
        case .free:
            return 10
        case .pro:
            return 300
        case .premium:
            return Int.max
        }
    }

    var dailyLimit: Int {
        switch self {
        case .free:
            return 10
        case .pro:
            return 200
        case .premium:
            return Int.max
        }
    }

    var hasConversationMode: Bool {
        self != .free
    }

    var hasPhraseSaving: Bool {
        self != .free
    }

    var hasPremiumVoices: Bool {
        self != .free
    }

    var hasOfflineMode: Bool {
        self == .premium
    }

    var hasPriorityProcessing: Bool {
        self == .premium
    }
}

// MARK: - User Model

struct User: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let appleUserId: String
    let email: String
    let firstName: String?
    let lastName: String?
    let subscriptionTier: SubscriptionTier
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty {
            if let lastName = lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return email.components(separatedBy: "@").first ?? "User"
    }

    var initials: String {
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    var isPremium: Bool {
        subscriptionTier != .free
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Equatable, Sendable {
    var preferredSourceLanguage: String?
    var preferredTargetLanguage: String?
    var preferredVoiceId: String?
    var autoPlayTranslation: Bool
    var hapticFeedbackEnabled: Bool
    var saveConversationHistory: Bool

    static let `default` = UserPreferences(
        preferredSourceLanguage: "en",
        preferredTargetLanguage: "es",
        preferredVoiceId: nil,
        autoPlayTranslation: true,
        hapticFeedbackEnabled: true,
        saveConversationHistory: true
    )
}

// MARK: - User Usage

struct UserUsage: Codable, Equatable, Sendable {
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let minutesUsed: Double
    let minutesLimit: Int
    let translationsCount: Int
    let conversationsCount: Int

    var minutesRemaining: Double {
        max(0, Double(minutesLimit) - minutesUsed)
    }

    var usagePercentage: Double {
        guard minutesLimit > 0 else { return 0 }
        return min(1.0, minutesUsed / Double(minutesLimit))
    }

    var isAtLimit: Bool {
        minutesRemaining <= 0
    }
}
