//
//  LiturgicalSeason.swift
//  Blissful Catholic
//
//  The Church's liturgical seasons. Drives the app's accent color and tone.
//  NOTE: Phase 1 uses a lightweight date heuristic (see LiturgicalCalendar).
//  Phase 4 replaces this with a bundled Roman Rite calendar (JSON).
//

import Foundation

enum LiturgicalSeason: String, CaseIterable, Codable, Identifiable {
    case advent
    case christmas
    case ordinaryTime
    case lent
    case triduum
    case easter
    case feast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .advent:       return "Advent"
        case .christmas:    return "Christmas"
        case .ordinaryTime: return "Ordinary time"
        case .lent:         return "Lent"
        case .triduum:      return "The Triduum"
        case .easter:       return "Easter"
        case .feast:        return "Feast"
        }
    }

    /// A short, warm description of the season's spirit.
    var spirit: String {
        switch self {
        case .advent:       return "A season of joyful waiting."
        case .christmas:    return "The Word made flesh dwells among us."
        case .ordinaryTime: return "Walking with Christ, day by day."
        case .lent:         return "A desert journey toward Easter."
        case .triduum:      return "The heart of the year — passion, death, resurrection."
        case .easter:       return "He is risen. Alleluia."
        case .feast:        return "A day of holy celebration."
        }
    }
}
