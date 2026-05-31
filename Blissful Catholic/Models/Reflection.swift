//
//  Reflection.swift
//  Blissful Catholic
//
//  Today's AI-generated reflection on the day's Gospel. Cached per-day in
//  UserDefaults so the home screen renders instantly on repeat opens, and
//  regenerated when the date rolls over.
//

import Foundation

nonisolated struct DailyReflection: Codable, Hashable, Sendable {
    /// YYYY-MM-DD this reflection was generated for.
    let date: String
    /// The Gospel citation it was grounded in (e.g. "Mark 11:11-26").
    let gospelCitation: String
    /// Full body text. Plain prose, paragraphs separated by "\n\n".
    let body: String
    /// When the reflection was generated (so we can age it / show a relative
    /// timestamp later if we want).
    let generatedAt: Date
}
