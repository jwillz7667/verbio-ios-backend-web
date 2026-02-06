//
//  OnboardingViewModel.swift
//  Verbio
//
//  ViewModel for the onboarding walkthrough
//

import Foundation

// MARK: - Onboarding Page

struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Onboarding ViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Properties

    var currentPage: Int = 0
    var showPaywall = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "globe",
            title: "Speak Any Language",
            subtitle: "Translate your voice instantly into 50+ languages with natural AI-powered speech."
        ),
        OnboardingPage(
            id: 1,
            icon: "waveform.circle.fill",
            title: "Natural AI Voices",
            subtitle: "Hear translations spoken in lifelike voices that capture the tone and nuance of real speech."
        ),
        OnboardingPage(
            id: 2,
            icon: "bubble.left.and.bubble.right.fill",
            title: "Live Conversations",
            subtitle: "Have real-time two-way conversations across languages — Verbio translates for both sides."
        ),
        OnboardingPage(
            id: 3,
            icon: "sparkles",
            title: "Start Your Free Trial",
            subtitle: "Unlock unlimited translations with a 7-day free trial. Cancel anytime."
        ),
    ]

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    // MARK: - Actions

    func nextPage() {
        if isLastPage {
            showPaywall = true
        } else {
            currentPage += 1
        }
    }

    func skip() {
        currentPage = pages.count - 1
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
