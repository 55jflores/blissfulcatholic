//
//  LiturgicalPalette.swift
//  Blissful Catholic
//
//  The accent that shifts with the liturgical season. Built on Lumen's warm
//  hexes, but corrected for Roman Rite accuracy (Advent is violet, not Lumen's
//  blue; Christmas gets its own white/gold; Triduum kept distinct from Feast).
//

import SwiftUI

struct LiturgicalPalette: Equatable {
    let accent: Color
    let accentSoft: Color
    /// Display name as it appears in headers (e.g. "Eastertide").
    let name: String

    static func `for`(_ season: LiturgicalSeason) -> LiturgicalPalette {
        switch season {
        case .ordinaryTime:
            return .init(accent: Color(hex: 0x4a6b3a), accentSoft: Color(hex: 0x7a9268),
                         name: "Ordinary Time")
        case .easter:
            return .init(accent: Color(hex: 0xb8956a), accentSoft: Color(hex: 0xd6b78c),
                         name: "Eastertide")
        case .lent:
            return .init(accent: Color(hex: 0x5a3a6b), accentSoft: Color(hex: 0x8568a0),
                         name: "Lent")
        case .advent:
            // Corrected to a royal violet — distinct from Lent's somber purple.
            return .init(accent: Color(hex: 0x6a4a8a), accentSoft: Color(hex: 0x9a7db0),
                         name: "Advent")
        case .christmas:
            // White/gold festal — richer than Eastertide's bronze-gold.
            return .init(accent: Color(hex: 0xbfa14a), accentSoft: Color(hex: 0xe0cd8f),
                         name: "Christmastide")
        case .triduum:
            // Deep blood red, darker than a Feast red.
            return .init(accent: Color(hex: 0x6e2a2a), accentSoft: Color(hex: 0x9c5050),
                         name: "Sacred Triduum")
        case .feast:
            // Red — martyrs, Pentecost, Palm Sunday.
            return .init(accent: Color(hex: 0x8a3a3a), accentSoft: Color(hex: 0xb06868),
                         name: "Feast")
        }
    }
}

private struct LumenPaletteKey: EnvironmentKey {
    static let defaultValue: LiturgicalPalette = .for(.easter)
}

extension EnvironmentValues {
    var lumenPalette: LiturgicalPalette {
        get { self[LumenPaletteKey.self] }
        set { self[LumenPaletteKey.self] = newValue }
    }
}
