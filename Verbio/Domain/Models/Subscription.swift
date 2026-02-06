//
//  Subscription.swift
//  Verbio
//
//  Domain models for StoreKit 2 subscriptions
//

import Foundation

// MARK: - Subscription Period

nonisolated enum SubscriptionPeriod: String, Sendable, CaseIterable {
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Subscription Product

struct SubscriptionProduct: Identifiable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
    let price: Decimal
    let tier: SubscriptionTier
    let period: SubscriptionPeriod
    let introductoryOffer: IntroductoryOffer?
}

// MARK: - Introductory Offer

struct IntroductoryOffer: Sendable {
    let displayPrice: String
    let periodCount: Int
    let periodUnit: String

    var displayText: String {
        if displayPrice == "$0.00" || displayPrice == "Free" {
            return "\(periodCount)-\(periodUnit) free trial"
        }
        return "\(displayPrice) for \(periodCount) \(periodUnit)"
    }
}

// MARK: - Active Subscription

struct ActiveSubscription: Sendable {
    let productId: String
    let tier: SubscriptionTier
    let period: SubscriptionPeriod
    let expirationDate: Date?
    let isInTrial: Bool
    let willAutoRenew: Bool

    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }
}

// MARK: - Purchase Result

enum PurchaseResult: Sendable {
    case success(SubscriptionTier)
    case pending
    case cancelled
    case failed(String)
}

// MARK: - Subscription Product IDs

nonisolated enum SubscriptionProductID: Sendable {
    static let proMonthly = "com.verbio.app.pro.monthly"
    static let proYearly = "com.verbio.app.pro.yearly"
    static let premiumMonthly = "com.verbio.app.premium.monthly"
    static let premiumYearly = "com.verbio.app.premium.yearly"

    static let all: Set<String> = [
        proMonthly, proYearly, premiumMonthly, premiumYearly
    ]

    static func tier(for productId: String) -> SubscriptionTier {
        switch productId {
        case proMonthly, proYearly:
            return .pro
        case premiumMonthly, premiumYearly:
            return .premium
        default:
            return .free
        }
    }

    static func period(for productId: String) -> SubscriptionPeriod {
        switch productId {
        case proMonthly, premiumMonthly:
            return .monthly
        case proYearly, premiumYearly:
            return .yearly
        default:
            return .monthly
        }
    }
}

// MARK: - Tier Features

struct TierFeatures: Sendable {
    let tier: SubscriptionTier
    let features: [Feature]

    struct Feature: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let included: Bool
    }

    static let free = TierFeatures(tier: .free, features: [
        Feature(name: "10 translations/day", included: true),
        Feature(name: "10 min/month", included: true),
        Feature(name: "Basic voices", included: true),
        Feature(name: "Conversation mode", included: false),
        Feature(name: "Phrase saving", included: false),
        Feature(name: "Premium voices", included: false),
        Feature(name: "Offline mode", included: false),
        Feature(name: "Priority processing", included: false),
    ])

    static let pro = TierFeatures(tier: .pro, features: [
        Feature(name: "200 translations/day", included: true),
        Feature(name: "300 min/month", included: true),
        Feature(name: "Premium voices", included: true),
        Feature(name: "Conversation mode", included: true),
        Feature(name: "Phrase saving", included: true),
        Feature(name: "Offline mode", included: false),
        Feature(name: "Priority processing", included: false),
    ])

    static let premium = TierFeatures(tier: .premium, features: [
        Feature(name: "Unlimited translations", included: true),
        Feature(name: "Unlimited minutes", included: true),
        Feature(name: "All voices", included: true),
        Feature(name: "Conversation mode", included: true),
        Feature(name: "Phrase saving", included: true),
        Feature(name: "Offline mode", included: true),
        Feature(name: "Priority processing", included: true),
    ])
}
