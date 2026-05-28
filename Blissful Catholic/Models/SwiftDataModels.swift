//
//  SwiftDataModels.swift
//  Blissful Catholic
//
//  The persisted models. Designed CloudKit-compatible from the start (every
//  property optional or defaulted, no `.unique` constraints, Codable enums) so
//  enabling CloudKit later is close to a one-line change — see [[phase2-swiftdata]].
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String = ""
    var stateInLife: StateInLife?
    var faithMaturity: FaithMaturity?
    var background: CatholicBackground?
    var onboardingComplete: Bool = false
    var createdAt: Date = Date.now

    init() {}
}

@Model
final class JournalEntry {
    var date: Date = Date.now
    var content: String = ""
    /// The chip the user tagged this with ("Examen", "Gratitude", …).
    var tag: String = ""
    var feature: AppFeature = AppFeature.journal
    var extractedThemes: [String] = []
    var liturgicalSeason: LiturgicalSeason = LiturgicalSeason.ordinaryTime
    var feastDay: String?

    init() {}

    /// First line of the content, for the entry list title.
    var derivedTitle: String {
        let firstLine = content
            .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
            .first.map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return tag.isEmpty ? "Untitled entry" : tag }
        return String(trimmed.prefix(60))
    }

    /// The content after the first line, for the entry list preview.
    var derivedPreview: String {
        let parts = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
        return parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }
}

@Model
final class PrayerSession {
    var date: Date = Date.now
    var feature: AppFeature = AppFeature.rosary
    var durationSeconds: Int = 0
    var completed: Bool = false
    var notes: String?

    init() {}
}

@Model
final class RosaryLog {
    var date: Date = Date.now
    var mysteries: MysterySet = MysterySet.joyful
    var intentions: [String] = []
    var completed: Bool = false

    init() {}
}

@Model
final class SpiritualInsight {
    var generatedDate: Date = Date.now
    var themes: [String] = []
    var struggles: [String] = []
    var graces: [String] = []
    var sourceFeature: AppFeature = AppFeature.journal

    init() {}
}

@Model
final class ConfessionLog {
    var date: Date = Date.now
    var notes: String?   // optional; UI arrives in Phase 4

    init() {}
}

/// All persisted model types, in one place for the container + previews.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        UserProfile.self, JournalEntry.self, PrayerSession.self,
        RosaryLog.self, SpiritualInsight.self, ConfessionLog.self,
    ]
}
