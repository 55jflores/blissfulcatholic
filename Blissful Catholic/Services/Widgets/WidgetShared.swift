//
//  WidgetShared.swift
//  Blissful Catholic  +  BlissfulWidgetsExtension   ← belongs to BOTH targets
//
//  The single shared surface between the app and the widget extension. The app
//  WRITES a fully-resolved snapshot (no app internals, no Bible JSON, nothing to
//  recompute); the widget READS and renders it. Passed through the App Group
//  container both processes can see.
//
//  ⚠️ This file must have Target Membership in BOTH "Blissful Catholic" and
//     "BlissfulWidgetsExtension" (File Inspector → Target Membership). It lives
//     in the app's synchronized folder, so it auto-joins the app target; tick
//     the widget target by hand.
//

import Foundation

enum AppGroup {
    /// Must match the App Groups capability on both targets' entitlements.
    static let id = "group.co.jesusflores.blissfulcatholic"
}

/// One day's liturgical identity + (optional) Gospel verse, fully resolved by the
/// app so the widget can render without any lookup. `colorHex` is the liturgical
/// color; gospel fields are nil on days the readings feed hasn't resolved.
struct WidgetDay: Codable, Hashable {
    let date: String          // YYYY-MM-DD (device-local)
    let celebration: String   // saint name on a memorial; weekday descriptor on a feria
    let rank: String          // SOLEMNITY | FEAST | MEMORIAL | OPT_MEMORIAL | SUNDAY | FERIA
    let season: String?
    let color: String?        // liturgical color NAME, e.g. "GREEN" / "VIOLET" / "WHITE"
    let cycle: String?        // e.g. "Year C"
    let gospelText: String?   // first verse of today's Mass Gospel
    let gospelCitation: String?
}

/// The whole payload the app writes for the widget: today + the next several days
/// so WidgetKit can build a timeline that rolls over at midnight on its own.
struct WidgetSnapshot: Codable {
    let days: [WidgetDay]
    let generatedAt: Date
}

extension String {
    /// Wrap a scripture verse in curly quotes for display — without doubling up
    /// when the WEBCE text already begins/ends with a quotation mark. Many Gospel
    /// verses are direct speech and arrive pre-quoted (e.g. Matthew 5:33 starts
    /// with a `"`), so naively adding quotes yields `""Again…`. Only *double*
    /// quotes at the boundary are stripped, so nested single quotes are preserved.
    var quotedForDisplay: String {
        var t = trimmingCharacters(in: .whitespacesAndNewlines)
        let doubleQuotes: Set<Character> = ["\"", "\u{201C}", "\u{201D}"]
        if let first = t.first, doubleQuotes.contains(first) { t.removeFirst() }
        if let last = t.last, doubleQuotes.contains(last) { t.removeLast() }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\u{201C}\(t)\u{201D}"
    }
}

enum WidgetSharedStore {
    private static let key = "widget.snapshot"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: AppGroup.id) }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> WidgetSnapshot? {
        guard let defaults, let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}
