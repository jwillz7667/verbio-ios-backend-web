//
//  Injected.swift
//  Verbio
//
//  Property wrapper for dependency injection
//

import Foundation

// MARK: - Injected Property Wrapper

/// Property wrapper that automatically resolves dependencies from the container
@propertyWrapper
struct Injected<T> {
    private var value: T

    var wrappedValue: T {
        get { value }
        mutating set { value = newValue }
    }

    init() {
        self.value = DependencyContainer.shared.resolve(T.self)
    }
}

// MARK: - Lazy Injected Property Wrapper

/// Property wrapper that lazily resolves dependencies on first access
@propertyWrapper
struct LazyInjected<T> {
    private var value: T?

    var wrappedValue: T {
        mutating get {
            if value == nil {
                value = DependencyContainer.shared.resolve(T.self)
            }
            return value!
        }
        set { value = newValue }
    }

    init() {
        self.value = nil
    }
}

// MARK: - Optional Injected Property Wrapper

/// Property wrapper that optionally resolves dependencies
@propertyWrapper
struct OptionalInjected<T> {
    private var value: T?

    var wrappedValue: T? {
        get { value }
        mutating set { value = newValue }
    }

    init() {
        self.value = DependencyContainer.shared.resolveOptional(T.self)
    }
}
