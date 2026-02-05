//
//  Language.swift
//  Verbio
//
//  Supported languages for translation
//

import Foundation

// MARK: - Language Enum

enum Language: String, Codable, CaseIterable, Identifiable, Sendable {
    case en = "EN"
    case es = "ES"
    case fr = "FR"
    case de = "DE"
    case it = "IT"
    case pt = "PT"
    case zh = "ZH"
    case ja = "JA"
    case ko = "KO"
    case ar = "AR"
    case hi = "HI"
    case ru = "RU"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Full display name of the language
    var displayName: String {
        switch self {
        case .en: return "English"
        case .es: return "Spanish"
        case .fr: return "French"
        case .de: return "German"
        case .it: return "Italian"
        case .pt: return "Portuguese"
        case .zh: return "Chinese"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .ar: return "Arabic"
        case .hi: return "Hindi"
        case .ru: return "Russian"
        }
    }

    /// Native name of the language
    var nativeName: String {
        switch self {
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        case .pt: return "Português"
        case .zh: return "中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .ar: return "العربية"
        case .hi: return "हिन्दी"
        case .ru: return "Русский"
        }
    }

    /// Flag emoji for the language
    var flag: String {
        switch self {
        case .en: return "🇺🇸"
        case .es: return "🇪🇸"
        case .fr: return "🇫🇷"
        case .de: return "🇩🇪"
        case .it: return "🇮🇹"
        case .pt: return "🇵🇹"
        case .zh: return "🇨🇳"
        case .ja: return "🇯🇵"
        case .ko: return "🇰🇷"
        case .ar: return "🇸🇦"
        case .hi: return "🇮🇳"
        case .ru: return "🇷🇺"
        }
    }

    /// Short display format: "EN" or "ES"
    var shortCode: String {
        rawValue
    }

    /// Locale identifier (BCP 47)
    var localeIdentifier: String {
        switch self {
        case .en: return "en-US"
        case .es: return "es-ES"
        case .fr: return "fr-FR"
        case .de: return "de-DE"
        case .it: return "it-IT"
        case .pt: return "pt-PT"
        case .zh: return "zh-CN"
        case .ja: return "ja-JP"
        case .ko: return "ko-KR"
        case .ar: return "ar-SA"
        case .hi: return "hi-IN"
        case .ru: return "ru-RU"
        }
    }

    // MARK: - Common Language Pairs

    /// Default translation pairs for quick selection
    static let commonPairs: [(source: Language, target: Language)] = [
        (.en, .es),
        (.en, .fr),
        (.en, .de),
        (.en, .zh),
        (.en, .ja),
        (.es, .en),
        (.fr, .en),
        (.de, .en),
        (.zh, .en),
        (.ja, .en),
    ]

    // MARK: - Initialization

    /// Initialize from locale identifier
    init?(localeIdentifier: String) {
        let code = String(localeIdentifier.prefix(2)).lowercased()

        switch code {
        case "en": self = .en
        case "es": self = .es
        case "fr": self = .fr
        case "de": self = .de
        case "it": self = .it
        case "pt": self = .pt
        case "zh": self = .zh
        case "ja": self = .ja
        case "ko": self = .ko
        case "ar": self = .ar
        case "hi": self = .hi
        case "ru": self = .ru
        default: return nil
        }
    }

    /// Get device's preferred language if supported
    static var deviceLanguage: Language {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        return Language(localeIdentifier: preferredLanguage) ?? .en
    }
}

// MARK: - Language + Comparable

extension Language: Comparable {
    static func < (lhs: Language, rhs: Language) -> Bool {
        lhs.displayName < rhs.displayName
    }
}
