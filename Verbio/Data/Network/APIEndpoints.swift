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
            return "/api/user/profile"
        case .updateProfile:
            return "/api/user/profile"
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
        case .updateProfile:
            return .patch
        case .updatePreferences:
            return .put
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

// MARK: - Phrases Endpoints

enum PhrasesEndpoint: APIEndpoint {
    case list(limit: Int, offset: Int, favoritesOnly: Bool, search: String?)
    case create
    case get(id: String)
    case update(id: String)
    case delete(id: String)

    var path: String {
        switch self {
        case .list(let limit, let offset, let favoritesOnly, let search):
            var queryItems = "?limit=\(limit)&offset=\(offset)"
            if favoritesOnly {
                queryItems += "&favorites=true"
            }
            if let search = search, !search.isEmpty {
                let encoded = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search
                queryItems += "&search=\(encoded)"
            }
            return "/api/phrases\(queryItems)"
        case .create:
            return "/api/phrases"
        case .get(let id), .update(let id), .delete(let id):
            return "/api/phrases/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .get:
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

// MARK: - Conversation Endpoints

enum ConversationEndpoint: APIEndpoint {
    case list
    case create
    case get(id: String)
    case update(id: String)
    case delete(id: String)
    case messages(conversationId: String)

    var path: String {
        switch self {
        case .list, .create:
            return "/api/conversations"
        case .get(let id), .update(let id), .delete(let id):
            return "/api/conversations/\(id)"
        case .messages(let conversationId):
            return "/api/conversations/\(conversationId)/messages"
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
