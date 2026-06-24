//
//  DailyReflectionStore.swift
//  Blissful Catholic
//
//  Fetches and caches the day's shared reflection on the Gospel. The reflection
//  is pre-generated server-side (a daily cron) and served from
//  /api/daily-reflection — so the card loads instantly, with no per-open AI call
//  and no cold-start timeout. Personalization lives in the separate "Reflect with
//  your companion" sheet, not here.
//
//  Cache lives in UserDefaults — small, simple, no schema; regenerates when the
//  date changes.
//

import Foundation

@MainActor
@Observable
final class DailyReflectionStore {
    static let shared = DailyReflectionStore()

    enum Phase: Equatable {
        case idle           // not yet attempted (e.g. liturgy not loaded yet)
        case loading        // fetch in flight
        case ready          // `reflection` is populated and current
        case error(String)  // fetch failed; reflection may still hold yesterday's
    }

    private(set) var reflection: DailyReflection?
    private(set) var phase: Phase = .idle

    private let userDefaultsKey = "dailyReflection.v1"
    private var loadTask: Task<Void, Never>?

    /// The public endpoint serving the pre-generated reflection.
    private let endpoint = SupabaseConfig.apiBaseURL.appending(path: "api/daily-reflection")

    private init() {
        // Pre-populate from disk so the card can render immediately on launch
        // even before the network round-trip resolves.
        if let cached = loadFromDisk() {
            reflection = cached
            phase = .ready
        }
    }

    // MARK: - Public API

    /// Loads the reflection for `date` if not already present. Idempotent on the
    /// same date — safe to call repeatedly from `.task` modifiers. Cancels any
    /// in-flight fetch for a stale date.
    func loadIfNeeded(date: String) async {
        // Already have today's reflection in memory — no work.
        if let r = reflection, r.date == date, phase == .ready { return }

        // Disk hit for today — restore without a network call.
        if let cached = loadFromDisk(), cached.date == date {
            reflection = cached
            phase = .ready
            return
        }

        loadTask?.cancel()
        phase = .loading

        loadTask = Task {
            do {
                let new = try await fetch(date: date)
                guard !Task.isCancelled else { return }
                self.reflection = new
                self.phase = .ready
                self.saveToDisk(new)
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                self.phase = .error(message)
            }
        }
        await loadTask?.value
    }

    /// Forget the cached reflection. Useful for a future pull-to-refresh.
    func reset() {
        loadTask?.cancel()
        loadTask = nil
        reflection = nil
        phase = .idle
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Network

    private enum FetchError: LocalizedError {
        case notReady
        case server(Int)

        var errorDescription: String? {
            switch self {
            case .notReady:         return "Today's reflection is on its way."
            case .server(let code): return "Couldn't reach the server (\(code))."
            }
        }
    }

    private func fetch(date: String) async throws -> DailyReflection {
        var comps = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "date", value: date)]
        var request = URLRequest(url: comps.url!)
        // The CDN caches at the edge; skip the device cache so a same-day refresh
        // (e.g. after the cron backfills) isn't masked by a stale local copy.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200:  return try Self.networkDecoder.decode(DailyReflection.self, from: data)
        case 404:  throw FetchError.notReady
        default:   throw FetchError.server(status)
        }
    }

    /// Server sends `generatedAt` as ISO-8601 (with fractional seconds); the disk
    /// cache uses the default numeric Date encoding, so they need separate coders.
    private static let networkDecoder: JSONDecoder = {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let s = try d.singleValueContainer().decode(String.self)
            if let date = withFractional.date(from: s) ?? plain.date(from: s) { return date }
            throw DecodingError.dataCorrupted(.init(
                codingPath: d.codingPath, debugDescription: "Unparseable date: \(s)"))
        }
        return decoder
    }()

    // MARK: - Disk cache

    private func loadFromDisk() -> DailyReflection? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(DailyReflection.self, from: data)
    }

    private func saveToDisk(_ r: DailyReflection) {
        if let data = try? JSONEncoder().encode(r) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
