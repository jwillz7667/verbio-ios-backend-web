//
//  SignInViewModel.swift
//  Verbio
//
//  ViewModel for the Sign In screen
//

import Foundation
import AuthenticationServices

// MARK: - Sign In View Model

@MainActor
@Observable
final class SignInViewModel {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case authenticated(User)
        case error(String)
    }

    private(set) var state: State = .idle

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = state { return message }
        return nil
    }

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let appleSignInCoordinator: AppleSignInCoordinator

    // MARK: - Initialization

    init(
        authService: AuthServiceProtocol? = nil
    ) {
        self.authService = authService ?? DependencyContainer.shared.resolve(AuthServiceProtocol.self)
        self.appleSignInCoordinator = AppleSignInCoordinator()
    }

    // MARK: - Actions

    func signInWithApple() async {
        state = .loading

        do {
            // Get Apple credential
            let credential = try await appleSignInCoordinator.signIn()

            // Authenticate with backend
            let user = try await authService.signInWithApple(credential: credential)

            state = .authenticated(user)
        } catch let error as AppError {
            switch error {
            case .operationCancelled:
                state = .idle
            default:
                state = .error(error.localizedDescription)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func checkExistingAuth() async {
        state = .loading

        let isAuthenticated = await authService.checkAuthStatus()

        if isAuthenticated {
            if let user = await authService.currentUser {
                state = .authenticated(user)
            } else {
                // Authenticated but no user data - fetch it
                // For Phase 1, we'll just set to idle and require sign-in
                state = .idle
            }
        } else {
            state = .idle
        }
    }

    func dismissError() {
        if case .error = state {
            state = .idle
        }
    }
}
