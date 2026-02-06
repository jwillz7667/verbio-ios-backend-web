//
//  SettingsViewModel.swift
//  Verbio
//
//  ViewModel for the Settings screen
//

import Foundation

// MARK: - Settings View Model

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - State

    private(set) var isLoading = false
    var showError = false
    var errorMessage = ""
    var showLogoutConfirmation = false

    // Profile
    private(set) var displayName = "User"
    private(set) var email = ""
    private(set) var userInitials = "U"
    private(set) var tierDisplayName = "Free"

    // Language preferences
    var sourceLanguage: Language = .en
    var targetLanguage: Language = .es
    var autoDetectSource = true

    // Voice preferences
    var speechRate: Double = 1.0
    var autoPlayTranslation = true

    // General preferences
    var hapticFeedbackEnabled = true
    var saveConversationHistory = true

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let translationRepository: TranslationRepositoryProtocol

    // MARK: - Initialization

    init(
        authService: AuthServiceProtocol? = nil,
        translationRepository: TranslationRepositoryProtocol? = nil
    ) {
        self.authService = authService ?? DependencyContainer.shared.resolve(AuthServiceProtocol.self)
        self.translationRepository = translationRepository ?? DependencyContainer.shared.resolve(TranslationRepositoryProtocol.self)
    }

    // MARK: - Actions

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        // Load user info
        if let user = await authService.currentUser {
            displayName = user.displayName
            email = user.email
            userInitials = user.initials
            tierDisplayName = user.subscriptionTier.displayName
        }

        // Load voice preferences from API
        do {
            let prefs = try await translationRepository.getPreferences()
            if let sourceLang = prefs.defaultSourceLang, let lang = Language(rawValue: sourceLang) {
                sourceLanguage = lang
            }
            if let targetLang = prefs.defaultTargetLang, let lang = Language(rawValue: targetLang) {
                targetLanguage = lang
            }
            if let rate = prefs.speechRate {
                speechRate = rate
            }
            if let autoDetect = prefs.autoDetectSource {
                autoDetectSource = autoDetect
            }
        } catch {
            // Use defaults if preferences not available
        }
    }

    func savePreferences() async {
        let prefs = VoicePreferencesDTO(
            preferredVoiceId: nil,
            voiceName: nil,
            speechRate: speechRate,
            defaultSourceLang: sourceLanguage.rawValue,
            defaultTargetLang: targetLanguage.rawValue,
            autoDetectSource: autoDetectSource
        )

        do {
            _ = try await translationRepository.updatePreferences(prefs)
        } catch {
            errorMessage = "Failed to save preferences"
            showError = true
        }
    }
}
