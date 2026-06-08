//
//  PodcastModels.swift
//  Blissful Catholic
//
//  Plain value types for the podcast simulation: one Podcast (channel) holding
//  its Episodes (items), decoded from an open RSS feed. No SwiftData yet — this
//  is the single-podcast "full pass" (see docs/podcast-flow.md); persistence,
//  downloads, and a queue come later.
//

import Foundation

struct Podcast: Equatable {
    let title: String
    let author: String
    let artworkURL: URL?
    let episodes: [Episode]
}

struct Episode: Identifiable, Equatable {
    /// The episode's <guid> when present, else its audio URL — stable enough to
    /// identify a row and (later) persist a resume position against.
    let id: String
    let title: String
    let summary: String
    /// The <enclosure> URL — the actual audio. Played VERBATIM so the feed's
    /// measurement prefix (Podtrac/Chartable/etc.) still counts the download for
    /// the podcaster. Never rewrite or strip this.
    let audioURL: URL
    /// Raw <itunes:duration> — "28:43" or "1723" (seconds). Display-only for now.
    let duration: String
    let publishedAt: Date?

    /// "28:43" stays as-is; bare seconds ("1723") render as "28 min".
    var durationLabel: String {
        if duration.contains(":") { return duration }
        if let secs = Int(duration) { return "\(max(1, secs / 60)) min" }
        return duration
    }

    /// "Jun 6" — compact published date, empty when the feed omits it.
    var dateLabel: String {
        guard let publishedAt else { return "" }
        return publishedAt.formatted(.dateTime.month(.abbreviated).day())
    }
}
