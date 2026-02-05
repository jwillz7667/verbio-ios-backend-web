//
//  NetworkError.swift
//  Verbio
//
//  Network-specific error types
//

import Foundation

// MARK: - Network Error

/// Errors that can occur during network operations
enum NetworkError: LocalizedError, Equatable {

    // MARK: - Connection Errors

    case noConnection
    case timeout
    case connectionLost

    // MARK: - Request Errors

    case invalidURL
    case invalidRequest(reason: String)
    case encodingFailed(reason: String)

    // MARK: - Response Errors

    case invalidResponse
    case decodingFailed(reason: String)
    case emptyResponse

    // MARK: - HTTP Errors

    case badRequest(message: String?)           // 400
    case unauthorized                            // 401
    case forbidden                               // 403
    case notFound                                // 404
    case conflict(message: String?)              // 409
    case unprocessableEntity(message: String?)   // 422
    case tooManyRequests(retryAfter: Int?)       // 429
    case serverError(statusCode: Int)            // 5xx
    case httpError(statusCode: Int, message: String?)

    // MARK: - Other Errors

    case cancelled
    case unknown(reason: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."

        case .timeout:
            return "The request timed out. Please try again."

        case .connectionLost:
            return "The connection was lost. Please try again."

        case .invalidURL:
            return "Invalid URL."

        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"

        case .encodingFailed(let reason):
            return "Failed to encode request: \(reason)"

        case .invalidResponse:
            return "Received an invalid response from the server."

        case .decodingFailed(let reason):
            return "Failed to decode response: \(reason)"

        case .emptyResponse:
            return "The server returned an empty response."

        case .badRequest(let message):
            return message ?? "Bad request."

        case .unauthorized:
            return "You are not authorized. Please sign in again."

        case .forbidden:
            return "You don't have permission to perform this action."

        case .notFound:
            return "The requested resource was not found."

        case .conflict(let message):
            return message ?? "A conflict occurred with the current state."

        case .unprocessableEntity(let message):
            return message ?? "The request could not be processed."

        case .tooManyRequests(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please try again in \(seconds) seconds."
            }
            return "Too many requests. Please try again later."

        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."

        case .httpError(let statusCode, let message):
            return message ?? "HTTP error \(statusCode)"

        case .cancelled:
            return "The request was cancelled."

        case .unknown(let reason):
            return "Network error: \(reason)"
        }
    }

    var failureReason: String? {
        errorDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your Wi-Fi or cellular connection."

        case .timeout, .connectionLost:
            return "Please check your connection and try again."

        case .unauthorized:
            return "Please sign in again to continue."

        case .tooManyRequests:
            return "Please wait before making more requests."

        case .serverError:
            return "This is a temporary issue. Please try again later."

        default:
            return "Please try again."
        }
    }

    // MARK: - HTTP Status Code Factory

    static func from(statusCode: Int, message: String? = nil) -> NetworkError {
        switch statusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message: message)
        case 422:
            return .unprocessableEntity(message: message)
        case 429:
            return .tooManyRequests(retryAfter: nil)
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .httpError(statusCode: statusCode, message: message)
        }
    }

    // MARK: - URL Error Factory

    static func from(urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .badURL:
            return .invalidURL
        default:
            return .unknown(reason: urlError.localizedDescription)
        }
    }
}

// MARK: - Conversion to AppError

extension NetworkError {
    func toAppError() -> AppError {
        switch self {
        case .unauthorized:
            return .notAuthenticated

        case .forbidden:
            return .authenticationFailed(reason: "Access denied")

        default:
            return .unknown(reason: self.localizedDescription)
        }
    }
}
