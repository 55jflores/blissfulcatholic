//
//  PodcastProgressStore.swift
//  Blissful Catholic
//
//  "Where you left off" for each episode — a per-episode resume pointer, so
//  reopening Day 157 picks up mid-episode while a fresh episode starts at 0.
//  Mirrors RosaryProgressStore's approach (transient UI state in UserDefaults),
//  but keyed by episode id since a feed has many episodes. An in-memory cache
//  keeps the per-tick reads cheap; finished episodes are cleared so they restart.
//

import Foundation

struct EpisodeProgress: Codable, Equatable {
    var seconds: Double
    var duration: Double
    var updatedAt: Date

    var fraction: Double { duration > 0 ? min(1, max(0, seconds / duration)) : 0 }
    /// Treat the last few seconds as "done" so we don't resume at the very end.
    var isFinished: Bool { duration > 0 && seconds >= duration - 5 }
    var secondsRemaining: Double { max(0, duration - seconds) }
}

@MainActor
enum PodcastProgressStore {
    private static let key = "podcast.progress"
    private static var cache: [String: EpisodeProgress]?

    private static func all() -> [String: EpisodeProgress] {
        if let cache { return cache }
        let loaded = UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([String: EpisodeProgress].self, from: $0) } ?? [:]
        cache = loaded
        return loaded
    }

    static func position(for id: String) -> EpisodeProgress? { all()[id] }

    static func save(id: String, seconds: Double, duration: Double) {
        var dict = all()
        dict[id] = EpisodeProgress(seconds: seconds, duration: duration, updatedAt: .now)
        persist(dict)
    }

    static func clear(id: String) {
        var dict = all()
        guard dict[id] != nil else { return }
        dict[id] = nil
        persist(dict)
    }

    private static func persist(_ dict: [String: EpisodeProgress]) {
        cache = dict
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
