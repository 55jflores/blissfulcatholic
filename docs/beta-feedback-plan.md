# Beta Feedback Plan — Build 2

Created 2026-06-06, the day Apple's Beta App Review approved Build 2 and the
first external testers got in. Goal: turn 3–5 friends using the app into
high-signal feedback without bureaucracy.

This doc replaces `checkpoint-2026-06-03.md` as the active working note.

---

## The two things this app must get right (watch these first)

1. **Theological / pastoral correctness.** This is a Catholic devotional app
   with AI reflections (lectio, catechism, confession_prep, saint,
   journal_insight). A wrong CCC citation, a fabricated saint fact, or a cold
   tone on confession prep is a *content* failure that no crash log will catch.
   Testers are your only sensor for this. Ask about it explicitly.
2. **Sign-in → Plus → AI actually works.** Every signed-in tester gets Plus
   (`BETA_GRANT_PLUS_TO_ALL_USERS = true`). If sign-in or the AI proxy fails
   for even one tester, they see a dead app. Confirm each tester reached a
   working AI reflection at least once.

---

## Channels (high-touch beats forms at this size)

- **Primary: a group chat** (iMessage/WhatsApp) with the testers. At 3–5
  people, a chat gets 10× the response rate of a form and lets you ask
  follow-ups. Pin one message: "Screenshot anything weird + one line of what
  you expected."
- **Secondary: TestFlight's built-in feedback.** Testers can screenshot in the
  app and share via the TestFlight feedback sheet; screenshots + device/OS land
  in App Store Connect → TestFlight → Feedback. Crash reports also surface here
  and in **Xcode → Organizer** (no Sentry/Crashlytics installed, so this is the
  only crash channel — check it every couple days).

---

## The 5 questions to actually ask (not "what do you think?")

Send these in the chat after they've used it ~3 days. Specific prompts beat
"any feedback?":

1. Did anything **crash, freeze, or fail to load**? (screenshot if so)
2. Did **sign-in work** the first time, and did the AI reflection appear?
3. Did any **AI reflection feel off** — wrong fact, wrong tone, or
   theologically shaky? (this is the one I care most about)
4. What's the **one screen you'd open daily**, and the one you'd never open?
5. What's **one thing missing** that would make you keep using it after the
   novelty?

---

## Copy-paste chat messages

Casual on purpose (close friends → higher response than a formal survey).
Q3 is softened ("felt off" + 🙏) so people freely flag theology/tone issues.
Lead with the short one if the group skews busy.

### Full version (warm)

> Hey friends 🙏 thank you so much for being my first testers — it genuinely
> means a lot. You've had a few days with Blissful Catholic now, so I'd love
> your honest takes. Don't sugarcoat anything — rough feedback is the most
> useful kind. If you can, screenshot anything weird.
>
> A few specific things I'm wondering:
>
> 1. **Did anything break?** Crashes, freezes, a screen that wouldn't load —
>    anything at all?
> 2. **Did sign-in work the first time,** and did the AI reflection actually
>    show up for you?
> 3. **Did any of the AI reflections feel off** — a fact that seemed wrong, or
>    a tone that felt cold or just not quite right? (This is the one I care
>    about most. 🙏)
> 4. **Which screen would you open every day,** and which one would you never
>    touch?
> 5. **What's one thing missing** that would make you keep using it after the
>    new-app excitement wears off?
>
> No need to answer all five at once — even one reply helps a ton. Thank you
> again ❤️

### Short version (busy groups)

> Hey friends 🙏 thank you for testing Blissful Catholic! Quick honest
> gut-checks (rough feedback is the best kind — screenshot anything weird):
>
> 1. Did anything **break or crash**?
> 2. Did **sign-in + the AI reflection** work?
> 3. Did any **AI reflection feel off** — wrong fact or off tone? 🙏
> 4. Which screen would you **open daily**? Which never?
> 5. One thing **missing** that'd keep you coming back?
>
> Even one answer helps a ton. Thank you ❤️

---

## Triage buckets (priority order)

| Bucket | Examples | Priority |
|---|---|---|
| **Crash / data loss** | app dies, journal entry lost, sign-in broken | P0 — fix now |
| **Theology / content** | wrong CCC cite, fabricated saint, harsh confession tone | P0 — credibility risk |
| **Broken UX** | button does nothing, AI spins forever, refresh fails | P1 |
| **Polish** | spacing, copy, color, animation | P2 — batch for Build 3 |
| **Feature request** | "wish it had X" | P3 — log, don't act yet |

Keep a running list at the bottom of this doc as feedback arrives.

---

## Backend / cost watch (because beta grants Plus to everyone)

Every AI call logs to the Supabase `api_usage` table (`user_id, endpoint,
model, input_tokens, output_tokens`). With ~5 testers it's cheap, but watch:

- **Vercel logs** for `500`s and `api_usage insert failed` lines (logging is
  fire-and-forget, but errors mean Supabase trouble).
- **Anthropic spend** — Opus 4.7 drives most features; a runaway tester or a
  retry loop could spike cost. Glance at the Anthropic console weekly.
- **Rate limits** — `checkRateLimit` is per-user rolling 24h. If a tester says
  "it stopped responding," check whether they hit the cap vs. a real error.

Quick health probe (same as the old checkpoint):
```bash
curl -s https://blissfulcatholic.com/api/health
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://blissfulcatholic.com/api/ai -d '{}'  # expect 401
```

---

## Cadence

- **Day ~3:** send the 5 questions. Check Xcode Organizer for crashes.
- **Day ~7:** follow up, look at `api_usage` volume, decide if Build 3 is
  warranted or if you expand the tester pool (3–5 → 10–15).
- **Rolling:** triage into the table above as things come in.

---

## Still parked (revisit after first feedback wave)

1. **Pricing reconciliation** — `monetization.md` ($8.99/$59.99) vs.
   `monetization-strategy.md` ($3.99/$29.99/$79.99). Pick one before Phase 5.
2. **Flip `BETA_GRANT_PLUS_TO_ALL_USERS` → false** when the Phase 5 paywall ships.
3. **Optional:** bump Plus features Opus 4.7 → Opus 4.8 (`claude-opus-4-8`),
   the current newest model. No urgency.
4. Phase 5 list: in-app account deletion (Apple requires before public launch),
   StoreKit + RevenueCat, custom SMTP, per-field encryption.
5. **Priest podcasts (tester request, 2026-06-06)** — POST-LAUNCH, not a beta
   blocker. Verdict: does NOT conflict with monetization the way it first seems.
   Guardrails if/when built:
   - **Free tier only** — can't paywall third-party free content (bad form +
     can violate RSS terms). Podcasts are top-of-funnel engagement, not a Plus
     feature. They don't cannibalize Plus (passive listening ≠ personalized AI).
   - **Source = open RSS feeds (via Apple Podcasts directory), NOT YouTube.**
     YouTube ToS forbids audio-only/background playback outside its player →
     useless + rejection risk. RSS is how every podcast app legally works.
   - **Curate, don't open the floodgates** — a hand-picked, orthodox set
     (5–10 priests). A heterodox feed in a Catholic app is the same credibility
     risk as a wrong CCC citation.
   - **Monetize the layer, not the content** — if anything is Plus, it's the
     AI-recommended episodes (by journal/season), playlists, downloads, ad-free.
     Raw audio stays free.
   - Real cost is **scope/focus** (player, background audio, downloads, queue =
     weeks), not monetization. Defer until after launch; ship a lightweight v1.
   - **Cost = $0.** Apple's iTunes Lookup/Search API (resolves podcast →
     `feedUrl`) is free, keyless, ~20 req/min soft cap. No Apple podcast
     playback SDK exists — you consume open RSS + stream the host's MP3 (also
     free). Nothing licensed from Apple.
   - **Plays are podcaster-friendly (flips the licensing ask).** Displaying an
     episode credits nothing; *playing* it requests the enclosure MP3 from the
     host, which counts as a download in their host + third-party analytics
     (Podtrac/Chartable/OP3) — same as Apple Podcasts. Caveats: (a) won't show
     in Apple's own Connect dashboard, only host/3rd-party; (b) **play the
     enclosure URL verbatim** — don't strip measurement prefixes or their
     tracking breaks; (c) **send an identifiable User-Agent** (e.g.
     `BlissfulCatholic/1.0`) so creators see us in their stats. Net: we bring
     them listeners + counted downloads at no cost → "offering reach," not
     "asking to take."
   - **Flow diagram + file map:** see `docs/podcast-flow.md` (single-podcast
     simulation: seed → fetch → FeedKit parse → model → Lumen list → AVPlayer).

---

## Feedback log (append as it arrives)

| Date | Tester | What they said | Bucket | Status |
|---|---|---|---|---|
| 2026-06-06 | — | "System" theme redundant w/ Parchment & Cathedral | Polish | ✅ Removed |
| 2026-06-06 | — | Rosary should show full Our Father / Hail Mary + all prayers | Theology/content | ✅ Full texts + Fatima + concluding prayer added |
| 2026-06-06 | — | Errant "V."/"R." in concluding prayer | Polish | ✅ Cleaned up |
| 2026-06-06 | — | Include priest podcasts (YouTube/Apple) | Feature request | Parked → Phase 5+ decision #5 |
