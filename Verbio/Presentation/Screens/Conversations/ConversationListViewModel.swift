//
//  ConversationListViewModel.swift
//  Verbio
//
//  ViewModel for the Conversation List screen
//

import Foundation

// MARK: - Conversation List View Model

@MainActor
@Observable
final class ConversationListViewModel {

    // MARK: - State

    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false
    var showError = false
    var errorMessage = ""

    // MARK: - Dependencies

    private let conversationRepository: ConversationRepositoryProtocol

    // MARK: - Initialization

    init(
        conversationRepository: ConversationRepositoryProtocol? = nil
    ) {
        self.conversationRepository = conversationRepository ?? DependencyContainer.shared.resolve(ConversationRepositoryProtocol.self)
    }

    // MARK: - Actions

    func loadConversations() async {
        isLoading = true
        defer { isLoading = false }

        do {
            conversations = try await conversationRepository.getConversations(limit: 50, offset: 0, activeOnly: nil)
        } catch {
            errorMessage = "Failed to load conversations"
            showError = true
        }
    }

    func deleteConversation(id: String) async {
        do {
            try await conversationRepository.deleteConversation(id: id)
            conversations.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete conversation"
            showError = true
        }
    }
}
