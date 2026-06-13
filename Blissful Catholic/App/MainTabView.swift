//
//  MainTabView.swift
//  Blissful Catholic
//
//  The five-tab spine, now with Lumen's floating tab bar. Daily is reskinned to
//  Lumen; Pray / Learn / Journal / You still use their Phase-1 layouts until
//  they're reskinned in turn.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selection: AppTab = .daily
    @Environment(\.lumenTokens) private var t
    @Environment(NotificationRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            t.bg.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LumenTabBar(selection: $selection)
        }
        .onChange(of: router.route) { _, newRoute in
            // A tapped notification asked us to navigate. v1: Daily only.
            guard let newRoute else { return }
            switch newRoute {
            case .daily: selection = .daily
            }
            router.route = nil
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .daily:   DailyView()
        case .pray:    PrayView()
        case .learn:   LearnView()
        case .journal: JournalView()
        case .profile: ProfileView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(UserProfileStore.preview)
        .environment(ThemeController())
        .environment(NotificationRouter())
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
        .modelContainer(PreviewSupport.container)
}
