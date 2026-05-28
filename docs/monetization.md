# Blissful Catholic — Monetization

Captured 2026-05-26 for implementation in **Phase 5** (StoreKit 2 + RevenueCat + Stripe).
This is the source of truth for pricing, the free/Plus split, and the entitlement
gating used by both the iOS app (paywall) and the Next.js AI proxy.

---

## 1. The value proposition (why anyone pays)

Free Catholic apps sell **content & utilities** (readings, rosary text, calendar,
saint blurbs). We don't paywall those — we can't out-content Hallow. We sell
**intelligence + relationship**: a personalized, orthodox AI companion that
*remembers the user and grows with them*. That is the moat and the paid tier.

The competitor to beat isn't only Catholic apps — it's **free ChatGPT**. We win on:
1. **Trust / orthodoxy** — won't give heterodox answers (foundation prompt + theological safety filter).
2. **Integration** — lives inside prayer life (Lectio, Rosary, Journal), not a blank chat box.
3. **Memory** — remembers the user's spiritual journey (themes, struggles, graces).
4. **Warmth + reverence** — a companion, not a tool.

> If we can't articulate why it beats free ChatGPT, the subscription is shaky.
> The answer is: **trust + integration + memory.**

---

## 2. Pricing

| Channel | Monthly | Annual | Notes |
|---|---|---|---|
| **App Store** (StoreKit 2 / RevenueCat) | **$8.99** | **$59.99** | Annual = "2 months free"; lead with annual on the paywall |
| **Web** (Stripe) | **$6.99** | **$49.99** | Cheaper — no Apple cut. Drive via SEO/social; **cannot** link from iOS (anti-steering) |

- **Free trial:** 7 days (test 14 later). Trial matters — the value (*feeling known over time*) needs a few sessions to land.
- **Apple Small Business Program:** enroll from day one → Apple's cut is **15%** (not 30%) while under $1M/yr. Biggest margin lever; free to opt into.
- **Founding-member** offer at launch (discounted first year) to seed reviews + word of mouth.
- **Psychological pricing** ($X.99). Annual is the default-highlighted option.

### Margin reality (we have a real marginal cost)
Unlike content apps, **every AI call costs Anthropic tokens** (~$1–3/mo for a heavy
user with Claude Sonnet + prompt caching). Price must clear *platform cut + AI cost
+ margin*. Protect it with: (a) the free/Plus split below, (b) **rate limiting**, (c)
**prompt caching** on the foundation system prompt, (d) the 15% Apple program.

---

## 3. Free vs. Plus split

**Principle:** free tier is genuinely useful (acquisition) + a *daily taste* of AI so
the paywall converts on felt value, not friction. The personalized, unlimited,
memory-bearing depth lives behind the wall.

| Capability | Free | Plus |
|---|---|---|
| Daily readings, saint of the day, liturgical calendar | ✅ | ✅ |
| Rosary tracker (beads, haptics, mystery selection) | ✅ | ✅ |
| Basic journaling (write/save/edit) | ✅ | ✅ |
| Prayer streaks / history | ✅ | ✅ |
| **AI Lectio Divina** (guided, personalized) | Taste (1/day) | ✅ Unlimited |
| **Catechism companion** (CCC-cited, level-calibrated) | Taste (few Q/day) | ✅ Unlimited |
| **AI Confession prep** (adaptive to state in life) | — | ✅ |
| **AI mystery reflections** (Rosary) | — | ✅ |
| **Journal insights** (themes/struggles/graces over time) | — | ✅ |
| **Personalization & memory** (grows with you) | — | ✅ |
| Formation paths / courses | Preview | ✅ Full |

> Exact "taste" limits (e.g. 1 Lectio + 3 Catechism questions/day) are tunable and
> should be A/B tested. They're enforced server-side (see §5).

---

## 4. Conversion strategy

- **Taste, then wall** — let users *feel* being known, then ask them to keep it.
- **Lead with annual** — most revenue + lowest churn; frame as "2 months free."
- **Growing switching cost** — journal, insights, and history live here; the longer
  they use it, the more it's theirs.
- **Mission angle** — "made by Catholics, orthodox, supports development" converts a
  surprising share, especially converts & the devout (our stated audience).
- **Web price via SEO** — organic discovery drives users to the cheaper Stripe plan.

---

## 5. Implementation notes (Phase 5)

### Entitlement
- Single entitlement: **`plus`** (RevenueCat). The app and the AI proxy both check it.

### Product identifiers (proposed)
- App Store: `co.jesusflores.blissfulcatholic.plus.monthly` ($8.99),
  `co.jesusflores.blissfulcatholic.plus.annual` ($59.99)
- Stripe (web): `plus_monthly` ($6.99), `plus_annual` ($49.99)
- RevenueCat offering `default` with `monthly` + `annual` packages; 7-day trial on both.

### iOS
- StoreKit 2 + RevenueCat SDK; paywall = `ProfileView` "See plans" / a dedicated paywall view.
- Read entitlement on-device (RevenueCat) to unlock UI and show the paywall.
- Subscription state also synced to Supabase (see below) for server-side gating.

### Backend (entitlement gating + rate limiting)
- Stripe **and** RevenueCat **webhooks** → Next.js → write subscription state to Supabase `subscriptions` (service-role client).
- The **AI proxy** (`/api/ai`) checks, server-side, before calling Claude:
  1. valid Supabase JWT (who),
  2. `plus` entitlement OR within the free daily "taste" quota (what they may do),
  3. rate limit (abuse protection).
- On-device gating alone is **not** trusted — a tampered client must not get free AI.

### Don't forget
- App Store requires **in-app account deletion** if we have account creation.
- Surface a **"Delete all data"** affordance (privacy trust; see CloudKit notes).

---

## 6. Open items to test
- Annual price point: **$49.99 vs $59.99** (RevenueCat A/B).
- Trial length: 7 vs 14 days.
- Free "taste" quota size (Lectio/Catechism per day).
- Whether to add a higher "patron" tier (optional).
