//
//  WidgetSupport.swift
//  BlissfulWidgets   (widget target)
//
//  Small self-contained helpers for the widgets: the parchment palette + curated
//  liturgical colors (echoing the app's Lumen look without importing it), date
//  parsing for the snapshot, and preview/today lookups.
//

import SwiftUI

enum LumenWidget {
    static let parchment = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let ink       = Color(red: 0.20, green: 0.17, blue: 0.13)
    static let inkSoft   = Color(red: 0.45, green: 0.40, blue: 0.33)

    /// Curated, slightly desaturated liturgical colors that sit well on parchment.
    static func liturgicalColor(_ name: String?) -> Color {
        switch (name ?? "").uppercased() {
        case "GREEN":            return Color(red: 0.24, green: 0.42, blue: 0.28)
        case "VIOLET", "PURPLE": return Color(red: 0.42, green: 0.31, blue: 0.56)
        case "WHITE", "GOLD":    return Color(red: 0.69, green: 0.54, blue: 0.24)
        case "RED":              return Color(red: 0.66, green: 0.23, blue: 0.22)
        case "ROSE", "PINK":     return Color(red: 0.76, green: 0.48, blue: 0.63)
        case "BLACK":            return Color(red: 0.23, green: 0.23, blue: 0.23)
        default:                 return Color(red: 0.42, green: 0.35, blue: 0.27)
        }
    }
}

enum WidgetDateFormat {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func parse(_ s: String) -> Date? { formatter.date(from: s) }
    static func string(for date: Date) -> String { formatter.string(from: date) }
}

extension WidgetSnapshot {
    /// The entry for the device's local "today", if the published snapshot has it.
    static func todayDay() -> WidgetDay? {
        let today = WidgetDateFormat.string(for: Date())
        return WidgetSharedStore.load()?.days.first { $0.date == today }
    }
}

extension WidgetDay {
    static let preview = WidgetDay(
        date: WidgetDateFormat.string(for: Date()),
        celebration: "Saint Anthony of Padua",
        rank: "MEMORIAL",
        season: "Ordinary Time",
        color: "WHITE",
        cycle: "Year C",
        gospelText: nil,
        gospelCitation: "Matthew 5:13")
}
