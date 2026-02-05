//
//  AppConfiguration.swift
//  Verbio
//
//  Environment configuration for the application
//

import Foundation

// MARK: - Environment

enum AppEnvironment: String {
    case development
    case staging
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000"
        case .staging:
            return "https://staging-api.verbio.app"
        case .production:
            return "https://api.verbio.app"
        }
    }

    var isDebug: Bool {
        self == .development
    }
}

// MARK: - App Configuration

final class AppConfiguration: Sendable {

    // MARK: - Singleton

    static let shared = AppConfiguration()

    // MARK: - Properties

    let environment: AppEnvironment
    let apiBaseURL: URL
    let appBundleId: String
    let appVersion: String
    let buildNumber: String

    // MARK: - API Configuration

    let apiTimeout: TimeInterval = 30
    let uploadTimeout: TimeInterval = 120
    let maxRetries: Int = 3

    // MARK: - Token Configuration

    let accessTokenExpiryBuffer: TimeInterval = 60 // Refresh 60s before expiry

    // MARK: - Keychain Configuration

    let keychainService: String = "com.verbio.app"
    let keychainAccessGroup: String? = nil // Set if using shared keychain

    // MARK: - Sign in with Apple

    let appleTeamId: String = "487LC4H9U4"
    let appleServiceId: String = "com.verbio.app"

    // MARK: - Feature Flags

    var enableAnalytics: Bool {
        environment != .development
    }

    var enableCrashReporting: Bool {
        environment != .development
    }

    // MARK: - Initialization

    private init() {
        #if DEBUG
        self.environment = .development
        #else
        self.environment = .production
        #endif

        guard let url = URL(string: environment.baseURL) else {
            fatalError("Invalid base URL for environment: \(environment)")
        }
        self.apiBaseURL = url

        self.appBundleId = Bundle.main.bundleIdentifier ?? "com.verbio.app"
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - URL Building

    func apiURL(for path: String) -> URL {
        apiBaseURL.appendingPathComponent(path)
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension AppConfiguration {
    /// Override base URL for testing
    static func setTestBaseURL(_ urlString: String) {
        // For testing purposes - would need to modify the implementation
        // to support mutable configuration in tests
    }
}
#endif
