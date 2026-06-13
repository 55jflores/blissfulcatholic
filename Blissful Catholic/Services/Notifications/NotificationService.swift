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
    private static let realDays = 7        // days of prefetched real Gospel content
    private static let fallbackDays = 7    // generic-copy tail (survives offline + lapsed users)

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
        // Idempotent reset — also covers the "turned off" case.
        let pending = await center.pendingNotificationRequests()
        let staleIDs = pending.map(\.identifier).filter { $0.hasPrefix(Self.gospelPrefix) }
        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
        }

        guard settings.gospelEnabled else { return }
        await refreshAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        let cal = Calendar.current
        let now = Date()

        for offset in 0..<(Self.realDays + Self.fallbackDays) {
            guard let date = cal.date(byAdding: .day, value: offset, to: now) else { continue }

            // Fire at the chosen hour:minute on `date`; skip if already past.
            var fireComps = cal.dateComponents([.year, .month, .day], from: date)
            fireComps.hour = settings.gospelHour
            fireComps.minute = settings.gospelMinute
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
