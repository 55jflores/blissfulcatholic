//
//  RosaryProgress.swift
//  Blissful Catholic
//
//  A lightweight "where you left off" pointer for the Rosary — the one paused,
//  unfinished session. Stored in UserDefaults (transient UI state, not prayer
//  history); completed rosaries are logged separately as RosaryLog.
//

import Foundation

struct RosaryProgress: Codable, Hashable {
    var mysteryRaw: String
    var index: Int
    var savedAt: Date

    var mystery: MysterySet { MysterySet(rawValue: mysteryRaw) ?? .joyful }
}

enum RosaryProgressStore {
    private static let key = "rosary.inProgress"

    static func save(mystery: MysterySet, index: Int) {
        let progress = RosaryProgress(mysteryRaw: mystery.rawValue, index: index, savedAt: .now)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> RosaryProgress? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(RosaryProgress.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
