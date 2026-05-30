//
//  Saint.swift
//  Blissful Catholic
//
//  Saint biographical data, bundled as saints.json. Resolved against romcal's
//  celebration string via SaintService.
//
//  Original devotional prose; factual basis cross-checked against the 1913
//  Catholic Encyclopedia (newadvent.org) and the General Roman Calendar.
//

import Foundation

nonisolated struct Saint: Decodable, Hashable, Sendable, Identifiable {
    /// Stable kebab-case identifier (e.g. "rita-of-cascia").
    let key: String
    /// Display name (e.g. "St. Rita of Cascia"). Uses the "St." abbreviation.
    let name: String
    /// Optional role descriptor — "Religious", "Bishop and Doctor of the Church",
    /// "Apostle", or the rank label ("Solemnity") for non-personal celebrations.
    let title: String?
    /// Year of death. Nil for Marian feasts, doctrine solemnities, and apostles
    /// whose dates are unknown.
    let yearOfDeath: Int?
    /// Single-sentence patronage/role line, shown beneath the name on both the
    /// card and the deep screen (e.g. "Patroness of impossible causes").
    let patronage: String?
    /// One- to two-sentence blurb for the card.
    let blurb: String
    /// Longer biography for the deep screen. Paragraphs separated by `\n\n`.
    let bio: String
    /// Pre-rendered art-plate label (e.g. "ST. RITA · 1457"). Authored per-saint
    /// so we keep typographic control for joint feasts and Marian solemnities.
    let artPlateLabel: String
    /// Possible romcal celebration strings that resolve to this saint. Matching
    /// in SaintService is case-insensitive, so we only need each distinct form
    /// once (no "St." vs "Saint" pairs).
    let romcalNames: [String]

    var id: String { key }
}

/// On-disk shape of saints.json — a tiny envelope around the saints array so
/// we can version the catalog without breaking decode.
nonisolated struct SaintCatalog: Decodable {
    let version: Int
    let saints: [Saint]
}
