//
//  UserProfileStore.swift
//  Blissful Catholic
//
//  The single source of truth for who the user is — now a thin facade over the
//  SwiftData `UserProfile` model (Phase 2). The property surface is unchanged, so
//  onboarding, the Profile screen, the Daily greeting, and AppContext keep
//  working untouched. Seeds once from the legacy @AppStorage keys on first run.
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class UserProfileStore {
    private let context: ModelContext
    private let model: UserProfile

    var displayName: String { didSet { model.displayName = displayName; persist() } }
    var background: CatholicBackground? { didSet { model.background = background; persist() } }
    var stateInLife: StateInLife? { didSet { model.stateInLife = stateInLife; persist() } }
    var faithMaturity: FaithMaturity? { didSet { model.faithMaturity = faithMaturity; persist() } }
    var onboardingComplete: Bool { didSet { model.onboardingComplete = onboardingComplete; persist() } }

    init(context: ModelContext) {
        self.context = context
        let model = Self.fetchOrCreate(in: context)
        self.model = model
        // Mirror into observable properties (didSet does not fire during init).
        self.displayName = model.displayName
        self.background = model.background
        self.stateInLife = model.stateInLife
        self.faithMaturity = model.faithMaturity
        self.onboardingComplete = model.onboardingComplete
    }

    var greetingName: String {
        displayName.trimmingCharacters(in: .whitespaces).isEmpty ? "Friend in Christ" : displayName
    }

    func applyOnboarding(displayName: String,
                         background: CatholicBackground?,
                         stateInLife: StateInLife?,
                         faithMaturity: FaithMaturity?) {
        self.displayName = displayName
        self.background = background
        self.stateInLife = stateInLife
        self.faithMaturity = faithMaturity
        self.onboardingComplete = true
    }

    private func persist() { try? context.save() }

    /// Fetch the single UserProfile, or create one — seeding from the legacy
    /// @AppStorage values used before Phase 2 so existing users keep their setup.
    private static func fetchOrCreate(in context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let d = UserDefaults.standard
        let profile = UserProfile()
        profile.displayName = d.string(forKey: "profile.displayName") ?? ""
        profile.background = CatholicBackground(rawValue: d.string(forKey: "profile.background") ?? "")
        profile.stateInLife = StateInLife(rawValue: d.string(forKey: "profile.stateInLife") ?? "")
        profile.faithMaturity = FaithMaturity(rawValue: d.string(forKey: "profile.faithMaturity") ?? "")
        profile.onboardingComplete = d.bool(forKey: "onboardingComplete")
        context.insert(profile)
        try? context.save()
        return profile
    }
}

extension UserProfileStore {
    /// A populated store for previews, backed by the in-memory preview container.
    @MainActor
    static var preview: UserProfileStore {
        let store = UserProfileStore(context: PreviewSupport.container.mainContext)
        if store.displayName.isEmpty {
            store.applyOnboarding(displayName: "Maria", background: .convert,
                                  stateInLife: .married, faithMaturity: .intermediate)
        }
        return store
    }
}
