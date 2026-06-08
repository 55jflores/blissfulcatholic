//
//  PodcastStore.swift
//  Blissful Catholic
//
//  Loads one podcast: fetch the RSS feed, parse it off-main, publish a Podcast.
//  Mirrors LiturgyStore's @MainActor @Observable + URLSession shape. Graceful on
//  failure — the view shows a retry, never crashes.
//

import Foundation

@MainActor
@Observable
final class PodcastStore {
    private(set) var podcast: Podcast?
    private(set) var isLoading = false
    private(set) var loadFailed = false

    /// Identifies our app in the podcaster's analytics. Good etiquette + lets
    /// creators see Blissful Catholic in their host/third-party stats.
    private static let userAgent = "BlissfulCatholic/1.0 (+https://blissfulcatholic.com)"

    func load(_ feed: PodcastFeed) async {
        if isLoading { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }

        var request = URLRequest(url: feed.feedURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadRevalidatingCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                loadFailed = true; return
            }
            // 8 MB+ feeds parse noticeably — keep it off the main actor.
            let name = feed.name
            let (since, maxEpisodes) = Self.resolve(feed.window)
            let parsed = await Task.detached(priority: .userInitiated) {
                RSSPodcastParser.parse(data, feedName: name, since: since, maxEpisodes: maxEpisodes)
            }.value
            if let parsed { podcast = parsed } else { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }

    /// Turn a display window into concrete parser bounds: a cutoff date and a
    /// hard cap. `.currentYear` cuts at Jan 1 of this year (today → Jan 1).
    private static func resolve(_ window: EpisodeWindow) -> (since: Date?, max: Int) {
        switch window {
        case .all:
            return (nil, 2000)
        case .currentYear:
            let cal = Calendar(identifier: .gregorian)
            let year = cal.component(.year, from: Date())
            let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))
            return (jan1, 500)
        case .recent(let n):
            return (nil, n)
        }
    }
}
