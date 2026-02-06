//
//  StoreKitService.swift
//  Verbio
//
//  StoreKit 2 service protocol
//

import Foundation

// MARK: - StoreKit Service Protocol

protocol StoreKitServiceProtocol: Sendable {
    /// The current active subscription, if any
    var activeSubscription: ActiveSubscription? { get async }

    /// The current subscription tier based on entitlements
    var currentTier: SubscriptionTier { get async }

    /// Load available subscription products from the App Store
    func loadProducts() async throws -> [SubscriptionProduct]

    /// Purchase a subscription product
    func purchase(_ productId: String) async throws -> PurchaseResult

    /// Restore previous purchases
    func restorePurchases() async throws

    /// Check if the user is eligible for an introductory offer on a product
    func isEligibleForIntroOffer(productId: String) async -> Bool

    /// Start listening for transaction updates (call on app launch)
    func startTransactionListener() async

    /// Show the system subscription management UI
    func showManageSubscriptions() async throws
}
