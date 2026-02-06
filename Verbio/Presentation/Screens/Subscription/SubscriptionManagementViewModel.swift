//
//  SubscriptionManagementViewModel.swift
//  Verbio
//
//  ViewModel for subscription management in Settings
//

import Foundation

// MARK: - Subscription Management ViewModel

@MainActor
@Observable
final class SubscriptionManagementViewModel {

    // MARK: - Properties

    var activeSubscription: ActiveSubscription?
    var currentTier: SubscriptionTier = .free
    var isLoading = true
    var showPaywall = false
    var errorMessage = ""
    var showError = false

    private let storeKitService: StoreKitServiceProtocol

    // MARK: - Initialization

    init(storeKitService: StoreKitServiceProtocol? = nil) {
        self.storeKitService = storeKitService ?? DependencyContainer.shared.resolve(StoreKitServiceProtocol.self)
    }

    // MARK: - Computed Properties

    var isSubscribed: Bool {
        currentTier != .free
    }

    var tierIcon: String {
        switch currentTier {
        case .free: return "person.fill"
        case .pro: return "crown.fill"
        case .premium: return "crown.fill"
        }
    }

    var expirationText: String {
        guard let sub = activeSubscription, let date = sub.expirationDate else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Renews \(formatter.string(from: date))"
    }

    var trialText: String? {
        guard let sub = activeSubscription, sub.isInTrial else { return nil }
        guard let date = sub.expirationDate else { return "Free trial active" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return "Free trial ends \(relative)"
    }

    var renewalText: String {
        guard let sub = activeSubscription else { return "" }
        if !sub.willAutoRenew {
            return "Subscription expires on renewal date"
        }
        return expirationText
    }

    var statusText: String {
        if let trialText = trialText {
            return trialText
        }
        if isSubscribed {
            return renewalText
        }
        return "No active subscription"
    }

    // MARK: - Actions

    func loadSubscription() async {
        isLoading = true
        currentTier = await storeKitService.currentTier
        activeSubscription = await storeKitService.activeSubscription
        isLoading = false
    }

    func manageSubscription() async {
        do {
            try await storeKitService.showManageSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
