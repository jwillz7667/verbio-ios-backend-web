//
//  SavedPhrasesViewModel.swift
//  Verbio
//
//  ViewModel for the Saved Phrases screen
//

import Foundation

// MARK: - Saved Phrases View Model

@MainActor
@Observable
final class SavedPhrasesViewModel {

    // MARK: - State

    private(set) var phrases: [SavedPhrase] = []
    private(set) var isLoading = false
    var showError = false
    var errorMessage = ""
    var searchText = ""
    var showFavoritesOnly = false

    // MARK: - Dependencies

    private let phrasesRepository: PhrasesRepositoryProtocol

    // MARK: - Debounce

    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        phrasesRepository: PhrasesRepositoryProtocol? = nil
    ) {
        self.phrasesRepository = phrasesRepository ?? DependencyContainer.shared.resolve(PhrasesRepositoryProtocol.self)
    }

    // MARK: - Actions

    func loadPhrases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await phrasesRepository.getPhrases(
                limit: 100,
                offset: 0,
                favoritesOnly: showFavoritesOnly,
                search: searchText.isEmpty ? nil : searchText
            )
            phrases = response.phrases
        } catch {
            errorMessage = "Failed to load phrases"
            showError = true
        }
    }

    func searchPhrases() async {
        searchTask?.cancel()

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            await loadPhrases()
        }
    }

    func toggleFavorite(_ phrase: SavedPhrase) async {
        let request = SavedPhraseUpdateRequest(
            isFavorite: !phrase.isFavorite,
            translatedText: nil
        )

        do {
            let updated = try await phrasesRepository.updatePhrase(id: phrase.id, request: request)
            if let index = phrases.firstIndex(where: { $0.id == phrase.id }) {
                phrases[index] = updated
            }
        } catch {
            errorMessage = "Failed to update phrase"
            showError = true
        }
    }

    func deletePhrase(id: String) async {
        do {
            try await phrasesRepository.deletePhrase(id: id)
            phrases.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete phrase"
            showError = true
        }
    }
}
