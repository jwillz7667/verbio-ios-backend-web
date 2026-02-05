//
//  HomeViewModel.swift
//  Verbio
//
//  ViewModel for the Home screen
//

import Foundation

// MARK: - Home View Model

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - State

    enum State: Equatable {
        case loading
        case loaded
        case error(String)
    }

    private(set) var state: State = .loading
    private(set) var user: User?
    private(set) var usage: UserUsage?

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var displayName: String {
        user?.displayName ?? "User"
    }

    var subscriptionTier: SubscriptionTier {
        user?.subscriptionTier ?? .free
    }

    var minutesRemaining: String {
        guard let usage = usage else { return "--" }
        return String(format: "%.1f", usage.minutesRemaining)
    }

    var usagePercentage: Double {
        usage?.usagePercentage ?? 0
    }

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(
        authService: AuthServiceProtocol? = nil
    ) {
        self.authService = authService ?? DependencyContainer.shared.resolve(AuthServiceProtocol.self)
    }

    // MARK: - Actions

    func loadData() async {
        state = .loading

        // Get current user from auth service
        user = await authService.currentUser

        // In a full implementation, we'd fetch usage data from the API
        // For Phase 1, we'll use mock data
        usage = UserUsage(
            currentPeriodStart: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            currentPeriodEnd: Date().addingTimeInterval(23 * 24 * 60 * 60),
            minutesUsed: 3.5,
            minutesLimit: user?.subscriptionTier.monthlyMinutes ?? 10,
            translationsCount: 12,
            conversationsCount: 3
        )

        state = .loaded
    }

    func logout() async throws {
        try await authService.logout()
    }
}
