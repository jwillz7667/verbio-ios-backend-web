//
//  AuthTokens.swift
//  Verbio
//
//  Authentication token models
//

import Foundation

// MARK: - Auth Tokens

struct AuthTokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String

    var expiresAt: Date {
        Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String = "Bearer"
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}

// MARK: - Auth Response

struct AuthResponse: Codable, Equatable, Sendable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    var tokens: AuthTokens {
        AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

// MARK: - Sign in with Apple Request

struct AppleAuthRequest: Codable, Sendable {
    let identityToken: String
    let authorizationCode: String
    let firstName: String?
    let lastName: String?
    let email: String?

    init(
        identityToken: String,
        authorizationCode: String,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil
    ) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}

// MARK: - Token Refresh Request

struct TokenRefreshRequest: Codable, Sendable {
    let refreshToken: String
}

// MARK: - Token Refresh Response

struct TokenRefreshResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    var tokens: AuthTokens {
        AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

// MARK: - JWT Claims (for local token inspection)

struct JWTClaims: Codable, Sendable {
    let sub: String        // User ID
    let email: String?
    let tier: String?      // Subscription tier
    let iat: Int           // Issued at
    let exp: Int           // Expires at

    var userId: String { sub }

    var expiresAt: Date {
        Date(timeIntervalSince1970: TimeInterval(exp))
    }

    var issuedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(iat))
    }

    var isExpired: Bool {
        expiresAt < Date()
    }

    var subscriptionTier: SubscriptionTier? {
        guard let tier = tier else { return nil }
        return SubscriptionTier(rawValue: tier)
    }
}

// MARK: - JWT Decoder (Basic - for local checks only)

enum JWTDecoder {
    /// Decode JWT claims without verification (for local checks only)
    /// Server should always verify tokens properly
    static func decode(_ token: String) -> JWTClaims? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }

        let payloadSegment = segments[1]

        // Add padding if needed
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64) else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(JWTClaims.self, from: data)
    }

    /// Check if a token is expired (with buffer time)
    static func isExpired(_ token: String, buffer: TimeInterval = 60) -> Bool {
        guard let claims = decode(token) else { return true }
        return claims.expiresAt.addingTimeInterval(-buffer) < Date()
    }
}
