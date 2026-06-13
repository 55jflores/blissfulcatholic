//
//  GospelReminderContent.swift
//  Blissful Catholic
//
//  Builds the title/body for the daily Gospel verse notification from a fetched
//  LiturgicalDay. The Catholic differentiator: the verse is the first line of
//  *today's actual Mass Gospel*, not an editorial pick. Degrades in three steps
//  to generic copy — offline (no day), no Gospel citation, or an empty verse —
//  the same graceful path the Daily screen uses for readings that haven't landed.
//

import Foundation

struct GospelReminderContent {
    let title: String
    let body: String

    /// Generic, no-network content for the fallback tier (days past the
    /// prefetch window) and any resolution failure.
    static var generic: GospelReminderContent { fallback(celebration: nil) }

    /// Resolve a notification from a day's Gospel. Runs on the main actor
    /// because BibleService is main-actor isolated.
    @MainActor
    static func make(for day: LiturgicalDay?) async -> GospelReminderContent {
        guard let day else { return generic }
        guard let gospel = day.readings?.first(where: { $0.label == "Gospel" }) else {
            return fallback(celebration: day.celebration)
        }
        let verses = await BibleService.shared.verses(forCitation: gospel.citation)
        guard let first = verses.first else { return fallback(celebration: day.celebration) }
        let text = cleaned(first.text)
        guard !text.isEmpty else { return fallback(celebration: day.celebration) }

        let reference = "\(bookName(fromCitation: gospel.citation)) \(first.chapter):\(first.verse)"
        return GospelReminderContent(
            title: day.celebration,
            body: "\u{201C}\(trimmed(text))\u{201D} — \(reference)"
        )
    }

    /// Title = the celebration when we have it, else a neutral header.
    static func fallback(celebration: String?) -> GospelReminderContent {
        GospelReminderContent(
            title: celebration ?? "Today's Gospel",
            body: "Today's Gospel is ready to pray with."
        )
    }

    // MARK: Helpers

    /// "Mark 11:11–26" → "Mark"; "1 Peter 4:7–13" → "1 Peter". Mirrors DailyView's
    /// private citation-to-book logic; kept local so this module is self-contained.
    private static func bookName(fromCitation citation: String) -> String {
        guard let colon = citation.firstIndex(of: ":") else { return citation }
        let head = citation[..<colon]
        guard let lastSpace = head.lastIndex(of: " ") else { return String(head) }
        return String(citation[..<lastSpace])
    }

    /// Collapse newlines/runs of whitespace and trim — verse JSON can carry stray
    /// spacing that looks wrong on a single-line lock-screen banner.
    private static func cleaned(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .joined(separator: " ")
    }

    /// Cap to a clean banner length, breaking on a word boundary.
    private static func trimmed(_ text: String, limit: Int = 120) -> String {
        guard text.count > limit else { return text }
        let cut = text.prefix(limit)
        if let lastSpace = cut.lastIndex(of: " ") {
            return String(cut[..<lastSpace]) + "…"
        }
        return String(cut) + "…"
    }
}
