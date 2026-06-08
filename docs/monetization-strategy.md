# Blissful Catholic — Monetization Strategy

Captured 2026-06-02 as a strategy/framing companion to
[`monetization.md`](./monetization.md) (which holds the Phase 5 implementation
plan — RevenueCat, StoreKit 2, Stripe, product identifiers, server-side
gating).

This doc covers the **why** and the **path to revenue** — the Catholic
theological framing, the app-store market landscape, realistic revenue
projections, the layered revenue model (subscription + donations + parish
licenses), and the launch sequencing strategy.

> **Pricing discrepancy with `monetization.md` — needs reconciliation.**
> `monetization.md` proposes $8.99/mo · $59.99/yr (App Store) and $6.99/mo ·
> $49.99/yr (web). This doc proposes $3.99/mo · $29.99/yr · $79.99 lifetime,
> positioned distinctly below Hallow. Two coherent positions; pick one before
> Phase 5 ships.

---

## 1. The Catholic theological framing

Two equally valid threads in Catholic tradition on payment for spiritual goods:

> *"Freely you have received; freely give."* — Matthew 10:8

> *"The laborer deserves his wages."* — Luke 10:7

The Church reconciles these with a clear principle: **you can charge for the
labor and infrastructure around spiritual goods, but not for the spiritual
goods themselves.** Selling a sacrament is simony. Selling a Mass intention
is forbidden (you offer a stipend, not a price). But Magnificat charges
$45/year for a devotional magazine, Ignatius Press sells books, Catholic
universities charge tuition, and spiritual directors charge for their time —
all without controversy.

**Concretely for Blissful Catholic:**

- ✅ **OK to charge for** — design work, content curation, time, AI
  infrastructure costs, software development. These are "wages of the laborer."
- ❌ **Cannot charge for** — Mass readings themselves (USCCB owns them; we
  republish under fair use), public prayers like the Rosary (common patrimony
  of the Church), or anything that gates *grace*.

The question isn't *whether* to charge — that's permitted. The question is
*what to charge for and how to frame it.*

---

## 2. Catholic app market landscape

| App | Model | Price | Notes |
|---|---|---|---|
| **Hallow** | Subscription | $69.99/yr | VC-backed, premium positioning, large content library |
| **Magnificat** | Subscription (digital) | $44.95/yr | Long-standing print legacy, devotional magazine |
| **Pray.com** | Subscription | $59.99/yr | Multi-faith but Catholic-friendly |
| **iBreviary** | Free + donations | $0 | Priest-built, donation-funded |
| **Laudate** | Free + ads | $0 | Broad utility, light ads |
| **Universalis** | One-time | ~$25 | Old-school transactional |
| **YouVersion Bible** | Free + donor | $0 | Nonprofit, large donor base |

**Free apps in this space depend on one of three things:**
1. Parish/diocesan funding (slow to land, requires B2B relationships)
2. Voluntary donations (unreliable at small scale)
3. Ads (incompatible with prayer UX and ethically dubious in religious context)

We have none of these baked in, and we have **real ongoing AI costs**. So free
forever doesn't pencil. Freemium does.

---

## 3. The freemium model — what's free, what's Plus

The codebase is already architected for this (`PlusUpsellCard`, entitlement
check, `upgradeRequired` error response from the AI proxy).

### Free tier — "common patrimony"

What the Church has always offered without price. A genuinely useful app on
its own:

- **Today's Mass readings** (can't charge for them anyway, Catholics expect access)
- **Saint of the day** (curated, commodity-quality info available elsewhere)
- **Monthly devotion** (this month's tradition — same logic)
- **The Rosary** (full functionality — five decades, all four sets of mysteries, audio)
- **Personal journal** (writing for God shouldn't have a fee)
- **Prayer intentions** (basic — keep a list, mark prayed)
- **Liturgical color themes** (the visual design *is* the gift)

### Plus tier — value-add labor and infrastructure

What our work + costs make possible:

- **AI reflections** — gated naturally because they have per-call Claude cost.
  This is what funds the rest. Daily reflection, "Reflect with your companion,"
  journal insights.
- **Expanded content** — deeper saint catalog (current 28 → 100+ saints),
  audio Rosary with a real voice, novena library, deeper devotional readings.
- **Personal context** — the personalization (Catholic role, life situation)
  that shapes AI tone. Architecturally already wired.
- **Future** — audio Mass readings, advanced journaling, family prayer plan,
  retreat plans.

### Hard rules on what NOT to gate

- **Don't gate the Rosary.** Most-recognized Catholic prayer. PR landmine + pastorally wrong.
- **Don't gate the daily reading text itself.**
- **Don't put paywall interrupts in the middle of a prayer flow.**
- The Plus prompt lives in two places only: at AI feature entry points, and in Profile.

---

## 4. Pricing positioning (this doc's recommendation)

Positioning: a **thoughtful indie alternative below Hallow.** Cheaper than the
VC-backed competitor, more polished than the free utilities.

| Plan | Price | Reasoning |
|---|---|---|
| **Monthly** | $3.99 | Magnificat / iBreviary-premium range — Catholics already pay this |
| **Annual** | $29.99 | Below "subscription fatigue" threshold (~$5/mo equivalent); 38% savings vs. monthly |
| **Lifetime** | $79.99 | ~2.7 yr payback; generous to early adopters, sustainable for us |

**Tradeoffs vs. the higher pricing in `monetization.md` ($8.99/mo · $59.99/yr):**

- This doc's pricing optimizes for **volume + goodwill** (more conversions at lower price)
- `monetization.md`'s pricing optimizes for **revenue per user** (fewer but more lucrative)
- Conversion-rate sensitivity: a 50% lower price often yields >2× more conversions
  in religious-content apps because the audience is price-conscious

A small touch that lands well in both:

- **Free Plus for clergy and religious.** Profile button: *"Are you a priest,
  deacon, religious sister, or seminarian? Email us."* Manually grant
  entitlement. Costs ~nothing (not high-volume users), generates enormous
  goodwill, canonically appropriate.

---

## 5. Realistic revenue projections

Assumes the lower pricing ($29.99/yr blended ARPU ≈ $2.50/mo). Adjust upward
proportionally for the higher-pricing path.

| Scenario | MAU | Plus conv. | ARPU | MRR |
|---|---|---|---|---|
| **Year 1 (slow build)** | 2,000 | 2% | $2.50/mo | **$100** |
| **Year 1 (good growth)** | 8,000 | 3% | $2.50/mo | **$600** |
| **Year 2 (steady)** | 25,000 | 4% | $2.50/mo | **$2,500** |
| **Year 3 (established niche)** | 75,000 | 5% | $2.50/mo | **$9,400** |

Notes on the math:

- **2–5% conversion is typical** for freemium religious apps. Hallow is
  reportedly 10–15% (they paywall hard from day 1). Magnificat is effectively
  100% (pay or no app). We land in the 2–5% range with a soft paywall.
- **ARPU $2.50/mo** assumes blended: half annual subscribers ($2.50/mo
  effective), some monthly ($3.99), some lifetime amortized.
- **"Decent income after bills are paid" (~$1,500–3,000/mo net)** is realistic
  for year 2–3 with consistent content cadence and word-of-mouth growth.
- **Apple's 15% cut** under the Small Business Program (free to enroll while
  under $1M/yr revenue). Don't worry about the 30% rate yet — enroll on day 1.

---

## 6. Layered revenue model — beyond subscription

### Layer 1: Plus subscription (above)

Primary revenue. 80–90% of total in years 1–2.

### Layer 2: Donations / "Support development"

Once Plus is stable, add a Profile screen option. Frame Catholic-appropriately:

> *"Blissful Catholic is built by one Catholic developer. If the app has
> supported your prayer life, you can support its development. Every
> contribution helps keep daily readings free for everyone."*

- One-time or recurring
- Use App Store IAP **consumables** ($1.99, $4.99, $9.99 "tips")
- Conversion rate: 0.5–1% of free users, ~$5 average donation
- Pure margin (no AI cost attached)
- Makes free users feel like participants rather than freeloaders

### Layer 3: Parish / diocesan licenses (year 2+)

**Where real money lives in Catholic apps. Also 6–12 month sales cycle.**

The pitch:

> *"Bulk Plus access for your entire parish. Every parishioner gets the full
> feature set, paid for by the parish budget. $99/year for parishes up to 500
> families. $299/year up to 2,000. Diocesan licensing available."*

Numbers from comparable Catholic SaaS:

- One mid-sized parish license ($99/yr) ≈ 33 individual subscribers
- One diocese (~150 parishes at $99 each) ≈ **$15,000/yr from one deal**
- Diocese-wide direct licenses: $5,000–50,000/yr depending on size and scope

Requires: phone calls, networking through Catholic Marketing Network and
Catholic Media Association, building relationships with parish IT leads and
directors of evangelization. Don't pursue until there's product traction.

### Layer 4: Print/physical companion (year 2+)

Catholic apps often have physical goods upsells. Examples worth considering:

- Hardcover Journal companion ($25)
- Printed daily devotional ($20)
- Branded prayer cards / mini-books

Small dollars per unit but high margin and excellent gift appeal.

### Layer 5: Affiliate / publisher partnerships (low priority)

Ignatius Press, Word on Fire, Augustine Institute, etc. Small dollars,
complicated bookkeeping. Skip unless an obvious partner approaches us.

---

## 7. Launch sequencing strategy

Don't launch Plus on day 1 of public release. Stage it.

| Phase | Timing | Action |
|---|---|---|
| **TestFlight beta** | Now | Build 2 to external testers. Free. No Plus. Focus on quality + content. |
| **Public launch (free)** | When ready | Launch entirely free. Build a user base, get reviews, refine content. 4–8 weeks. |
| **Plus enable, soft** | After ~5,000 MAU | Enable Plus quietly. Grandfather first 1,000 users with free Plus for life as "early supporters." |
| **MRR target $500/mo** | Month 6 | ~165 paying annual subscribers. Achievable with quality + word of mouth. |
| **Donations layer** | Year 1 end | Add Profile tip-jar after Plus is steady. |
| **Parish outreach** | Year 2 | Start B2B sales motion. Catholic conferences, parish demos. |
| **Reassess as business vs. side project** | Year 3 | Adjust ambition based on actual traction. |

**Why no Plus on day 1:** the loudest negative reviews on Catholic apps are
about paywalls. Launching free buys goodwill, creates baseline reviews, gives
you content to point to ("here's what users love before the paid tier").
Then Plus reads as "support what's already great" rather than "you have to
pay to use this."

---

## 8. Hard rules — things to avoid

| Avoid | Why |
|---|---|
| **Ads** | Categorically inappropriate during prayer. Networks (AdMob, Meta Audience) serve content we can't control. Bad UX. |
| **Aggressive paywall placement** | No interrupting prayers with upsells. Plus prompt lives at AI feature entry points and in Profile. |
| **Dark patterns** | No "trial that auto-renews for a year." Use Apple's standard subscription mechanisms with transparent pricing. |
| **"Free month for inviting 3 friends"** | Growth hacks feel wrong in a faith context. Word of mouth has to be organic. |
| **One-time purchase only** | Doesn't fund ongoing AI costs. Lifetime as one option among subscriptions is fine; lifetime-only isn't. |
| **Selling user content** | Journal entries are inviolably the user's. Never train on them, never share, never sell. |
| **Paywalling the Rosary** | Most-recognized Catholic prayer. Non-negotiable that this stays free. |

---

## 9. The spirit of it

The Catholic faith has always sustained good work through a mix of
self-supporting labor (Paul tentmaking, monasteries running farms) and the
gifts of those who benefit (the widow's mite, the patronage of Christian
princes). A devotional app following that pattern — **modestly priced for those
who can pay, free for those who can't, supported by parish budgets and
grateful tips** — is in complete continuity with that tradition.

We're not "monetizing the faith." We're sustaining the labor that makes a free
tier possible for the people who need it. That's the right framing both
ethically and theologically.

---

## 10. Open strategic questions

These need decisions before Phase 5 ships:

- **Reconcile pricing with `monetization.md`** — $3.99/$29.99 (this doc) vs.
  $8.99/$59.99 (existing). Position below or alongside Hallow?
- **Free trial length** — 7 vs. 14 days. Existing doc proposes 7. The "felt
  value over time" of personalized AI suggests 14 might convert better.
- **"Taste" quotas** (free AI calls per day) — needs A/B testing. Existing
  doc proposes 1 Lectio + 3 Catechism Q/day. Worth revisiting.
- **Higher patron tier** — Some Catholic apps offer a "Patron" or "Benefactor"
  tier ($19.99/mo equivalent) for users who want to contribute more. Worth
  considering once Plus is stable.
- **Public launch timing** — when do we flip from external TestFlight to App
  Store public? Recommend after 50–100 external testers have used it for 2+
  weeks with no critical issues.

---

## See also

- [`monetization.md`](./monetization.md) — Phase 5 implementation reference
  (RevenueCat, StoreKit 2, Stripe, product IDs, server-side gating).
