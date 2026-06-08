//
//  PodcastSeed.swift
//  Blissful Catholic
//
//  The hardcoded curated entry for the single-podcast simulation. The real
//  feature would resolve many shows via Apple's free iTunes Lookup API
//  (id → feedUrl); for this pass we paste one verified feedUrl directly.
//
//  How this URL was obtained (one-time, out of app):
//    curl "https://itunes.apple.com/search?term=bible+in+a+year+fr+mike+schmitz&entity=podcast"
//    → results[0].feedUrl
//

import Foundation

/// How much of a feed to display. A daily 365-day series (like Bible in a Year)
/// wants the current year's run; an ordinary show just wants the latest few.
enum EpisodeWindow: Equatable {
    case all
    case currentYear          // today back to Jan 1 of this year
    case recent(Int)
}

struct PodcastFeed {
    let name: String
    let feedURL: URL
    var window: EpisodeWindow = .recent(100)
}

enum PodcastSeed {
    /// Fr. Mike Schmitz — priest-hosted, orthodox, #1 Catholic podcast. It's a
    /// 365-day daily series, but the feed accumulates EVERY year's run (1,700+
    /// episodes back to 2021, each titled "Day N (YYYY)"). So we window to the
    /// current year: today → Jan 1 (~Day N plus a couple of bonus checkpoints).
    static let bibleInAYear = PodcastFeed(
        name: "The Bible in a Year (with Fr. Mike Schmitz)",
        feedURL: URL(string: "https://feeds.fireside.fm/bibleinayear/rss")!,
        window: .currentYear
    )
}
