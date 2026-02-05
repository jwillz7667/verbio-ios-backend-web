//
//  APIEndpoints.swift
//  Verbio
//
//  API endpoint definitions
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoint Protocol

protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var requiresAuth: Bool { get }
}

extension APIEndpoint {
    var headers: [String: String]? { nil }
    var requiresAuth: Bool { true }
}

// MARK: - Auth Endpoints

enum AuthEndpoint: APIEndpoint {
    case signInWithApple
    case refreshToken
    case logout

    var path: String {
        switch self {
        case .signInWithApple:
            return "/api/auth/apple"
        case .refreshToken:
            return "/api/auth/refresh"
        case .logout:
            return "/api/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .signInWithApple, .refreshToken, .logout:
            return .post
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .signInWithApple, .refreshToken:
            return false
        case .logout:
            return true
        }
    }
}

// MARK: - User Endpoints

enum UserEndpoint: APIEndpoint {
    case profile
    case updateProfile
    case preferences
    case updatePreferences
    case usage

    var path: String {
        switch self {
        case .profile:
            return "/api/user"
        case .updateProfile:
            return "/api/user"
        case .preferences:
            return "/api/user/preferences"
        case .updatePreferences:
            return "/api/user/preferences"
        case .usage:
            return "/api/user/usage"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile, .preferences, .usage:
            return .get
        case .updateProfile, .updatePreferences:
            return .patch
        }
    }
}

// MARK: - Health Endpoint

enum HealthEndpoint: APIEndpoint {
    case health

    var path: String {
        "/api/health"
    }

    var method: HTTPMethod {
        .get
    }

    var requiresAuth: Bool {
        false
    }
}

// MARK: - Translation Endpoints (Phase 2+)

enum TranslationEndpoint: APIEndpoint {
    case translate

    var path: String {
        switch self {
        case .translate:
            return "/api/translate"
        }
    }

    var method: HTTPMethod {
        .post
    }
}

// MARK: - Conversation Endpoints (Phase 2+)

enum ConversationEndpoint: APIEndpoint {
    case list
    case create
    case get(id: String)
    case update(id: String)
    case delete(id: String)
    case messages(id: String)

    var path: String {
        switch self {
        case .list, .create:
            return "/api/conversations"
        case .get(let id), .update(let id), .delete(let id):
            return "/api/conversations/\(id)"
        case .messages(let id):
            return "/api/conversations/\(id)/messages"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .get, .messages:
            return .get
        case .create:
            return .post
        case .update:
            return .patch
        case .delete:
            return .delete
        }
    }
}
