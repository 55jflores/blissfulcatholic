//
//  AppContext.swift
//  Blissful Catholic
//
//  The "context object" from the brief — the bundle of personalization signals
//  that accompanies every Claude API call so responses are tailored to *this*
//  user, *today*. Assembling it here makes the data flow explicit long before
//  the AI backend exists.
//
//  Brief: "Context object sent with every call: user state in life, faith
//  maturity, Catholic background, liturgical season, today's feast, recent
//  spiritual themes, prayer history."
//

import Foundation

struct AppContext {
    // From the user's profile.
    let stateInLife: StateInLife?
    let faithMaturity: FaithMaturity?
    let catholicBackground: CatholicBackground?

    // From the liturgical calendar / today.
    let liturgicalSeason: LiturgicalSeason
    let feastTitle: String?

    // PHASE 4 placeholders — populated from SpiritualInsight / PrayerSession once
    // those features are live. Empty for now.
    let recentThemes: [String]
    let prayerHistorySummary: String?

    /// Assemble the context for the current moment from the user's profile.
    static func current(profile: UserProfileStore,
                        season: LiturgicalSeason = LiturgicalCalendar.currentSeason(),
                        feastTitle: String? = nil,
                        recentThemes: [String] = [],
                        prayerHistorySummary: String? = nil) -> AppContext {
        AppContext(
            stateInLife: profile.stateInLife,
            faithMaturity: profile.faithMaturity,
            catholicBackground: profile.background,
            liturgicalSeason: season,
            feastTitle: feastTitle,
            recentThemes: recentThemes,
            prayerHistorySummary: prayerHistorySummary
        )
    }

    /// The text block that will be injected into the system prompt in Phase 3/4.
    /// Defined now so the personalization contract is visible and testable.
    var systemPromptFragment: String {
        var lines: [String] = ["# About this person"]
        if let s = stateInLife { lines.append("- State in life: \(s.displayName)") }
        if let f = faithMaturity { lines.append("- Faith maturity: \(f.displayName)") }
        if let b = catholicBackground { lines.append("- Background: \(b.displayName)") }
        lines.append("- Liturgical season: \(liturgicalSeason.displayName)")
        if let feast = feastTitle { lines.append("- Today: \(feast)") }
        if !recentThemes.isEmpty {
            lines.append("- Recent spiritual themes: \(recentThemes.joined(separator: ", "))")
        }
        if let history = prayerHistorySummary { lines.append("- Prayer history: \(history)") }
        return lines.joined(separator: "\n")
    }
}
