//
//  NotificationService.swift
//  Blissful Catholic
//
//  Owns the local notification system. v1 schedules the daily Gospel verse — a
//  rolling window of real prefetched content (the next ~7 days' Mass Gospel)
//  plus a generic fallback tail, re-rolled on every app foreground/background.
//  See docs/notification-gospel-verse.md for the full design + edge-case matrix.
//
//  All local notifications — no push server, no entitlement, no Info.plist key.
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject {
    static let shared = NotificationService()

    /// Latest known authorization status — refreshed on launch and after every
    /// request. The Profile reminder UI reads this to show "Enable in Settings".
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Set once at app launch so a cold-launch tap can route into the UI.
    @ObservationIgnored weak var router: NotificationRouter?

    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    private static let gospelPrefix = "daily.gospel."
    private static let gospelHour = 8      // fixed morning Gospel reminder time (local)
    private static let realDays = 7        // days of prefetched real Gospel content
    private static let fallbackDays = 7    // generic-copy tail (survives offline + lapsed users)

    private static let disciplinePrefix = "discipline."
    private static let disciplineDaysAhead = 14   // enough to schedule a holy day's lead-time notice

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: Authorization

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    /// Request permission. Call only from the user-initiated opt-in path.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorizationStatus()
        return granted
    }

    // MARK: Scheduling

    /// Rebuild the pending Gospel notifications from settings + the next week of
    /// readings. Idempotent: clears every `daily.gospel.*` request, then (if
    /// enabled + authorized) reschedules the rolling window. Safe to call often —
    /// it runs on launch, on backgrounding, and on any settings change.
    func refresh(settings: ReminderSettings) async {
        // Idempotent reset of everything we manage — also covers the "turned off" case.
        let pending = await center.pendingNotificationRequests()
        let staleIDs = pending.map(\.identifier).filter {
            $0.hasPrefix(Self.gospelPrefix) || $0.hasPrefix(Self.disciplinePrefix)
        }
        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
        }

        await refreshAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        if settings.gospelEnabled { await scheduleGospel() }
        if settings.holyDayEnabled || settings.fastingEnabled { await scheduleDiscipline(settings: settings) }
    }

    // MARK: Gospel verse

    private func scheduleGospel() async {
        let cal = Calendar.current
        let now = Date()

        for offset in 0..<(Self.realDays + Self.fallbackDays) {
            guard let date = cal.date(byAdding: .day, value: offset, to: now) else { continue }

            // Fire at the fixed Gospel hour on `date`; skip if already past.
            var fireComps = cal.dateComponents([.year, .month, .day], from: date)
            fireComps.hour = Self.gospelHour
            fireComps.minute = 0
            guard let fireDate = cal.date(from: fireComps), fireDate > now else { continue }

            let dateString = LiturgyStore.dateString(for: date)
            let content: GospelReminderContent
            if offset < Self.realDays {
                let day = await LiturgyStore.fetchDay(dateString: dateString)
                content = await GospelReminderContent.make(for: day)
            } else {
                content = .generic
            }

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.gospelPrefix)\(dateString)",
                content: notificationContent(from: content),
                trigger: trigger)
            try? await center.add(request)
        }
    }

    // MARK: Holy days & fasting

    /// Walk the look-ahead window; for each holy day of obligation schedule a
    /// planning notice (`holyDayLeadDays` before, 9 AM) + a vigil-aware notice
    /// (evening before, 5 PM); for each penitential day schedule a morning-of
    /// notice (7 AM). Drives off the pure LiturgicalDiscipline rules.
    private func scheduleDiscipline(settings: ReminderSettings) async {
        let cal = Calendar.current
        let now = Date()

        for offset in 0..<Self.disciplineDaysAhead {
            guard let date = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = LiturgyStore.dateString(for: date)

            if settings.holyDayEnabled, let hd = LiturgicalDiscipline.holyDayOfObligation(on: date) {
                // Advance planning notice at the chosen lead. Skipped when lead == 1,
                // since it would collide with the evening-before vigil notice below.
                if settings.holyDayLeadDays > 1,
                   let plan = cal.date(byAdding: .day, value: -settings.holyDayLeadDays, to: date) {
                    await schedule(on: plan, hour: 9, minute: 0, now: now,
                                   id: "\(Self.disciplinePrefix)holyday.plan.\(key)",
                                   title: hd.name,
                                   body: "In \(settings.holyDayLeadDays) days — a holy day of obligation. Plan to attend Mass.")
                }
                // Vigil-aware notice, evening before (4 PM — early enough to catch
                // an evening vigil Mass).
                if let eve = cal.date(byAdding: .day, value: -1, to: date) {
                    await schedule(on: eve, hour: 16, minute: 0, now: now,
                                   id: "\(Self.disciplinePrefix)holyday.eve.\(key)",
                                   title: hd.name,
                                   body: "Tomorrow — a holy day of obligation. A vigil Mass this evening, or Mass tomorrow, fulfills it.")
                }
            }

            if settings.fastingEnabled, let pen = LiturgicalDiscipline.penitential(on: date) {
                // Morning of.
                await schedule(on: date, hour: 7, minute: 0, now: now,
                               id: "\(Self.disciplinePrefix)fasting.\(key)",
                               title: pen.name,
                               body: pen.summary)
                // Evening-before heads-up for the two fasting days people plan
                // around (Ash Wednesday / Good Friday) — 6 PM, when they're
                // home planning the next day.
                if pen.fasting, let eve = cal.date(byAdding: .day, value: -1, to: date) {
                    await schedule(on: eve, hour: 18, minute: 0, now: now,
                                   id: "\(Self.disciplinePrefix)fasting.eve.\(key)",
                                   title: "Tomorrow: \(pen.name)",
                                   body: pen.summary)
                }
            }
        }
    }

    /// Schedule one fixed-text notification at `hour:minute` on `date`, skipping
    /// if that fire time is already past.
    private func schedule(on date: Date, hour: Int, minute: Int, now: Date,
                          id: String, title: String, body: String) async {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        guard let fire = cal.date(from: comps), fire > now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["route": "daily"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
            repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func notificationContent(from content: GospelReminderContent) -> UNMutableNotificationContent {
        let notif = UNMutableNotificationContent()
        notif.title = content.title
        notif.body = content.body
        notif.sound = .default
        notif.userInfo = ["route": "daily"]
        return notif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// v1: show the banner even in-foreground — harmless and makes testing real.
    /// (Can suppress-when-already-on-Daily later.) Completion-handler variant is
    /// used deliberately — it bridges to the ObjC delegate reliably; without a
    /// returned option set iOS silently drops foreground notifications.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    /// A tap routes to today's Daily — always live data, never a stale snapshot.
    /// Hops to the main actor to touch the router; completion handler is called
    /// immediately so the system isn't left waiting on the navigation.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let route = response.notification.request.content.userInfo["route"] as? String
        if route == "daily" {
            Task { @MainActor in self.router?.route = .daily }
        }
        completionHandler()
    }
}
