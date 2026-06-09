# Podcast Feature — Checkpoint (paused 2026-06-09)

Pausing podcast work here. This is the state-of-play + the prioritized backlog
so a future session can resume without re-deriving anything.

**To resume:** `Read docs/podcast-feature-checkpoint.md and continue the podcast feature.`

Related docs: `docs/podcast-flow.md` (data-flow diagram + file map) ·
`docs/beta-feedback-plan.md` decision #5 (strategy, guardrails, $0 cost,
plays-count-as-downloads).

---

## TL;DR

A working **single-podcast simulation** is built, wired, and committed. It
streams Fr. Mike Schmitz's *The Bible in a Year* end-to-end with the three
highest-value aficionado controls (**speed, per-episode resume, sleep timer**)
and full **background / lock-screen playback**. It is still a *simulation*: one
hardcoded curated feed, no multi-podcast directory, no offline downloads.

Entry point: **Pray tab → "Listen" row** (`PrayRoute.listen`).

---

## What's DONE (all committed)

- **Fetch + parse** — downloads the full RSS feed, parses with Foundation
  `XMLParser` (no FeedKit dependency). Streams the `<enclosure>` URL **verbatim**
  so the feed's Podtrac measurement prefix still counts the download.
- **Current-year window** — feed holds 1,700+ episodes back to 2021; we show
  only this year's run (today → Jan 1, ~166 now → ~370 by December) via a
  `since` date filter + early `abortParsing()` (feed is newest-first, so it
  stops near the top of the file). `LazyVStack` keeps the list cheap as it grows.
- **Background audio + system controls** — `UIBackgroundModes: [audio]` +
  `.playback` session; `MPNowPlayingInfoCenter` (title/show/artwork/scrubber) +
  `MPRemoteCommandCenter` (play/pause/skip ±30/15/scrub) for lock screen,
  Control Center, AirPods, CarPlay. Handles interruptions (calls/Siri) and route
  changes (headphones unplugged → pause).
- **Speed control** — 1× / 1.25× / 1.5× / 1.75× / 2×, tap-to-cycle, **persisted**
  across launches, `.timeDomain` pitch correction (natural voice). Lock-screen
  rate reports true speed so the scrubber tracks.
- **Per-episode resume** — `PodcastProgressStore` (UserDefaults dict by episode
  id, in-memory cache). Saves every ~5s + on pause/switch/background; clears on
  finish. Rows show a progress bar + "N min left"; playing row shows live
  progress.
- **Sleep timer** — 5/15/30/45/60 min + "End of episode", session-only,
  countdown badge, gentle 15s volume fade, pauses (saving resume position).

### File map
```
Services/Podcasts/
  PodcastModels.swift        Podcast + Episode value types
  RSSPodcastParser.swift     XMLParser RSS→Podcast (since-filter + early abort)
  PodcastStore.swift         @Observable fetch/parse; resolves EpisodeWindow
  AudioPlayer.swift          shared AVPlayer engine: background, now-playing,
                             remote commands, speed, resume, sleep timer
  PodcastProgressStore.swift per-episode resume pointers (UserDefaults)
Features/Listen/
  PodcastSeed.swift          the 1 hardcoded feed + EpisodeWindow enum
  PodcastView.swift          screen: header, episode list, states
  PlayerBar.swift            docked mini-player: play/pause, scrubber, speed, sleep
Features/Pray/PrayView.swift  entry point (PrayRoute.listen)
Blissful-Catholic-Info.plist  (UIBackgroundModes audio added via Xcode GUI)
```

---

## What's NEXT (prioritized backlog)

### Tier 1 — still expected by serious listeners
- **Offline downloads** — save the MP3 for offline/airplane; the biggest
  remaining gap. Needs file storage + download manager + per-episode state
  (downloaded/downloading/stream). Pairs with SwiftData for episode records.
- **Variable skip intervals** — let the user choose 10/15/30/45s (currently
  fixed at skip-forward 30 / back 15).

### Tier 2 — "this app gets it"
- **Show-notes detail view** — tap an episode → full description. NOTE: we
  already parse + retain `Episode.summary`; it's unused, waiting for this screen.
- **Smart Speed / trim silence** · **Voice Boost / loudness normalization**.
- **Chapters** — if the feed embeds chapter markers, jump between segments.
- **Queue / Up Next + autoplay-next**.

### Tier 3 — power-user delight
- Bookmarks/clips · mark played/unplayed + filter/sort · per-podcast speed
  defaults · CarPlay · Apple Watch · AirPlay/casting · new-episode notifications.

### Devotional-specific (high value for a daily Scripture series)
- **"Today's episode" quick action** — jump to Day N without scrolling.
- **Mark day complete + progress through the year** ("Day 158 of 365"),
  integrated with the existing prayer-streak system. `EpisodeProgress` already
  tracks `duration` + an `isFinished` flag — the bridge data is in place.

### Beyond the simulation (to become a real feature)
- **Multiple curated podcasts** — resolve many feeds via Apple's free iTunes
  Lookup API (`id → feedUrl`); a curated, theologically-vetted set (5–10).
- **A real "Listen" home** — currently a single screen behind Pray; the real
  feature likely wants its own surface.
- **SwiftData persistence** for episodes/downloads/progress (progress is
  UserDefaults today — fine for resume, but downloads/marks want a real store).

---

## Decisions + guardrails already locked (don't re-litigate)

- **Source = open RSS via Apple Lookup API, NOT YouTube** (YouTube ToS forbids
  audio-only/background). Cost = **$0** (free/keyless API + stream host's MP3).
- **Free tier only** — don't paywall third-party free content. Monetize the
  *layer* (AI recommendations, playlists, ad-free), not the audio.
- **Curated + orthodox** — a heterodox feed is the same credibility risk as a
  wrong CCC citation. Hand-pick shows.
- **Play the enclosure URL verbatim + send `BlissfulCatholic/1.0` User-Agent**
  so podcasters get counted downloads and can see us in their stats.
- **Current-year window** for the daily series; ordinary shows would use
  `.recent(n)` (see `EpisodeWindow`).

## Known caveats (acceptable for now)
- Full ~8 MB feed is downloaded every load (RSS has no pagination); the
  date-filter trims *parse*, not *download*. HTTP caching makes refetches cheap.
- `Episode.summary` retained but unused (waiting for the detail view).
- Podcast resume positions are local UserDefaults → **wiped on app delete /
  device change** (fine for throwaway pointers; see [[phase2-swiftdata]] memory).
- Lock screen shows skip arrows OR a scrubber depending on enabled commands.
