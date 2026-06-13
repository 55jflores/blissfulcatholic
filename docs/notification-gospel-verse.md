# Daily Gospel Verse Notification — Implementation Plan

The first of the Tier‑1 notifications (see notification strategy discussion). A
**Gospel verse of the day** drawn from the *actual Mass readings* — the Catholic
differentiator versus YouVersion's curated/editorial single global verse. All
**local** notifications (`UNUserNotificationCenter`); no push server, no new
backend, no entitlement.

The core trick: local notifications are scheduled *ahead of time* with content
baked in, so we **prefetch the next ~7 days of readings and schedule them**, then
re‑roll that window every time the app foregrounds/backgrounds.

---

## 1. Component architecture

```
┌───────────────────────────────────────────────────────────────────┐
│  Blissful_CatholicApp (entry)                                       │
│   • init(): NotificationService.shared.router = notificationRouter  │
│   • .task → refresh()        (re-roll window on launch)             │
│   • scenePhase → .background → refresh()   (re-roll on leaving)     │
└───────────────┬───────────────────────────────────┬───────────────┘
                │                                     │
                ▼                                     ▼
   ┌──────────────────────────┐         ┌────────────────────────────┐
   │ NotificationService      │◄────────│ ReminderSettings (store)   │
   │ @MainActor, NSObject     │         │  UserDefaults:             │
   │  • requestAuthorization()│         │   gospelEnabled / hour / min│
   │  • refresh(settings:)    │         └────────────────────────────┘
   │  • UNUserNotif delegate  │
   └───┬────────────┬─────────┘
       │            │
       ▼            ▼
  LiturgyStore    BibleService
  .fetchDay(      .verses(
   dateString:)    forCitation:)
       │            │
       ▼            ▼
  GET /api/liturgy  bundled WEBCE JSON
  (Gospel citation) (verse text)
       │            │
       └─────┬──────┘
             ▼
   GospelReminderContent.make(for: day)
     → (title, body)  — real verse, or generic fallback
             │
             ▼
   UNUserNotificationCenter
     schedules N one-shot UNCalendarNotificationTriggers
     id = "daily.gospel.<yyyy-MM-dd>"
             │ (user taps)
             ▼
   NotificationRouter.route = .daily
             │
             ▼
   MainTabView.onChange → selection = .daily   (Daily shows the verse hero)
```

**New files** (`Services/Notifications/`): `NotificationService.swift`,
`ReminderSettings.swift`, `GospelReminderContent.swift`, `NotificationRouter.swift`.
**Touched:** `LiturgyStore` (add stateless `fetchDay`), `Blissful_CatholicApp`
(wire), `MainTabView` (deep-link), `ProfileView` (Reminders settings section).

---

## 2. The scheduling window

```
  now
   │
   ▼
  D0    D1   D2   D3   D4   D5   D6  │  D7   D8  …  D13  │  D14+
 ───────────────────────────────────│──────────────────│────────
 [ real Gospel verse — prefetched ] │ [ generic copy ] │  (none)
  skip                               │                  │
  if 8 AM                            │  insurance tail  │ silent until
  already                            │  (needs no       │ next app open
  passed                             │   network)       │ (then re-rolls)
```

- **Real tier (D0–D6):** one liturgy fetch + verse resolve per day, content baked in.
- **Fallback tier (D7–D13):** evergreen copy, no network — survives offline + the
  day‑8 "user never opened the app" case so the reminder never goes fully dark.
- **Budget:** ~14 of iOS's 64 pending‑notification cap. Comfortable.

The window is a **rolling buffer, not a countdown.** Every app open re‑centers it
on the current date, so an active user never sees the fallback tier at all.

---

## 3. Refresh lifecycle — what re-rolls the window

| Trigger | When | Effect |
|---|---|---|
| `.task` on root view | every app launch | clear + rebuild window from today |
| `scenePhase → .background` | user leaves the app | clear + rebuild (queue fresh on exit) |
| Settings toggle / time change | user edits in Profile | rebuild immediately |
| Permission granted | first opt-in | initial schedule |

`refresh()` is **idempotent**: remove every pending `daily.gospel.*` request, then
reschedule. Stable per-day IDs (`daily.gospel.2026-06-12`) mean no duplicates.

---

## 4. End-to-end flow (one refresh)

```
refresh(settings)
  │
  ├─ remove all pending "daily.gospel.*"          (idempotent reset)
  ├─ guard settings.gospelEnabled                 (else: stop — stays cleared)
  ├─ guard authorizationStatus == .authorized     (else: stop quietly)
  │
  └─ for offset in 0..<14:
        date      = today + offset
        fireDate  = date @ settings.hour:minute
        guard fireDate > now                       (skip already-passed times)

        if offset < 7:                             ── real tier
            day     = await LiturgyStore.fetchDay(date)
            content = await GospelReminderContent.make(for: day)
        else:                                      ── fallback tier
            content = GospelReminderContent.fallback

        schedule UNCalendarNotificationTrigger(fireDate, repeats: false)
                 id "daily.gospel.<date>", userInfo ["route": "daily"]
```

`GospelReminderContent.make` degrades in three steps — any failure → generic copy:
`day == nil` (offline) → no Gospel citation (`readings == nil`) → verse resolves
empty (parser/WEBCE miss).

---

## 5. Edge cases & handling

| # | Edge case | Handling | Where |
|---|---|---|---|
| 1 | Reminder time already passed today | `guard fireDate > now` skips D0; schedule from D1 | `refresh()` |
| 2 | Offline at refresh | `fetchDay` → nil → **generic fallback** that day; real content fills on next online refresh | `make()` |
| 3 | Readings feed has no Gospel for a future date (`readings == nil`) | generic fallback for that day (same path as the Daily screen's psalm-lag handling) | `make()` |
| 4 | Gospel citation resolves to empty verses (parser miss / missing in WEBCE) | generic fallback | `make()` |
| 5 | User never opens app for 8+ days | D1–D6 real, D7–D13 generic, D14+ silent; **heals on next open** | window design |
| 6 | Permission not-determined / denied | `refresh()` no-ops on the auth guard; Profile toggle requests, or routes to iOS Settings if denied | `refresh()`, Profile |
| 7 | Permission revoked in iOS Settings later | next refresh's auth check fails → silently stops scheduling; toggle shows "Enable in Settings" | `refresh()`, Profile |
| 8 | Notification fires while app foregrounded | **v1: show banner** (`willPresent → [.banner,.sound]`) — testable + harmless; can suppress-on-Daily later | delegate |
| 9 | Notification tapped days late | routes to **today's** Daily (live data) — never a stale snapshot | `userInfo["route"]` |
| 10 | Cold-launch tap (app not running) | delegate set in `App.init()` so `didReceive` still fires + routes | App init |
| 11 | Midnight rollover / stale queue | re-roll on every foreground + background | lifecycle |
| 12 | Timezone travel / DST | `UNCalendarNotificationTrigger` uses local wall-clock automatically; date↔content remaps on next open | iOS trigger |
| 13 | Duplicate scheduling | clear-then-rebuild + stable daily IDs = idempotent | `refresh()` |
| 14 | iOS 64 pending-notification cap | 7 real + 7 fallback ≈ 14 — well under | window budget |
| 15 | Toggle off | `refresh()` clears all `daily.gospel.*`; nothing fires | `refresh()` |
| 16 | Very long first verse | trim to ~120 chars + ellipsis for a clean banner | `make()` |
| 17 | DEBUG date override (`LiturgyStore`) | only affects the in-app "today" path; `fetchDay(dateString:)` uses real dates, so scheduling is unaffected | `LiturgyStore` |
| 18 | Testing without waiting until morning | set the reminder a minute ahead, background the app, wait | Profile → Reminders |

---

## 6. Build order

1. `LiturgyStore.fetchDay(dateString:)` + `dateString(for:)` — stateless look-ahead.
2. `ReminderSettings` + store (UserDefaults).
3. `GospelReminderContent.make()` — pure content builder + 3-step degradation.
4. `NotificationService` — permission, `refresh()`, delegate; `NotificationRouter`.
5. Wire `Blissful_CatholicApp` (router + lifecycle) and `MainTabView` (deep-link).
6. Profile **Reminders** section (toggle + time picker) — makes it testable on device.
7. Verify on device by setting the reminder a minute ahead and backgrounding the app.

> Honest caveat: notification scheduling is fiddly to verify — expect an
> iterate-on-device loop (set a time a few minutes out, background the app),
> not a single clean build.
