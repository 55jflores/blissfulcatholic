//
//  DailyReflectionStore.swift
//  Blissful Catholic
//
//  Fetches and caches today's AI-generated devotional reflection on the day's
//  Gospel. Cache lives in UserDefaults — small, simple, no schema; regenerates
//  when the date changes.
//
//  Calls the `daily` feature on /api/ai (FREE tier per backend FEATURE_PROMPTS).
//  When Phase 5 lands, we'd promote this to a Plus-gated feature key — but the
//  call signature here doesn't change, only the backend gating.
//

import Foundation

@MainActor
@Observable
final class DailyReflectionStore {
    static let shared = DailyReflectionStore()

    enum Phase: Equatable {
        case idle           // not yet attempted (e.g. liturgy not loaded yet)
        case loading        // call in flight
        case ready          // `reflection` is populated and current
        case error(String)  // call failed; reflection may still hold yesterday's
        case signedOut      // can't call /api/ai without an access token
    }

    private(set) var reflection: DailyReflection?
    private(set) var phase: Phase = .idle

    private let userDefaultsKey = "dailyReflection.v1"
    private var loadTask: Task<Void, Never>?

    private init() {
        // Pre-populate from disk so the card can render immediately on launch
        // even before the network round-trip resolves.
        if let cached = loadFromDisk() {
            reflection = cached
            phase = .ready
        }
    }

    // MARK: - Public API

    /// Loads today's reflection if not already present. Idempotent on the same
    /// date — safe to call repeatedly from `.task` modifiers. Cancels any
    /// in-flight task for a stale date.
    func loadIfNeeded(
        date: String,
        gospelCitation: String,
        gospelText: String,
        token: String?,
        personalization: String?
    ) async {
        // Already have today's reflection in memory — no work.
        if let r = reflection, r.date == date, phase == .ready { return }

        // Disk hit for today — restore without a network call.
        if let cached = loadFromDisk(), cached.date == date {
            reflection = cached
            phase = .ready
            return
        }

        // From here we need to call the AI.
        guard let token else {
            phase = .signedOut
            return
        }
        guard !gospelText.isEmpty else {
            // Gospel hasn't resolved yet (BibleService still loading webce.json).
            // Bail; the caller will re-invoke once verses arrive.
            return
        }

        loadTask?.cancel()
        phase = .loading
        let prompt = Self.buildPrompt(citation: gospelCitation, gospelText: gospelText)

        loadTask = Task {
            do {
                var accumulated = ""
                let stream = AIService.shared.stream(
                    feature: "daily",
                    messages: [["role": "user", "content": prompt]],
                    personalization: personalization,
                    token: token
                )
                for try await chunk in stream {
                    accumulated += chunk
                }
                guard !Task.isCancelled else { return }
                let new = DailyReflection(
                    date: date,
                    gospelCitation: gospelCitation,
                    body: accumulated.trimmingCharacters(in: .whitespacesAndNewlines),
                    generatedAt: Date()
                )
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

    /// Forget the cached reflection. Useful when the user signs out (so the
    /// next signed-in user doesn't see someone else's reflection) and for any
    /// future pull-to-refresh.
    func reset() {
        loadTask?.cancel()
        loadTask = nil
        reflection = nil
        phase = .idle
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Prompt

    private static func buildPrompt(citation: String, gospelText: String) -> String {
        """
        Write a short Catholic devotional reflection — about 150 to 180 words, in two short paragraphs — on today's Gospel:

        \(citation)

        "\(gospelText)"

        Tone: warm, prayerful, lectionary-grounded. Address the reader directly ("you"). Surface one specific insight from the passage, then offer a brief invitation to prayer or to a small, concrete spiritual step. Avoid clichés and hedging. Do not begin with a title.
        """
    }

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
