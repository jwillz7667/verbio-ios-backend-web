//
//  UserRepository.swift
//  Verbio
//
//  Repository for user profile API calls
//

import Foundation

// MARK: - User Repository Protocol

protocol UserRepositoryProtocol: Sendable {
    func getProfile() async throws -> User
    func updateProfile(firstName: String?, lastName: String?) async throws -> User
}

// MARK: - User Repository Implementation

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClientProtocol

    // MARK: - Initialization

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Get Profile

    func getProfile() async throws -> User {
        struct UserResponse: Decodable {
            let user: User
        }

        let response = try await networkClient.request(
            endpoint: UserEndpoint.profile,
            body: nil as EmptyBody?,
            responseType: UserResponse.self
        )
        return response.user
    }

    // MARK: - Update Profile

    func updateProfile(firstName: String?, lastName: String?) async throws -> User {
        struct UpdateRequest: Encodable {
            let firstName: String?
            let lastName: String?
        }

        struct UserResponse: Decodable {
            let user: User
        }

        let request = UpdateRequest(firstName: firstName, lastName: lastName)
        let response = try await networkClient.request(
            endpoint: UserEndpoint.updateProfile,
            body: request,
            responseType: UserResponse.self
        )
        return response.user
    }
}

// MARK: - Empty Types

private struct EmptyBody: Encodable {}
