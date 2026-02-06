//
//  Container.swift
//  Verbio
//
//  Lightweight dependency injection container
//

import Foundation

// MARK: - Dependency Container

/// Thread-safe dependency injection container
final class DependencyContainer: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Storage

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var singletonKeys: Set<String> = []  // Track which keys should be singletons
    private let lock = NSLock()

    // MARK: - Initialization

    private init() {
        registerDefaults()
    }

    // MARK: - Registration

    /// Register a factory that creates a new instance each time
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        factories[key] = factory
    }

    /// Register a singleton instance (lazy initialization to avoid recursive access)
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        // Store factory for lazy initialization to avoid recursive access during init
        factories[key] = factory
        singletonKeys.insert(key)
    }

    /// Register an existing instance as a singleton
    func registerInstance<T>(_ instance: T) {
        let key = String(describing: T.self)
        lock.lock()
        defer { lock.unlock() }
        singletons[key] = instance
    }

    // MARK: - Resolution

    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        lock.lock()

        // Check singletons cache first
        if let singleton = singletons[key] as? T {
            lock.unlock()
            return singleton
        }

        // Check factories
        if let factory = factories[key] {
            // For singletons, create and cache the instance
            if singletonKeys.contains(key) {
                lock.unlock()  // Unlock before calling factory to avoid deadlock
                let instance = factory()
                lock.lock()
                // Double-check another thread didn't create it
                if let existingSingleton = singletons[key] as? T {
                    lock.unlock()
                    return existingSingleton
                }
                singletons[key] = instance
                lock.unlock()
                return instance as! T
            } else {
                lock.unlock()
                return factory() as! T
            }
        }

        lock.unlock()
        fatalError("No registered dependency for type: \(key)")
    }

    /// Resolve a dependency, returning nil if not found
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        lock.lock()

        // Check singletons cache first
        if let singleton = singletons[key] as? T {
            lock.unlock()
            return singleton
        }

        // Check factories
        if let factory = factories[key] {
            // For singletons, create and cache the instance
            if singletonKeys.contains(key) {
                lock.unlock()
                let instance = factory()
                lock.lock()
                if let existingSingleton = singletons[key] as? T {
                    lock.unlock()
                    return existingSingleton
                }
                singletons[key] = instance
                lock.unlock()
                return instance as? T
            } else {
                lock.unlock()
                return factory() as? T
            }
        }

        lock.unlock()
        return nil
    }

    // MARK: - Default Registrations

    private func registerDefaults() {
        // Register core services
        registerSingleton(KeychainServiceProtocol.self) {
            KeychainService()
        }

        registerSingleton(NetworkClientProtocol.self) {
            NetworkClient(
                configuration: AppConfiguration.shared,
                keychainService: DependencyContainer.shared.resolve(KeychainServiceProtocol.self)
            )
        }

        registerSingleton(AuthRepositoryProtocol.self) {
            AuthRepository(
                networkClient: DependencyContainer.shared.resolve(NetworkClientProtocol.self),
                keychainService: DependencyContainer.shared.resolve(KeychainServiceProtocol.self)
            )
        }

        registerSingleton(AuthServiceProtocol.self) {
            AuthService(
                authRepository: DependencyContainer.shared.resolve(AuthRepositoryProtocol.self),
                keychainService: DependencyContainer.shared.resolve(KeychainServiceProtocol.self)
            )
        }

        // Audio Service
        registerSingleton(AudioServiceProtocol.self) {
            AudioService()
        }

        // Translation Repository
        registerSingleton(TranslationRepositoryProtocol.self) {
            TranslationRepository(
                networkClient: DependencyContainer.shared.resolve(NetworkClientProtocol.self)
            )
        }

        // Conversation Repository
        registerSingleton(ConversationRepositoryProtocol.self) {
            ConversationRepository(
                networkClient: DependencyContainer.shared.resolve(NetworkClientProtocol.self)
            )
        }

        // Phrases Repository
        registerSingleton(PhrasesRepositoryProtocol.self) {
            PhrasesRepository(
                networkClient: DependencyContainer.shared.resolve(NetworkClientProtocol.self)
            )
        }

        // User Repository
        registerSingleton(UserRepositoryProtocol.self) {
            UserRepository(
                networkClient: DependencyContainer.shared.resolve(NetworkClientProtocol.self)
            )
        }

        // Translation Service
        registerSingleton(TranslationServiceProtocol.self) {
            TranslationService(
                translationRepository: DependencyContainer.shared.resolve(TranslationRepositoryProtocol.self),
                audioService: DependencyContainer.shared.resolve(AudioServiceProtocol.self)
            )
        }

        // Conversation Service
        registerSingleton(ConversationServiceProtocol.self) {
            ConversationService(
                conversationRepository: DependencyContainer.shared.resolve(ConversationRepositoryProtocol.self),
                translationService: DependencyContainer.shared.resolve(TranslationServiceProtocol.self)
            )
        }

        // StoreKit Service
        registerSingleton(StoreKitServiceProtocol.self) {
            StoreKitManager()
        }
    }

    // MARK: - Testing Support

    /// Reset the container (useful for testing)
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
        singletons.removeAll()
        singletonKeys.removeAll()
        registerDefaults()
    }
}

// MARK: - Container Keys

enum ContainerKey {
    static let keychainService = "KeychainServiceProtocol"
    static let networkClient = "NetworkClientProtocol"
    static let authRepository = "AuthRepositoryProtocol"
    static let authService = "AuthServiceProtocol"
    static let audioService = "AudioServiceProtocol"
    static let translationRepository = "TranslationRepositoryProtocol"
    static let conversationRepository = "ConversationRepositoryProtocol"
    static let translationService = "TranslationServiceProtocol"
    static let conversationService = "ConversationServiceProtocol"
    static let storeKitService = "StoreKitServiceProtocol"
}
