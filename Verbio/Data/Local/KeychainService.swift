//
//  KeychainService.swift
//  Verbio
//
//  Secure token storage using iOS Keychain
//

import Foundation
import Security

// MARK: - Keychain Service Protocol

protocol KeychainServiceProtocol: Sendable {
    func save(_ data: Data, for key: KeychainKey) throws
    func load(for key: KeychainKey) throws -> Data?
    func delete(for key: KeychainKey) throws
    func clear() throws
}

// MARK: - Keychain Keys

enum KeychainKey: String, CaseIterable {
    case accessToken = "com.verbio.accessToken"
    case refreshToken = "com.verbio.refreshToken"
    case userId = "com.verbio.userId"
    case userEmail = "com.verbio.userEmail"

    var accessibility: CFString {
        switch self {
        case .accessToken, .refreshToken:
            // Available after first unlock, persists across reboots
            return kSecAttrAccessibleAfterFirstUnlock
        case .userId, .userEmail:
            // Available after first unlock
            return kSecAttrAccessibleAfterFirstUnlock
        }
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case dataConversionFailed
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .dataConversionFailed:
            return "Failed to convert data"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        }
    }
}

// MARK: - Keychain Service Implementation

final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let service: String
    private let accessGroup: String?
    private let lock = NSLock()

    // MARK: - Initialization

    init(
        service: String = AppConfiguration.shared.keychainService,
        accessGroup: String? = AppConfiguration.shared.keychainAccessGroup
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Public Methods

    func save(_ data: Data, for key: KeychainKey) throws {
        lock.lock()
        defer { lock.unlock() }

        // Delete existing item first
        try? deleteInternal(for: key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = key.accessibility

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    func load(for key: KeychainKey) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            return data

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainError.loadFailed(status: status)
        }
    }

    func delete(for key: KeychainKey) throws {
        lock.lock()
        defer { lock.unlock() }
        try deleteInternal(for: key)
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }

        for key in KeychainKey.allCases {
            try? deleteInternal(for: key)
        }
    }

    // MARK: - Private Methods

    private func baseQuery(for key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    private func deleteInternal(for key: KeychainKey) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainServiceProtocol {
    /// Save a string value
    func save(_ string: String, for key: KeychainKey) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        try save(data, for: key)
    }

    /// Load a string value
    func loadString(for key: KeychainKey) throws -> String? {
        guard let data = try load(for: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    /// Save a Codable value
    func save<T: Encodable>(_ value: T, for key: KeychainKey) throws {
        let data = try JSONEncoder().encode(value)
        try save(data, for: key)
    }

    /// Load a Codable value
    func load<T: Decodable>(_ type: T.Type, for key: KeychainKey) throws -> T? {
        guard let data = try load(for: key) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }
}
