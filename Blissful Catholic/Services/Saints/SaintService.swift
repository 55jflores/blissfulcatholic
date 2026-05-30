//
//  SaintService.swift
//  Blissful Catholic
//
//  Lazy-loads bundled saints.json and resolves romcal celebration names into
//  Saint entries. Same lazy-load pattern as BibleService.
//
//  First-cut catalog: ~30 high-traffic entries. On days whose celebration isn't
//  in the catalog, `resolve` returns nil and DailyView hides the saint card.
//

import Foundation

@MainActor
@Observable
final class SaintService {
    static let shared = SaintService()

    private(set) var isLoaded = false
    private var catalog: SaintCatalog?
    private var loadTask: Task<SaintCatalog?, Never>?

    private init() {}

    // MARK: - Public API

    /// Resolve a romcal `celebration` string (e.g. "Saint Rita of Cascia,
    /// Religious") into a bundled `Saint`. Nil = no match — the calling view
    /// should hide its saint card rather than display stale content.
    func resolve(celebration: String) async -> Saint? {
        guard let catalog = await loadIfNeeded() else { return nil }
        let needle = Self.normalize(celebration)
        for saint in catalog.saints {
            for name in saint.romcalNames where Self.normalize(name) == needle {
                return saint
            }
        }
        return nil
    }

    // MARK: - Loading

    /// Loads bundled `saints.json` on the first call; cached thereafter.
    /// Concurrent callers coalesce onto the same task — same pattern as
    /// BibleService.loadIfNeeded.
    private func loadIfNeeded() async -> SaintCatalog? {
        if let catalog { return catalog }
        if let loadTask { return await loadTask.value }

        let task = Task.detached(priority: .utility) { Self.loadFromBundle() }
        loadTask = task
        let result = await task.value
        catalog = result
        isLoaded = (result != nil)
        loadTask = nil
        return result
    }

    nonisolated private static func loadFromBundle() -> SaintCatalog? {
        guard let url = Bundle.main.url(forResource: "saints", withExtension: "json") else {
            assertionFailure("saints.json missing from bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SaintCatalog.self, from: data)
        } catch {
            assertionFailure("Failed to load saints.json: \(error)")
            return nil
        }
    }

    // MARK: - Matching

    /// Aggressive canonicalisation so romcal's many surface variants collapse to
    /// the same key as our catalog's `romcalNames`. Both sides go through this
    /// function before comparison.
    ///
    /// romcal in practice emits a wide range of forms for the same saint:
    ///   "Saint Thomas Aquinas, Priest and Doctor"   (no "of the Church")
    ///   "Joseph, Husband of Mary"                    (no "Saint")
    ///   "Saint Augustine of Hippo, Bishop and Doctor of the Church"
    ///   "Saint Pio of Pietrelcina (Padre Pio), Priest"
    ///   "Birth of John the Baptist"                  ("Birth" not "Nativity")
    ///   "Saint Bartholomew the Apostle"              (no comma)
    ///   "Saint Catherine of Siena, Virgin and Doctor of The Church, Patron of Europe"
    ///
    /// We normalise all of those down to the short canonical core (e.g.
    /// "thomas aquinas", "joseph", "augustine", "pio of pietrelcina") so a
    /// single catalog entry matches every variant.
    private static func normalize(_ s: String) -> String {
        var text = s.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)

        // 1. Strip parenthetical aliases — "(padre pio)", etc.
        while let range = text.range(of: #"\s*\([^)]*\)"#, options: .regularExpression) {
            text.removeSubrange(range)
        }

        // 2. Strip role descriptors that follow a comma. Repeated because
        //    Catherine has ", virgin and doctor of the church, patron of europe".
        let commaSuffixes = [
            ", priest and doctor of the church",
            ", priest and doctor",
            ", bishop and doctor of the church",
            ", bishop and doctor",
            ", virgin and doctor of the church",
            ", virgin and doctor",
            ", doctor of the church",
            ", spouse of the blessed virgin mary",
            ", husband of mary",
            ", apostle and evangelist",
            ", patron of europe",
            ", apostles",
            ", apostle",
            ", evangelist",
            ", bishop",
            ", priest",
            ", religious",
            ", virgin",
            ", doctor",
            ", missionary",
        ]
        var changed = true
        while changed {
            changed = false
            for suffix in commaSuffixes where text.hasSuffix(suffix) {
                text.removeLast(suffix.count)
                changed = true
                break
            }
        }

        // 3. Strip leading title words ("Solemnity of ", "Saint ", "The ", …).
        let prefixes = [
            "solemnity of ", "memorial of ", "feast of ", "commemoration of ",
            "saints ", "sts. ", "sts ", "saint ", "st. ", "st ", "blessed ",
            "the ",
        ]
        changed = true
        while changed {
            changed = false
            for prefix in prefixes where text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
                changed = true
                break
            }
        }

        // 4. Strip the same title words mid-string ("nativity of saint john …").
        text = text.replacingOccurrences(of: " saint ", with: " ")
        text = text.replacingOccurrences(of: " st. ", with: " ")
        text = text.replacingOccurrences(of: " st ", with: " ")
        text = text.replacingOccurrences(of: " blessed ", with: " ")

        // 5. Strip trailing "the Apostle" / "of Hippo" patterns (no comma).
        let trailingDescriptors = [
            " the apostle and evangelist",
            " the apostle",
            " the evangelist",
            " the great",
            " the greater",
            " the less",
            " of hippo",
        ]
        for desc in trailingDescriptors where text.hasSuffix(desc) {
            text.removeLast(desc.count)
            break
        }

        // 6. Strip trailing object phrases so "Annunciation of the Lord" matches
        //    "Annunciation" and "Assumption of the Blessed Virgin Mary" matches
        //    "Assumption".
        let trailingPhrases = [
            " of the blessed virgin mary",
            " of the lord",
            " of christ",
            " of god",
        ]
        for phrase in trailingPhrases where text.hasSuffix(phrase) {
            text.removeLast(phrase.count)
            break
        }

        // 7. romcal uses "Birth of John the Baptist"; tradition uses "Nativity of".
        //    Coalesce.
        if text.hasPrefix("birth of ") {
            text = "nativity of " + text.dropFirst("birth of ".count)
        }

        // 8. Collapse whitespace and trim.
        text = text.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        return text
    }
}
