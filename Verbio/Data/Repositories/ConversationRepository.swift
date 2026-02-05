//
//  ConversationRepository.swift
//  Verbio
//
//  Repository for conversation API calls
//

import Foundation

// MARK: - Conversation Repository Protocol

protocol ConversationRepositoryProtocol: Sendable {
    /// Get list of user's conversations
    func getConversations(limit: Int, offset: Int, activeOnly: Bool?) async throws -> [Conversation]

    /// Create a new conversation
    func createConversation(
        title: String?,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> Conversation

    /// Get a specific conversation with messages
    func getConversation(id: String) async throws -> Conversation

    /// Delete a conversation
    func deleteConversation(id: String) async throws

    /// Update a conversation
    func updateConversation(id: String, title: String?, isActive: Bool?) async throws -> Conversation

    /// Get messages for a conversation
    func getMessages(conversationId: String, limit: Int, offset: Int) async throws -> MessagesResponse
}

// MARK: - Conversation Repository Implementation

final class ConversationRepository: ConversationRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClientProtocol

    // MARK: - Initialization

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - List Conversations

    func getConversations(limit: Int = 20, offset: Int = 0, activeOnly: Bool? = nil) async throws -> [Conversation] {
        let response = try await networkClient.request(
            endpoint: ConversationEndpoint.list,
            body: nil as EmptyBody?,
            responseType: ConversationListResponse.self
        )

        return response.conversations
    }

    // MARK: - Create Conversation

    func createConversation(
        title: String?,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> Conversation {
        let request = ConversationCreateRequest(
            title: title,
            sourceLanguage: sourceLanguage.rawValue,
            targetLanguage: targetLanguage.rawValue
        )

        let response = try await networkClient.request(
            endpoint: ConversationEndpoint.create,
            body: request,
            responseType: ConversationResponse.self
        )

        return response.conversation
    }

    // MARK: - Get Conversation

    func getConversation(id: String) async throws -> Conversation {
        let response = try await networkClient.request(
            endpoint: ConversationEndpoint.get(id: id),
            body: nil as EmptyBody?,
            responseType: ConversationResponse.self
        )

        return response.conversation
    }

    // MARK: - Delete Conversation

    func deleteConversation(id: String) async throws {
        try await networkClient.request(
            endpoint: ConversationEndpoint.delete(id: id),
            body: nil as EmptyBody?
        )
    }

    // MARK: - Update Conversation

    func updateConversation(id: String, title: String?, isActive: Bool?) async throws -> Conversation {
        struct UpdateRequest: Encodable {
            let title: String?
            let isActive: Bool?
        }

        let request = UpdateRequest(title: title, isActive: isActive)

        let response = try await networkClient.request(
            endpoint: ConversationEndpoint.update(id: id),
            body: request,
            responseType: ConversationResponse.self
        )

        return response.conversation
    }

    // MARK: - Get Messages

    func getMessages(conversationId: String, limit: Int = 50, offset: Int = 0) async throws -> MessagesResponse {
        let response = try await networkClient.request(
            endpoint: ConversationEndpoint.messages(conversationId: conversationId),
            body: nil as EmptyBody?,
            responseType: MessagesResponse.self
        )

        return response
    }
}

// MARK: - Empty Types

private struct EmptyBody: Encodable {}

private struct EmptyResponse: Decodable {}
