# Notifications — master schedule

The single reference for **every** notification the app sends, when it fires, and
at what time. All times are **device-local** (the `UNCalendarNotificationTrigger`s
use local wall-clock). Implementation lives in
`Services/Notifications/NotificationService.swift`; detail docs are linked below.

| Notification | Toggle (default) | Fires | Time |
|---|---|---|---|
| **Morning Gospel** | Morning Gospel (**off**) | every day | **8:00 AM** |
| **Holy day — planning** | Holy days of obligation (**on**) | 1 / 3 / 7 days before (user picks; default 3; **skipped if 1**) | **9:00 AM** |
| **Holy day — vigil** | Holy days of obligation (**on**) | the evening before | **4:00 PM** |
| **Fasting/abstinence — day-of** | Fasting & abstinence (**on**) | that morning (Ash Wednesday, Fridays of Lent, Good Friday) | **7:00 AM** |
| **Fasting — eve** | Fasting & abstinence (**on**) | the evening before — **Ash Wednesday & Good Friday only** | **6:00 PM** |

## What's user-configurable

- **On/off** per notification — three toggles in Profile → Reminders.
- **Holy-day lead time** — 1 / 3 / 7 days before (the only timing control).
- Every actual **fire time is fixed in code** (constants in `NotificationService`);
  there is no time picker.

## Notes

- All are **local notifications** — no push server, no entitlement.
- Permission is requested on first opt-in (any toggle); if previously denied, the
  toggle routes the user to iOS Settings.
- Gospel is **opt-in** (default off); holy-day and fasting alerts are **on by
  default** (informational + rare), but only fire once notification permission
  has been granted.
- The Daily-tab discipline **card** is driven by the same rules but is separate
  from these notifications (shown regardless of the toggles) — see the discipline
  doc.

## Detail docs

- [`notification-gospel-verse.md`](./notification-gospel-verse.md) — the daily
  Gospel verse: rolling 7-day prefetch window, content/fallback, edge cases.
- [`liturgical-discipline.md`](./liturgical-discipline.md) — the holy-day and
  fasting rules (the `LiturgicalDiscipline` type), the Daily card, and the
  notification wiring.
