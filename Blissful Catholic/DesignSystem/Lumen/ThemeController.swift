//
//  ThemeController.swift
//  Blissful Catholic
//
//  Holds the user's appearance choices: ground (Parchment/Cathedral/System) and
//  an optional manual liturgical-season override (otherwise auto from the
//  calendar). Persisted like UserProfileStore. Injected at the root; the
//  Profile → Appearance settings will drive it (replacing Lumen's Tweaks panel).
//

import SwiftUI
import Observation

@Observable
final class ThemeController {
    private let defaults: UserDefaults

    var mode: ThemeMode {
        didSet { defaults.set(mode.rawValue, forKey: Keys.mode) }
    }
    /// nil = derive the season automatically from today's date.
    var seasonOverride: LiturgicalSeason? {
        didSet { defaults.set(seasonOverride?.rawValue, forKey: Keys.season) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.mode = ThemeMode(rawValue: defaults.string(forKey: Keys.mode) ?? "") ?? .parchment
        self.seasonOverride = LiturgicalSeason(rawValue: defaults.string(forKey: Keys.season) ?? "")
    }

    var season: LiturgicalSeason {
        seasonOverride ?? LiturgicalCalendar.currentSeason()
    }

    var palette: LiturgicalPalette { .for(season) }

    /// What to hand SwiftUI's `.preferredColorScheme` (nil = follow system).
    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .parchment: return .light
        case .cathedral: return .dark
        case .system:    return nil
        }
    }

    /// The effective ground, resolving `.system` against the device appearance.
    func effectiveScheme(system: ColorScheme) -> ColorScheme {
        switch mode {
        case .parchment: return .light
        case .cathedral: return .dark
        case .system:    return system
        }
    }

    func tokens(system: ColorScheme) -> LumenTokens {
        effectiveScheme(system: system) == .dark ? .cathedral : .parchment
    }

    private enum Keys {
        static let mode = "theme.mode"
        static let season = "theme.seasonOverride"
    }
}

/// Resolves the active tokens/palette and publishes them to the environment,
/// while keeping the legacy `\.liturgicalSeason` value in sync for not-yet-
/// reskinned screens.
struct LumenThemeProvider<Content: View>: View {
    @Environment(ThemeController.self) private var theme
    @Environment(\.colorScheme) private var systemScheme
    @ViewBuilder var content: Content

    var body: some View {
        let tokens = theme.tokens(system: systemScheme)
        content
            .environment(\.lumenTokens, tokens)
            .environment(\.lumenPalette, theme.palette)
            .tint(theme.palette.accent)
            .preferredColorScheme(theme.preferredColorScheme)
    }
}
