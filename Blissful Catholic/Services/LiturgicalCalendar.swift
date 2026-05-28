//
//  LiturgicalCalendar.swift
//  Blissful Catholic
//
//  PHASE 1 STUB. A crude month-based heuristic for the current season so the
//  design system has something real to react to. This is intentionally NOT
//  liturgically exact — Phase 4 replaces it with a bundled Roman Rite calendar
//  (JSON) covering moveable feasts, fasting days, and ranks.
//

import Foundation

enum LiturgicalCalendar {
    /// Best-effort current season. Approximate — see file note.
    static func currentSeason(on date: Date = .now) -> LiturgicalSeason {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 12:        return .advent        // (Christmas proper begins Dec 25)
        case 1:         return .christmas      // Christmastide into early Ordinary Time
        case 2, 3:      return .lent
        case 4, 5:      return .easter
        default:        return .ordinaryTime
        }
    }
}
