//
//  Blissful_CatholicApp.swift
//  Blissful Catholic
//
//  App entry point. Phase 2: a local SwiftData ModelContainer is created here and
//  shared app-wide (CloudKit deferred — see [[phase2-swiftdata]]). The profile
//  store reads the container's main context.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct Blissful_CatholicApp: App {
    private let modelContainer: ModelContainer
    @State private var profile: UserProfileStore
    @State private var theme = ThemeController()
    @State private var auth = AuthStore()
    @State private var notificationRouter: NotificationRouter
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Schema(AppSchema.models))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        modelContainer = container
        _profile = State(initialValue: UserProfileStore(context: container.mainContext))

        // Wire the notification deep-link router into the service before any UI
        // appears, so a cold-launch notification tap routes correctly.
        let router = NotificationRouter()
        _notificationRouter = State(initialValue: router)
        NotificationService.shared.router = router
    }

    var body: some Scene {
        WindowGroup {
            LumenThemeProvider {
                AppRootView()
            }
            .environment(profile)
            .environment(theme)
            .environment(auth)
            .environment(notificationRouter)
            .task {
                await NotificationService.shared.refreshAuthorizationStatus()
                await NotificationService.shared.refresh(settings: ReminderSettingsStore.load())
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Re-roll the rolling notification window when leaving the app —
                // the queue is freshest exactly when it's about to be needed.
                if newPhase == .background {
                    Task { await NotificationService.shared.refresh(settings: ReminderSettingsStore.load()) }
                }
            }
            .onOpenURL { url in
                if GIDSignIn.sharedInstance.handle(url) { return }
                Task { await auth.handle(url: url) }
            }
            .alert(
                "Blissful Catholic",
                isPresented: Binding(
                    get: { auth.authNotice != nil },
                    set: { if !$0 { auth.authNotice = nil } }
                )
            ) {
                Button("OK", role: .cancel) { auth.authNotice = nil }
            } message: {
                Text(auth.authNotice ?? "")
            }
        }
        .modelContainer(modelContainer)
    }
}
