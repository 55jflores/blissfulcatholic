//
//  WidgetSnapshotWriter.swift
//  Blissful Catholic   (app target only)
//
//  Builds the next week of liturgical days (+ each day's Gospel first verse) and
//  publishes a WidgetSnapshot to the App Group for the widgets to render. Runs on
//  app launch and on backgrounding — independent of reminder settings, since the
//  widgets exist whether or not notifications are enabled.
//
//  Note: this currently fetches its own 7-day window, separate from
//  NotificationService.refresh's. A future pass can share one fetch between them;
//  the endpoint is edge-cached, so the overlap is cheap for now.
//

import Foundation
import WidgetKit

enum WidgetSnapshotWriter {
    private static let daysAhead = 7

    @MainActor
    static func update() async {
        let cal = Calendar.current
        var days: [WidgetDay] = []

        for offset in 0..<daysAhead {
            guard let date = cal.date(byAdding: .day, value: offset, to: Date()),
                  let day = await LiturgyStore.fetchDay(dateString: LiturgyStore.dateString(for: date))
            else { continue }

            let (text, citation) = await gospel(for: day)
            days.append(WidgetDay(
                date: LiturgyStore.dateString(for: date),
                celebration: day.celebration,
                rank: day.rank,
                season: day.season,
                color: day.color,
                cycle: day.cycle,
                gospelText: text,
                gospelCitation: citation))
        }

        // On a total fetch failure keep the last good snapshot rather than wiping
        // the widget — same graceful-degradation principle as the Daily screen.
        guard !days.isEmpty else { return }
        WidgetSharedStore.save(WidgetSnapshot(days: days, generatedAt: Date()))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// First verse of the day's Gospel + its citation ("John 15:9"), or (nil, nil)
    /// when there's no Gospel citation or it doesn't resolve.
    @MainActor
    private static func gospel(for day: LiturgicalDay) async -> (String?, String?) {
        guard let gospel = day.readings?.first(where: { $0.label == "Gospel" }) else { return (nil, nil) }
        let verses = await BibleService.shared.verses(forCitation: gospel.citation)
        guard let first = verses.first, !first.text.isEmpty else { return (nil, nil) }
        let text = first.text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return (text, "\(bookName(fromCitation: gospel.citation)) \(first.chapter):\(first.verse)")
    }

    private static func bookName(fromCitation citation: String) -> String {
        guard let colon = citation.firstIndex(of: ":") else { return citation }
        let head = citation[..<colon]
        guard let lastSpace = head.lastIndex(of: " ") else { return String(head) }
        return String(citation[..<lastSpace])
    }
}
