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
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .verbioColors()
        }
    }
}
