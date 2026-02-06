//
//  PaywallViewModel.swift
//  Verbio
//
//  ViewModel for the subscription paywall
//

import Foundation

// MARK: - Paywall State

enum PaywallState: Sendable {
    case loading
    case loaded
    case purchasing
    case error(String)
}

// MARK: - Paywall ViewModel

@MainActor
@Observable
final class PaywallViewModel {

    // MARK: - Properties

    var state: PaywallState = .loading
    var products: [SubscriptionProduct] = []
    var selectedPeriod: SubscriptionPeriod = .yearly
    var selectedTier: SubscriptionTier = .pro
    var purchaseComplete = false
    var errorMessage = ""
    var showError = false

    private let storeKitService: StoreKitServiceProtocol

    // MARK: - Initialization

    init(storeKitService: StoreKitServiceProtocol? = nil) {
        self.storeKitService = storeKitService ?? DependencyContainer.shared.resolve(StoreKitServiceProtocol.self)
    }

    // MARK: - Computed Properties

    var proProduct: SubscriptionProduct? {
        products.first { $0.tier == .pro && $0.period == selectedPeriod }
    }

    var premiumProduct: SubscriptionProduct? {
        products.first { $0.tier == .premium && $0.period == selectedPeriod }
    }

    var selectedProduct: SubscriptionProduct? {
        products.first { $0.tier == selectedTier && $0.period == selectedPeriod }
    }

    var ctaText: String {
        guard let product = selectedProduct else { return "Subscribe" }

        if selectedPeriod == .yearly, let offer = product.introductoryOffer {
            return "Start \(offer.displayText)"
        }
        return "Subscribe for \(product.displayPrice)/\(selectedPeriod == .monthly ? "mo" : "yr")"
    }

    var yearlySavingsText: String? {
        guard let monthlyPro = products.first(where: { $0.tier == selectedTier && $0.period == .monthly }),
              let yearlyPro = products.first(where: { $0.tier == selectedTier && $0.period == .yearly }) else {
            return nil
        }

        let monthlyCost = monthlyPro.price * 12
        let yearlyCost = yearlyPro.price
        guard monthlyCost > yearlyCost else { return nil }

        let savings = monthlyCost - yearlyCost
        let percentage = (savings / monthlyCost) * 100
        return "Save \(Int(truncating: percentage as NSDecimalNumber))%"
    }

    // MARK: - Actions

    func loadProducts() async {
        state = .loading
        do {
            products = try await storeKitService.loadProducts()
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func purchase() async {
        guard let product = selectedProduct else { return }

        state = .purchasing
        do {
            let result = try await storeKitService.purchase(product.id)
            switch result {
            case .success:
                purchaseComplete = true
                state = .loaded
            case .pending:
                errorMessage = "Purchase is pending approval."
                showError = true
                state = .loaded
            case .cancelled:
                state = .loaded
            case .failed(let reason):
                errorMessage = reason
                showError = true
                state = .loaded
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            state = .loaded
        }
    }

    func restorePurchases() async {
        state = .purchasing
        do {
            try await storeKitService.restorePurchases()
            let tier = await storeKitService.currentTier
            if tier != .free {
                purchaseComplete = true
            } else {
                errorMessage = "No active subscriptions found."
                showError = true
            }
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            state = .loaded
        }
    }
}
