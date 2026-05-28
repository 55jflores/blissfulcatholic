//
//  PreviewSupport.swift
//  Blissful Catholic
//
//  An in-memory SwiftData container seeded with sample data, for SwiftUI
//  previews that use @Query.
//

import SwiftData
import Foundation

@MainActor
enum PreviewSupport {
    static let container: ModelContainer = {
        let schema = Schema(AppSchema.models)
        let container = try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        seed(container.mainContext)
        return container
    }()

    private static func seed(_ ctx: ModelContext) {
        let cal = Calendar.current

        let entries: [(Int, String, String)] = [
            (1, "Examen", "On surrender\nI noticed today how often I clutch — at outcomes, at people."),
            (3, "Confession prep", "Three weeks since my last. Areas to examine: speech, patience with the kids."),
            (6, "Gratitude", "Three things\nThe lilacs by the side door. A long phone call with Anna."),
        ]
        for (daysAgo, tag, content) in entries {
            let e = JournalEntry()
            e.date = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
            e.tag = tag
            e.content = content
            ctx.insert(e)
        }

        for daysAgo in [0, 1, 2, 4, 5, 7, 8, 9, 10] {
            let r = RosaryLog()
            r.date = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
            r.mysteries = .glorious
            r.completed = true
            ctx.insert(r)
        }
        try? ctx.save()
    }
}
