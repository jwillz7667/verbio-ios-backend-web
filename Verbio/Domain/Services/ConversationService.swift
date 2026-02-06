//
//  ConversationService.swift
//  Verbio
//
//  Conversation orchestration service
//

import Foundation

// MARK: - Conversation Service Protocol

protocol ConversationServiceProtocol: Sendable {
    /// Get list of user's conversations
    func listConversations() async throws -> [Conversation]

    /// Create a new conversation
    func createConversation(
        title: String?,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> Conversation

    /// Get a specific conversation with messages
    func getConversation(id: String) async throws -> Conversation

    /// Get messages for a conversation
    func getMessages(conversationId: String, limit: Int, offset: Int) async throws -> MessagesResponse

    /// Delete a conversation
    func deleteConversation(id: String) async throws

    /// Update a conversation title
    func updateConversation(id: String, title: String?) async throws -> Conversation

    /// Translate audio within a conversation context
    func translateInConversation(
        conversationId: String,
        audio: Data,
        sourceLanguage: Language?,
        targetLanguage: Language,
        speaker: Speaker
    ) async throws -> Translation
}

// MARK: - Conversation Service Implementation

actor ConversationService: ConversationServiceProtocol {

    // MARK: - Properties

    private let conversationRepository: ConversationRepositoryProtocol
    private let translationService: TranslationServiceProtocol

    // MARK: - Initialization

    init(
        conversationRepository: ConversationRepositoryProtocol,
        translationService: TranslationServiceProtocol
    ) {
        self.conversationRepository = conversationRepository
        self.translationService = translationService
    }

    // MARK: - Conversations

    func listConversations() async throws -> [Conversation] {
        try await conversationRepository.getConversations(limit: 50, offset: 0, activeOnly: nil)
    }

    func createConversation(
        title: String?,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> Conversation {
        try await conversationRepository.createConversation(
            title: title,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }

    func getConversation(id: String) async throws -> Conversation {
        try await conversationRepository.getConversation(id: id)
    }

    func getMessages(conversationId: String, limit: Int = 50, offset: Int = 0) async throws -> MessagesResponse {
        try await conversationRepository.getMessages(
            conversationId: conversationId,
            limit: limit,
            offset: offset
        )
    }

    func deleteConversation(id: String) async throws {
        try await conversationRepository.deleteConversation(id: id)
    }

    func updateConversation(id: String, title: String?) async throws -> Conversation {
        try await conversationRepository.updateConversation(id: id, title: title, isActive: nil)
    }

    // MARK: - Translation

    func translateInConversation(
        conversationId: String,
        audio: Data,
        sourceLanguage: Language?,
        targetLanguage: Language,
        speaker: Speaker
    ) async throws -> Translation {
        try await translationService.translateInConversation(
            conversationId: conversationId,
            audio: audio,
            from: sourceLanguage,
            to: targetLanguage,
            speaker: speaker
        )
    }
}
