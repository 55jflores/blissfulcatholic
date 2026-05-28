//
//  Streak.swift
//  Blissful Catholic
//
//  Derives prayer streaks from activity dates (prayer sessions, journal entries,
//  rosary logs). A day is "active" if it has at least one of those.
//

import Foundation

enum Streak {
    /// The set of distinct day-starts that had activity.
    static func activeDays(from dates: [Date], calendar: Calendar = .current) -> Set<Date> {
        Set(dates.map { calendar.startOfDay(for: $0) })
    }

    /// Consecutive active days ending today (or yesterday, if today isn't yet active).
    static func current(_ activeDays: Set<Date>, today: Date = .now, calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: today)
        if !activeDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
            guard activeDays.contains(day) else { return 0 }
        }
        var count = 0
        while activeDays.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// For the last `n` days (oldest → today), whether each was active.
    static func lastNDays(_ n: Int, activeDays: Set<Date>, today: Date = .now,
                          calendar: Calendar = .current) -> [Bool] {
        let start = calendar.startOfDay(for: today)
        return (0..<n).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: start)!
            return activeDays.contains(day)
        }
    }
}
