//
//  VerbioApp.swift
//  Verbio
//
//  Created by Justin Williams on 2/4/26.
//

import SwiftUI

@main
struct VerbioApp: App {

    // MARK: - Initialization

    init() {
        // Initialize dependency container
        // This happens automatically via DependencyContainer.shared
        // but we can add custom initialization here if needed

        // Start StoreKit transaction listener
        Task {
            let storeKit = DependencyContainer.shared.resolve(StoreKitServiceProtocol.self)
            await storeKit.startTransactionListener()
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .verbioColors()
        }
    }
}
