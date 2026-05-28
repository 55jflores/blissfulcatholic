//
//  DomainModels.swift
//  Blissful Catholic
//
//  Plain value types for content the app displays. In Phase 1 these are filled
//  from hardcoded SampleData; in Phase 4 they come from bundled JSON + the API.
//

import Foundation

/// A saint for the "Saint of the day" feature.
struct Saint: Identifiable, Codable {
    let id: UUID
    let name: String
    /// e.g. "Memorial", "Optional memorial", "Feast".
    let rank: String
    /// e.g. "1515 – 1595".
    let years: String
    let patronage: String
    /// A few sentences of biography.
    let biography: String
    /// A short, warm reflection to carry into the day.
    let reflection: String

    init(id: UUID = UUID(), name: String, rank: String, years: String,
         patronage: String, biography: String, reflection: String) {
        self.id = id
        self.name = name
        self.rank = rank
        self.years = years
        self.patronage = patronage
        self.biography = biography
        self.reflection = reflection
    }
}

/// One of the day's Mass readings.
struct ScriptureReading: Identifiable, Codable {
    let id: UUID
    /// e.g. "First reading", "Responsorial psalm", "Gospel".
    let label: String
    /// e.g. "John 16:23b–28".
    let citation: String
    let excerpt: String

    init(id: UUID = UUID(), label: String, citation: String, excerpt: String) {
        self.id = id
        self.label = label
        self.citation = citation
        self.excerpt = excerpt
    }
}

/// A short daily invitation to prayer or reflection.
struct DailyPrompt: Identifiable, Codable {
    let id: UUID
    let text: String
    /// Which feature this prompt invites the user into.
    let feature: AppFeature

    init(id: UUID = UUID(), text: String, feature: AppFeature) {
        self.id = id
        self.text = text
        self.feature = feature
    }
}

/// Everything the Daily home needs for a given day.
struct DailyContext {
    let date: Date
    let season: LiturgicalSeason
    let feastTitle: String
    let saint: Saint
    let readings: [ScriptureReading]
    let prompt: DailyPrompt
}
