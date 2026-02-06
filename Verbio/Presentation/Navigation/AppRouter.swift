//
//  AppRouter.swift
//  Verbio
//
//  Main app navigation router
//

import SwiftUI

// MARK: - App Route

enum AppRoute: Hashable {
    case signIn
    case home
    case translation
    case conversation
    case history
    case phrases
    case settings
}

// MARK: - Auth State

@MainActor
@Observable
final class AuthState {

    // MARK: - Properties

    private(set) var isAuthenticated = false
    private(set) var isCheckingAuth = true
    private(set) var currentUser: User?

    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? DependencyContainer.shared.resolve(AuthServiceProtocol.self)
    }

    // MARK: - Methods

    func checkAuthStatus() async {
        isCheckingAuth = true
        defer { isCheckingAuth = false }

        isAuthenticated = await authService.checkAuthStatus()

        if isAuthenticated {
            currentUser = await authService.currentUser
        }
    }

    func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
    }

    func signOut() async {
        try? await authService.logout()
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - App Router View

struct AppRouterView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var authState = AuthState()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        Group {
            if authState.isCheckingAuth {
                // Loading state
                splashView
            } else if authState.isAuthenticated {
                if !hasSeenOnboarding {
                    // Show onboarding on first launch after sign-in
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                } else {
                    // Authenticated + onboarded — show main app
                    MainTabView()
                        .environment(authState)
                }
            } else {
                // Not authenticated - show sign in
                SignInView()
                    .environment(authState)
            }
        }
        .animation(VerbioAnimations.Spring.smooth, value: authState.isAuthenticated)
        .animation(VerbioAnimations.Spring.smooth, value: authState.isCheckingAuth)
        .animation(VerbioAnimations.Spring.smooth, value: hasSeenOnboarding)
        .task {
            await authState.checkAuthStatus()
        }
    }

    private var splashView: some View {
        ZStack {
            colors.backgrounds.primary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("VerbioLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                ProgressView()
                    .tint(colors.brand.primary)

                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(colors.text.secondary)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: AppRoute = .home

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tag(AppRoute.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Translation screen
            NavigationStack {
                TranslationView()
            }
            .tag(AppRoute.translation)
            .tabItem {
                Label("Translate", systemImage: "mic.fill")
            }

            // History screen
            ConversationListView()
                .tag(AppRoute.history)
                .tabItem {
                    Label("Conversations", systemImage: "bubble.left.and.bubble.right.fill")
                }

            // Saved Phrases screen
            SavedPhrasesView()
                .tag(AppRoute.phrases)
                .tabItem {
                    Label("Phrases", systemImage: "bookmark.fill")
                }

            // Settings screen
            SettingsView()
                .tag(AppRoute.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(colors.brand.primary)
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let icon: String

    var colors: VerbioColorScheme {
        VerbioColorScheme(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.backgrounds.primary
                    .ignoresSafeArea()

                VStack(spacing: VerbioSpacing.lg) {
                    Image(systemName: icon)
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(colors.brand.primary.opacity(0.5))

                    Text("Coming Soon")
                        .verbioHeadlineMedium()
                        .foregroundStyle(colors.text.secondary)

                    Text("\(title) will be available in the next update.")
                        .verbioBodyMedium()
                        .foregroundStyle(colors.text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, VerbioSpacing.xxl)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview("App Router") {
    AppRouterView()
}
