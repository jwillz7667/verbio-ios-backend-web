//
//  PhrasesRepository.swift
//  Verbio
//
//  Repository for saved phrases API calls
//

import Foundation

// MARK: - Phrases Repository Protocol

protocol PhrasesRepositoryProtocol: Sendable {
    func getPhrases(limit: Int, offset: Int, favoritesOnly: Bool, search: String?) async throws -> SavedPhraseListResponse
    func createPhrase(_ request: SavedPhraseCreateRequest) async throws -> SavedPhrase
    func updatePhrase(id: String, request: SavedPhraseUpdateRequest) async throws -> SavedPhrase
    func deletePhrase(id: String) async throws
}

// MARK: - Phrases Repository Implementation

final class PhrasesRepository: PhrasesRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClientProtocol

    // MARK: - Initialization

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Get Phrases

    func getPhrases(limit: Int = 50, offset: Int = 0, favoritesOnly: Bool = false, search: String? = nil) async throws -> SavedPhraseListResponse {
        let response = try await networkClient.request(
            endpoint: PhrasesEndpoint.list(limit: limit, offset: offset, favoritesOnly: favoritesOnly, search: search),
            body: nil as EmptyBody?,
            responseType: SavedPhraseListResponse.self
        )
        return response
    }

    // MARK: - Create Phrase

    func createPhrase(_ request: SavedPhraseCreateRequest) async throws -> SavedPhrase {
        let response = try await networkClient.request(
            endpoint: PhrasesEndpoint.create,
            body: request,
            responseType: SavedPhraseResponse.self
        )
        return response.phrase
    }

    // MARK: - Update Phrase

    func updatePhrase(id: String, request: SavedPhraseUpdateRequest) async throws -> SavedPhrase {
        let response = try await networkClient.request(
            endpoint: PhrasesEndpoint.update(id: id),
            body: request,
            responseType: SavedPhraseResponse.self
        )
        return response.phrase
    }

    // MARK: - Delete Phrase

    func deletePhrase(id: String) async throws {
        try await networkClient.request(
            endpoint: PhrasesEndpoint.delete(id: id),
            body: nil as EmptyBody?
        )
    }
}

// MARK: - Empty Types

private struct EmptyBody: Encodable {}
