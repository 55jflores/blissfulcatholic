//
//  BlissfulWidgets.swift
//  BlissfulWidgets
//
//  "Today, liturgically" — today's celebration, rank, season, and liturgical
//  color, read from the App Group snapshot the app publishes (WidgetSnapshot).
//  On a saint's memorial the celebration IS the saint of the day; on a feria it
//  reads as the weekday. Populated every day of the year.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct LiturgyEntry: TimelineEntry {
    let date: Date
    let day: WidgetDay?
}

struct LiturgyProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiturgyEntry {
        LiturgyEntry(date: Date(), day: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (LiturgyEntry) -> Void) {
        completion(LiturgyEntry(date: Date(), day: WidgetSnapshot.todayDay() ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiturgyEntry>) -> Void) {
        let days = WidgetSharedStore.load()?.days ?? []
        // One entry per day, dated at that day's local midnight, so the widget
        // rolls over on its own. WidgetKit shows the most recent past entry.
        var entries: [LiturgyEntry] = days.compactMap { day in
            guard let date = WidgetDateFormat.parse(day.date) else { return nil }
            return LiturgyEntry(date: Calendar.current.startOfDay(for: date), day: day)
        }
        if entries.isEmpty { entries = [LiturgyEntry(date: Date(), day: nil)] }
        entries.sort { $0.date < $1.date }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget

struct BlissfulTodayWidget: Widget {
    let kind = "BlissfulToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiturgyProvider()) { entry in
            TodayWidgetView(entry: entry)
                .widgetURL(URL(string: "blissfulcatholic://daily"))
        }
        .configurationDisplayName("Today, Liturgically")
        .description("The day's celebration, season, and liturgical color.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Views

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiturgyEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                switch family {
                case .accessoryRectangular, .accessoryCircular, .accessoryInline:
                    AccessoryWidgetBackground()   // adaptive backing for legibility on any wallpaper
                default:
                    LumenWidget.parchment
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:      inline
        case .accessoryRectangular: rectangular
        case .systemMedium:         medium
        default:                    small
        }
    }

    private var day: WidgetDay? { entry.day }

    // Home — small
    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            colorEyebrow
            Text(day?.celebration ?? "Today")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(LumenWidget.ink)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if let season = day?.season {
                Text(season)
                    .font(.system(.caption2))
                    .foregroundStyle(LumenWidget.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Home — medium. Celebration-first, with a snippet of today's Gospel filling
    // the body (the dedicated Gospel widget makes the verse the hero instead).
    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            colorEyebrow
            Text(day?.celebration ?? "Today")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(LumenWidget.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let verse = day?.gospelText, !verse.isEmpty {
                Text(verse.quotedForDisplay)
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(LumenWidget.inkSoft)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
            HStack {
                if let season = day?.season {
                    Text([season, day?.cycle].compactMap { $0 }.joined(separator: " · "))
                        .font(.system(.caption))
                        .foregroundStyle(LumenWidget.inkSoft)
                }
                Spacer()
                if let citation = day?.gospelCitation {
                    Text("Gospel · \(citation)")
                        .font(.system(.caption2))
                        .foregroundStyle(LumenWidget.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Lock screen — rectangular. Rank + season share one compact eyebrow so the
    // celebration gets two full lines (long names like "Immaculate Heart of the
    // Blessed Virgin Mary" otherwise truncate to one line).
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text([rankLabel, day?.season].compactMap { $0 }.joined(separator: " · ").uppercased())
                .font(.system(.caption2).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(day?.celebration ?? "Today")
                .font(.system(.subheadline, design: .serif).weight(.medium))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetAccentable()
    }

    // Lock screen — inline (single line beside the clock)
    private var inline: some View {
        Text("\(rankLabel) · \(day?.celebration ?? "Today")")
    }

    // Shared: colored rank eyebrow (the liturgical color is the visual)
    private var colorEyebrow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LumenWidget.liturgicalColor(day?.color))
                .frame(width: 8, height: 8)
            Text(rankLabel.uppercased())
                .font(.system(.caption2).weight(.semibold))
                .foregroundStyle(LumenWidget.liturgicalColor(day?.color))
                .tracking(0.5)
        }
    }

    private var rankLabel: String {
        switch day?.rank {
        case "SOLEMNITY":    return "Solemnity"
        case "FEAST":        return "Feast"
        case "MEMORIAL":     return "Memorial"
        case "OPT_MEMORIAL": return "Optional Memorial"
        case "SUNDAY":       return "Sunday"
        default:             return "Weekday"
        }
    }
}

#Preview(as: .systemSmall) {
    BlissfulTodayWidget()
} timeline: {
    LiturgyEntry(date: .now, day: .preview)
}
