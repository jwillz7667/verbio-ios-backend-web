//
//  ConversationDetailViewModel.swift
//  Verbio
//
//  ViewModel for the Conversation Detail screen
//

import Foundation

// MARK: - Conversation Detail View Model

@MainActor
@Observable
final class ConversationDetailViewModel {

    // MARK: - State

    private(set) var conversation: Conversation?
    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    var showError = false
    var errorMessage = ""

    var conversationTitle: String {
        conversation?.displayTitle ?? "Conversation"
    }

    var sourceLanguageFlag: String {
        conversation?.sourceLanguage.flag ?? ""
    }

    var targetLanguageFlag: String {
        conversation?.targetLanguage.flag ?? ""
    }

    // MARK: - Properties

    private let conversationId: String
    private let conversationRepository: ConversationRepositoryProtocol
    private let phrasesRepository: PhrasesRepositoryProtocol
    private let audioService: AudioServiceProtocol

    // MARK: - Initialization

    init(
        conversationId: String,
        conversationRepository: ConversationRepositoryProtocol? = nil,
        phrasesRepository: PhrasesRepositoryProtocol? = nil,
        audioService: AudioServiceProtocol? = nil
    ) {
        self.conversationId = conversationId
        self.conversationRepository = conversationRepository ?? DependencyContainer.shared.resolve(ConversationRepositoryProtocol.self)
        self.phrasesRepository = phrasesRepository ?? DependencyContainer.shared.resolve(PhrasesRepositoryProtocol.self)
        self.audioService = audioService ?? DependencyContainer.shared.resolve(AudioServiceProtocol.self)
    }

    // MARK: - Actions

    func loadConversation() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let convo = try await conversationRepository.getConversation(id: conversationId)
            conversation = convo
            messages = convo.messages ?? []
        } catch {
            errorMessage = "Failed to load conversation"
            showError = true
        }
    }

    func savePhrase(from message: Message) async {
        let request = SavedPhraseCreateRequest(
            originalText: message.originalText,
            translatedText: message.translatedText,
            sourceLanguage: message.sourceLanguage.rawValue,
            targetLanguage: message.targetLanguage.rawValue,
            isFavorite: nil
        )

        do {
            _ = try await phrasesRepository.createPhrase(request)
        } catch {
            errorMessage = "Failed to save phrase"
            showError = true
        }
    }

    func playMessageAudio(_ message: Message) async {
        guard let url = message.audioURL else { return }

        do {
            try await audioService.playAudio(url: url)
        } catch {
            errorMessage = "Failed to play audio"
            showError = true
        }
    }
}
