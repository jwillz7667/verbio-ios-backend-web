//
//  AppError.swift
//  Verbio
//
//  Base error types for the application
//

import Foundation

// MARK: - App Error

/// Base error type for all application errors
enum AppError: LocalizedError, Equatable {

    // MARK: - Authentication Errors

    case notAuthenticated
    case authenticationFailed(reason: String)
    case tokenExpired
    case tokenRefreshFailed
    case signInWithAppleFailed(reason: String)

    // MARK: - Validation Errors

    case validationFailed(field: String, reason: String)
    case invalidInput(reason: String)

    // MARK: - Storage Errors

    case keychainError(reason: String)
    case dataCorrupted

    // MARK: - General Errors

    case unknown(reason: String)
    case operationCancelled

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in. Please sign in to continue."

        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"

        case .tokenExpired:
            return "Your session has expired. Please sign in again."

        case .tokenRefreshFailed:
            return "Unable to refresh your session. Please sign in again."

        case .signInWithAppleFailed(let reason):
            return "Sign in with Apple failed: \(reason)"

        case .validationFailed(let field, let reason):
            return "Invalid \(field): \(reason)"

        case .invalidInput(let reason):
            return "Invalid input: \(reason)"

        case .keychainError(let reason):
            return "Secure storage error: \(reason)"

        case .dataCorrupted:
            return "Data appears to be corrupted."

        case .unknown(let reason):
            return "An unexpected error occurred: \(reason)"

        case .operationCancelled:
            return "The operation was cancelled."
        }
    }

    var failureReason: String? {
        errorDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated, .tokenExpired, .tokenRefreshFailed, .authenticationFailed:
            return "Please try signing in again."

        case .signInWithAppleFailed:
            return "Please try again or use a different sign-in method."

        case .validationFailed, .invalidInput:
            return "Please check your input and try again."

        case .keychainError, .dataCorrupted:
            return "Please try again. If the problem persists, reinstall the app."

        case .unknown:
            return "Please try again later."

        case .operationCancelled:
            return nil
        }
    }
}

// MARK: - Error Conversion

extension AppError {
    /// Create an AppError from any Error
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        return .unknown(reason: error.localizedDescription)
    }
}
