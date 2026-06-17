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
    /// Morning Gospel verse-of-the-day reminder (fixed 8 AM — see NotificationService).
    var gospelEnabled: Bool = false

    /// Holy day of obligation alerts (a planning notice + a vigil-aware one the
    /// evening before). Informational + rare, so on by default.
    var holyDayEnabled: Bool = true
    var holyDayLeadDays: Int = 3  // 1 / 3 / 7: how many days before to send the advance planning notice

    /// Fasting / abstinence alerts (Ash Wednesday, Fridays of Lent, Good Friday).
    var fastingEnabled: Bool = true

    static let `default` = ReminderSettings()
}

extension ReminderSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case gospelEnabled
        case holyDayEnabled, holyDayLeadDays, fastingEnabled
    }

    /// Resilient decode: any missing key falls back to its property default, so
    /// adding new notification toggles later won't make old stored settings fail
    /// to decode (synthesized Codable throws `keyNotFound`, which would wipe a
    /// user's existing reminder preferences back to defaults).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReminderSettings.default
        gospelEnabled = try c.decodeIfPresent(Bool.self, forKey: .gospelEnabled) ?? d.gospelEnabled
        holyDayEnabled = try c.decodeIfPresent(Bool.self, forKey: .holyDayEnabled) ?? d.holyDayEnabled
        holyDayLeadDays = try c.decodeIfPresent(Int.self, forKey: .holyDayLeadDays) ?? d.holyDayLeadDays
        fastingEnabled = try c.decodeIfPresent(Bool.self, forKey: .fastingEnabled) ?? d.fastingEnabled
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
