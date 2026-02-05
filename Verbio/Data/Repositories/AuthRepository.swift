//
//  AuthRepository.swift
//  Verbio
//
//  Repository for authentication API operations
//

import Foundation

// MARK: - Auth Repository Protocol

protocol AuthRepositoryProtocol: Sendable {
    func signInWithApple(request: AppleAuthRequest) async throws -> AuthResponse
    func refreshToken(refreshToken: String) async throws -> TokenRefreshResponse
    func logout() async throws
}

// MARK: - Auth Repository Implementation

final class AuthRepository: AuthRepositoryProtocol, Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClientProtocol
    private let keychainService: KeychainServiceProtocol

    // MARK: - Initialization

    init(
        networkClient: NetworkClientProtocol,
        keychainService: KeychainServiceProtocol
    ) {
        self.networkClient = networkClient
        self.keychainService = keychainService
    }

    // MARK: - Sign in with Apple

    func signInWithApple(request: AppleAuthRequest) async throws -> AuthResponse {
        let response = try await networkClient.request(
            endpoint: AuthEndpoint.signInWithApple,
            body: request,
            responseType: AuthResponse.self
        )

        // Store tokens securely
        try keychainService.save(response.accessToken, for: .accessToken)
        try keychainService.save(response.refreshToken, for: .refreshToken)
        try keychainService.save(response.user.id, for: .userId)

        if let email = response.user.email.nilIfEmpty {
            try keychainService.save(email, for: .userEmail)
        }

        return response
    }

    // MARK: - Token Refresh

    func refreshToken(refreshToken: String) async throws -> TokenRefreshResponse {
        let request = TokenRefreshRequest(refreshToken: refreshToken)

        let response = try await networkClient.request(
            endpoint: AuthEndpoint.refreshToken,
            body: request,
            responseType: TokenRefreshResponse.self
        )

        // Update stored tokens
        try keychainService.save(response.accessToken, for: .accessToken)
        try keychainService.save(response.refreshToken, for: .refreshToken)

        return response
    }

    // MARK: - Logout

    func logout() async throws {
        // Call server to invalidate refresh token
        do {
            try await networkClient.request(endpoint: AuthEndpoint.logout)
        } catch {
            // Continue with local cleanup even if server call fails
            print("Server logout failed: \(error.localizedDescription)")
        }

        // Clear local tokens
        try keychainService.clear()
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
