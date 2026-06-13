//
//  ReminderSettings.swift
//  Blissful Catholic
//
//  User preferences for local reminders, persisted in UserDefaults (same
//  lightweight pattern as BibleReadingStore — transient UI state, not history).
//  v1 covers only the daily Gospel verse; the other Tier-1 reminders (intention,
//  streak, holy-day/fasting) add fields here as they ship — see
//  docs/notification-gospel-verse.md.
//

import Foundation

struct ReminderSettings: Equatable {
    /// Morning Gospel verse-of-the-day reminder.
    var gospelEnabled: Bool = false
    var gospelHour: Int = 8       // 0–23, device-local time
    var gospelMinute: Int = 0     // 0–59

    static let `default` = ReminderSettings()
}

extension ReminderSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case gospelEnabled, gospelHour, gospelMinute
    }

    /// Resilient decode: any missing key falls back to its property default, so
    /// adding new notification toggles later won't make old stored settings fail
    /// to decode (synthesized Codable throws `keyNotFound`, which would wipe a
    /// user's existing reminder preferences back to defaults).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReminderSettings.default
        gospelEnabled = try c.decodeIfPresent(Bool.self, forKey: .gospelEnabled) ?? d.gospelEnabled
        gospelHour = try c.decodeIfPresent(Int.self, forKey: .gospelHour) ?? d.gospelHour
        gospelMinute = try c.decodeIfPresent(Int.self, forKey: .gospelMinute) ?? d.gospelMinute
    }
}

enum ReminderSettingsStore {
    private static let key = "reminders.settings"

    static func load() -> ReminderSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(ReminderSettings.self, from: data)
        else { return .default }
        return settings
    }

    static func save(_ settings: ReminderSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
