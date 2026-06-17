//
//  LiturgicalDiscipline.swift
//  Blissful Catholic
//
//  Pure, on-device rules for US holy days of obligation and days of fasting /
//  abstinence. This data is NOT in romcal or /api/liturgy (rank is not a proxy —
//  many solemnities aren't obligation days), so we encode it ourselves. No API,
//  no AI — just deterministic date logic, fully unit-testable.
//
//  Full rules reference + scoping (US only, Ascension deferred, Dec 8 transfer
//  edge case): docs/liturgical-discipline.md.
//

import Foundation

/// A US holy day of obligation that actually binds on a given date (already
/// accounts for the Sat/Mon abrogation of Jan 1 / Aug 15 / Nov 1).
struct HolyDay: Equatable {
    let name: String        // full: "The Assumption of the Blessed Virgin Mary"
    let shortName: String   // concise: "the Assumption" — for notification copy
}

/// A day of obligatory penance: abstinence (no meat) and/or fasting (limited food).
struct Penitential: Equatable {
    let name: String        // "Ash Wednesday" / "Friday of Lent" / "Good Friday"
    let abstinence: Bool
    let fasting: Bool

    /// One-line description for a card/notification body.
    var summary: String {
        if abstinence && fasting { return "A day of fasting and abstinence from meat." }
        if abstinence { return "A day of abstinence from meat." }
        if fasting { return "A day of fasting." }
        return ""
    }
}

enum LiturgicalDiscipline {

    private static let calendar = Calendar(identifier: .gregorian)

    // MARK: Holy days of obligation

    /// The US holy day of obligation that binds on `date`, or nil. Ascension is
    /// deliberately excluded (province-dependent — see the doc).
    static func holyDayOfObligation(on date: Date) -> HolyDay? {
        let c = calendar.dateComponents([.month, .day, .weekday], from: date)
        guard let month = c.month, let day = c.day, let weekday = c.weekday else { return nil }
        // Calendar weekday: 1 = Sunday … 7 = Saturday. Abrogated on Sat (7) or Mon (2).
        let abrogatedIfSatMon = (weekday == 7 || weekday == 2)

        switch (month, day) {
        case (1, 1):
            return abrogatedIfSatMon ? nil
                : HolyDay(name: "Mary, the Holy Mother of God", shortName: "Mary, Mother of God")
        case (8, 15):
            return abrogatedIfSatMon ? nil
                : HolyDay(name: "The Assumption of the Blessed Virgin Mary", shortName: "the Assumption")
        case (11, 1):
            return abrogatedIfSatMon ? nil
                : HolyDay(name: "All Saints", shortName: "All Saints")
        case (12, 8):
            return HolyDay(name: "The Immaculate Conception of the Blessed Virgin Mary",
                           shortName: "the Immaculate Conception")
        case (12, 25):
            return HolyDay(name: "The Nativity of the Lord", shortName: "Christmas")
        default:
            return nil
        }
    }

    // MARK: Fasting & abstinence

    /// The obligatory penance on `date` (Ash Wednesday, a Friday of Lent, or Good
    /// Friday), or nil. Ordinary Fridays return nil — in the US, abstinence
    /// outside Lent may be substituted, so we don't assert "no meat" on them.
    static func penitential(on date: Date) -> Penitential? {
        let year = calendar.component(.year, from: date)
        let easter = easter(year: year)
        guard let ashWednesday = calendar.date(byAdding: .day, value: -46, to: easter),
              let goodFriday = calendar.date(byAdding: .day, value: -2, to: easter)
        else { return nil }

        let day = calendar.startOfDay(for: date)
        if calendar.isDate(day, inSameDayAs: ashWednesday) {
            return Penitential(name: "Ash Wednesday", abstinence: true, fasting: true)
        }
        if calendar.isDate(day, inSameDayAs: goodFriday) {
            return Penitential(name: "Good Friday", abstinence: true, fasting: true)
        }
        // Fridays strictly between Ash Wednesday and Good Friday (weekday 6 = Friday).
        if calendar.component(.weekday, from: day) == 6,
           day > calendar.startOfDay(for: ashWednesday),
           day < calendar.startOfDay(for: goodFriday) {
            return Penitential(name: "Friday of Lent", abstinence: true, fasting: false)
        }
        return nil
    }

    // MARK: Easter (Gregorian computus)

    /// Western (Gregorian) Easter Sunday for `year` — Anonymous Gregorian
    /// algorithm (Meeus/Jones/Butcher). Drives Ash Wednesday and Good Friday.
    static func easter(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps) ?? Date()
    }
}
