//
//  LiturgyStore.swift
//  Blissful Catholic
//
//  Fetches the day's liturgical info (season, color, celebration/saint, rank) from
//  the backend's /api/liturgy (romcal — calendar facts, no copyright). Reading
//  citations + scripture text are layered on later. Falls back gracefully when
//  offline: the UI keeps using the locally-computed season.
//

import Foundation

struct LiturgicalDay: Decodable {
    let date: String          // YYYY-MM-DD
    let celebration: String   // e.g. "The Ascension of the Lord" / "Friday of the 8th week of Ordinary Time"
    let rank: String          // SOLEMNITY | FEAST | MEMORIAL | OPT_MEMORIAL | SUNDAY | FERIA | …
    let season: String?       // e.g. "Ordinary Time"
    let seasonKey: String?
    let color: String?        // e.g. "GREEN"
    let colorHex: String?
    let cycle: String?
    /// Today's Mass reading *citations* (label + reference, no text). iOS
    /// resolves them against bundled WEBCE locally via `BibleService`.
    /// `nil` when the upstream readings source is unreachable.
    let readings: [ReadingCitation]?

    var isFeria: Bool { rank == "FERIA" }
}

struct ReadingCitation: Decodable, Hashable, Sendable, Identifiable {
    let label: String         // "First Reading" | "Responsorial Psalm" | "Second Reading" | "Gospel"
    let citation: String      // e.g. "Acts 18:9–18", "Daniel 3:52, 53, 54, 55, 56"

    var id: String { label + citation }
}

@MainActor
@Observable
final class LiturgyStore {
    private(set) var today: LiturgicalDay?

    /// Loads today's liturgical day (no-op if already loaded for the current date).
    /// Pass `force: true` to bypass the same-date short-circuit — used by
    /// pull-to-refresh so the user can re-pull when the upstream readings source
    /// has backfilled missing fields (a common case for the Responsorial Psalm
    /// on optional-memorial days).
    func loadToday(force: Bool = false) async {
        let date = Self.localDateString()
        if !force, today?.date == date { return }
        if let day = await Self.fetchDay(dateString: date) { today = day }
    }

    /// Stateless fetch of the liturgical day for an arbitrary `YYYY-MM-DD` date.
    /// Does not touch `today` — used by the notification scheduler to look ahead
    /// over the coming week. Returns nil on any network/decode failure (the
    /// caller falls back to generic copy). The `await` suspends, so being
    /// main-actor-isolated doesn't block the UI during the network call.
    static func fetchDay(dateString: String) async -> LiturgicalDay? {
        guard var comps = URLComponents(
            url: SupabaseConfig.apiBaseURL.appending(path: "api/liturgy"),
            resolvingAgainstBaseURL: false
        ) else { return nil }
        comps.queryItems = [URLQueryItem(name: "date", value: dateString)]
        guard let url = comps.url else { return nil }

        // Bypass URLSession's local cache — the response is small and the CDN already
        // caches at the edge. Local caching here once bit us: a stale pre-readings
        // payload sat in the device cache for an hour even after the backend was
        // updated, returning a day with `readings == nil`.
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(LiturgicalDay.self, from: data)
        } catch {
            return nil
        }
    }

    /// Debug-only date override. Set to a "YYYY-MM-DD" string to make every
    /// liturgy fetch behave as if that were today — useful for previewing the
    /// saint card and readings on a specific day without touching the device
    /// clock. Leave as `nil` for normal behavior. Stripped from release builds.
    #if DEBUG
    private static let debugDateOverride: String? = nil
    // Examples while content-wiring:
    //   "2026-06-24"  → Nativity of St. John the Baptist (Solemnity)
    //   "2026-08-15"  → Assumption (Solemnity)
    //   "2026-08-28"  → Augustine (Memorial)
    //   "2026-07-22"  → Mary Magdalene (Feast)
    //   "2026-05-22"  → Rita of Cascia (Optional Memorial)
    //   nil           → use the device's real clock
    #endif

    /// Today's date in the device's local calendar, as YYYY-MM-DD. Honors the
    /// DEBUG override so the in-app "today" can be pinned to a specific feast.
    private static func localDateString() -> String {
        #if DEBUG
        if let override = debugDateOverride { return override }
        #endif
        return dateString(for: Date())
    }

    /// Formats an arbitrary date as YYYY-MM-DD in the device's local calendar.
    /// No DEBUG override — the override is a "today" concept only, so the
    /// notification scheduler's look-ahead always uses real calendar dates.
    static func dateString(for date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
