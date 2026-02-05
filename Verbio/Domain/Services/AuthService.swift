//
//  AuthService.swift
//  Verbio
//
//  Sign in with Apple authentication service
//

import Foundation
import AuthenticationServices

// MARK: - Auth Service Protocol

protocol AuthServiceProtocol: Sendable {
    var isAuthenticated: Bool { get async }
    var currentUser: User? { get async }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func checkAuthStatus() async -> Bool
    func logout() async throws
}

// MARK: - Auth Service Implementation

actor AuthService: AuthServiceProtocol {

    // MARK: - Properties

    private let authRepository: AuthRepositoryProtocol
    private let keychainService: KeychainServiceProtocol

    private var _currentUser: User?
    private var _isAuthenticated: Bool = false

    // MARK: - Public Properties

    var isAuthenticated: Bool {
        _isAuthenticated
    }

    var currentUser: User? {
        _currentUser
    }

    // MARK: - Initialization

    init(
        authRepository: AuthRepositoryProtocol,
        keychainService: KeychainServiceProtocol
    ) {
        self.authRepository = authRepository
        self.keychainService = keychainService
    }

    // MARK: - Sign in with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        // Extract identity token
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AppError.signInWithAppleFailed(reason: "Missing identity token")
        }

        // Extract authorization code
        guard let authCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authCodeData, encoding: .utf8) else {
            throw AppError.signInWithAppleFailed(reason: "Missing authorization code")
        }

        // Extract user info (only available on first sign-in)
        let firstName = credential.fullName?.givenName
        let lastName = credential.fullName?.familyName
        let email = credential.email

        // Create auth request
        let request = AppleAuthRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            firstName: firstName,
            lastName: lastName,
            email: email
        )

        // Authenticate with backend
        let response = try await authRepository.signInWithApple(request: request)

        // Update local state
        _currentUser = response.user
        _isAuthenticated = true

        return response.user
    }

    // MARK: - Check Auth Status

    func checkAuthStatus() async -> Bool {
        // Check if we have stored tokens
        guard let accessToken = try? keychainService.loadString(for: .accessToken),
              let _ = try? keychainService.loadString(for: .refreshToken) else {
            _isAuthenticated = false
            _currentUser = nil
            return false
        }

        // Check if access token is expired
        if JWTDecoder.isExpired(accessToken, buffer: AppConfiguration.shared.accessTokenExpiryBuffer) {
            // Token is expired, but we have a refresh token
            // The NetworkClient will handle the refresh automatically
            // For now, consider the user authenticated
        }

        // Extract user info from token
        if let claims = JWTDecoder.decode(accessToken) {
            // We're authenticated but need to fetch full user data
            _isAuthenticated = true

            // Note: In a full implementation, we'd fetch the user profile here
            // For now, we'll just set authenticated state
        }

        _isAuthenticated = true
        return true
    }

    // MARK: - Logout

    func logout() async throws {
        try await authRepository.logout()
        _currentUser = nil
        _isAuthenticated = false
    }
}

// MARK: - Sign in with Apple Coordinator

@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    // MARK: - Properties

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    // MARK: - Public Methods

    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Invalid credential type"))
                continuation = nil
                return
            }

            continuation?.resume(returning: appleIDCredential)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    continuation?.resume(throwing: AppError.operationCancelled)
                case .failed:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Authorization failed"))
                case .invalidResponse:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Invalid response"))
                case .notHandled:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Request not handled"))
                case .unknown:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Unknown error"))
                case .notInteractive:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Not interactive"))
                case .matchedExcludedCredential:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: "Credential excluded"))
                @unknown default:
                    continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: error.localizedDescription))
                }
            } else {
                continuation?.resume(throwing: AppError.signInWithAppleFailed(reason: error.localizedDescription))
            }
            continuation = nil
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Sign in with Apple presentation")
        }
        return window
    }
}
