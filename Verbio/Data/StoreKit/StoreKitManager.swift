//
//  StoreKitManager.swift
//  Verbio
//
//  StoreKit 2 implementation for subscription management
//

import Foundation
import StoreKit
import UIKit

// MARK: - StoreKit Error

enum StoreKitError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case verificationFailed
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested product could not be found."
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .verificationFailed:
            return "Transaction verification failed."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - StoreKit Manager

actor StoreKitManager: StoreKitServiceProtocol {

    // MARK: - Properties

    private var products: [String: Product] = [:]
    private var _activeSubscription: ActiveSubscription?
    private var _currentTier: SubscriptionTier = .free
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Protocol Computed Properties

    var activeSubscription: ActiveSubscription? {
        _activeSubscription
    }

    var currentTier: SubscriptionTier {
        _currentTier
    }

    // MARK: - Load Products

    func loadProducts() async throws -> [SubscriptionProduct] {
        // Return cached products if available
        if !products.isEmpty {
            return mapProducts(Array(products.values))
        }

        do {
            let storeProducts = try await Product.products(for: SubscriptionProductID.all)

            for product in storeProducts {
                products[product.id] = product
            }

            return mapProducts(storeProducts)
        } catch {
            throw StoreKitError.networkError
        }
    }

    // MARK: - Purchase

    func purchase(_ productId: String) async throws -> PurchaseResult {
        guard let product = products[productId] else {
            // Try loading products first
            _ = try await loadProducts()
            guard let product = products[productId] else {
                throw StoreKitError.productNotFound
            }
            return try await executePurchase(product)
        }

        return try await executePurchase(product)
    }

    private func executePurchase(_ product: Product) async throws -> PurchaseResult {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                return .success(_currentTier)

            case .pending:
                return .pending

            case .userCancelled:
                return .cancelled

            @unknown default:
                throw StoreKitError.unknown
            }
        } catch StoreKitError.verificationFailed {
            throw StoreKitError.verificationFailed
        } catch {
            throw StoreKitError.purchaseFailed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Introductory Offer Eligibility

    func isEligibleForIntroOffer(productId: String) async -> Bool {
        guard let product = products[productId],
              let subscription = product.subscription else {
            return false
        }

        return await subscription.isEligibleForIntroOffer
    }

    // MARK: - Transaction Listener

    func startTransactionListener() async {
        // Check current entitlements on launch
        await updateSubscriptionStatus()

        // Listen for future transaction updates
        transactionListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                do {
                    let transaction = try await self.checkVerification(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    // Verification failed, ignore this transaction
                }
            }
        }
    }

    // MARK: - Manage Subscriptions

    @MainActor
    func showManageSubscriptions() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        try await AppStore.showManageSubscriptions(in: windowScene)
    }

    // MARK: - Private Helpers

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    private func updateSubscriptionStatus() async {
        var latestTier: SubscriptionTier = .free
        var latestSubscription: ActiveSubscription?
        var latestExpirationDate: Date = .distantPast

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productType == .autoRenewable else { continue }

            // Only consider non-revoked, non-expired transactions
            if let revocationDate = transaction.revocationDate, revocationDate < Date() {
                continue
            }

            let tier = SubscriptionProductID.tier(for: transaction.productID)
            let period = SubscriptionProductID.period(for: transaction.productID)
            let expirationDate = transaction.expirationDate

            // Check if this is a trial
            let isInTrial: Bool
            if let offer = transaction.offer {
                isInTrial = offer.type == .introductory
            } else {
                isInTrial = false
            }

            // Pick the highest-tier, latest-expiring subscription
            let rank = self.tierRank(tier)
            let currentRank = self.tierRank(latestTier)

            if rank > currentRank || (rank == currentRank && (expirationDate ?? .distantFuture) > latestExpirationDate) {
                latestTier = tier
                latestExpirationDate = expirationDate ?? .distantFuture

                // Check auto-renew status
                let statuses = try? await products[transaction.productID]?.subscription?.status
                var willAutoRenew = true
                if let renewalInfo = statuses?.first?.renewalInfo {
                    if case .verified(let info) = renewalInfo {
                        willAutoRenew = info.willAutoRenew
                    }
                }

                latestSubscription = ActiveSubscription(
                    productId: transaction.productID,
                    tier: tier,
                    period: period,
                    expirationDate: expirationDate,
                    isInTrial: isInTrial,
                    willAutoRenew: willAutoRenew
                )
            }
        }

        _currentTier = latestTier
        _activeSubscription = latestSubscription
    }

    private func tierRank(_ tier: SubscriptionTier) -> Int {
        switch tier {
        case .free: return 0
        case .pro: return 1
        case .premium: return 2
        }
    }

    private func mapProducts(_ storeProducts: [Product]) -> [SubscriptionProduct] {
        storeProducts.compactMap { product -> SubscriptionProduct? in
            guard SubscriptionProductID.all.contains(product.id) else { return nil }

            let tier = SubscriptionProductID.tier(for: product.id)
            let period = SubscriptionProductID.period(for: product.id)

            // Map introductory offer
            var introOffer: IntroductoryOffer?
            if let offer = product.subscription?.introductoryOffer {
                let periodUnit: String
                switch offer.period.unit {
                case .day: periodUnit = "day"
                case .week: periodUnit = "week"
                case .month: periodUnit = "month"
                case .year: periodUnit = "year"
                @unknown default: periodUnit = "period"
                }

                introOffer = IntroductoryOffer(
                    displayPrice: offer.displayPrice,
                    periodCount: offer.period.value,
                    periodUnit: periodUnit
                )
            }

            return SubscriptionProduct(
                id: product.id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                price: product.price,
                tier: tier,
                period: period,
                introductoryOffer: introOffer
            )
        }
        .sorted { lhs, rhs in
            let lhsRank = tierRank(lhs.tier)
            let rhsRank = tierRank(rhs.tier)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.period == .monthly
        }
    }
}
