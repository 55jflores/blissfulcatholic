//
//  AppRootView.swift
//  Blissful Catholic
//
//  Decides what the user sees first: onboarding (and, later, authentication)
//  until they've completed setup, then the main tab experience.
//
//  AppRootView
//  ├── OnboardingView        (until onboardingComplete)
//  └── MainTabView           (Daily · Pray · Learn · Journal · Profile)
//

import SwiftUI
import SwiftData

struct AppRootView: View {
    // Reads the shared profile. Phase 4 will add a real authentication gate
    // before the main experience.
    @Environment(UserProfileStore.self) private var profile

    var body: some View {
        Group {
            if profile.onboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: profile.onboardingComplete)
    }
}

#Preview("Onboarding") {
    AppRootView()
        .environment(UserProfileStore.preview)
        .environment(ThemeController())
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
        .modelContainer(PreviewSupport.container)
}
