# Blissful Catholic — Business & Operations Checklist

Captured 2026-06-03 as a forward-looking reference for the non-coding work that
sits between TestFlight and public launch (and beyond). Sibling to the
monetization docs:

- [`monetization.md`](./monetization.md) — Phase 5 implementation reference
- [`monetization-strategy.md`](./monetization-strategy.md) — strategic framing

This is a checklist, not a plan. Come back to it when picking up business/ops
work; mark items as you complete them.

---

## Tier 1 — Must do before App Store public launch

These are the actual gates between TestFlight and a public release.

### Legal documents

- [ ] **Terms of Service / EULA decision**
  - **Why:** Apple requires a EULA for any app with accounts. Custom is needed once you have user-generated content (journal entries), AI-generated content, or subscriptions.
  - **TestFlight stance:** Apple's Standard EULA is automatically applied — nothing to write.
  - **Public-launch stance:** custom ToS covering journal-content ownership, AI disclaimers, subscription terms, IP, dispute resolution.
  - **How:** [Termly](https://termly.io) or [iubenda](https://iubenda.com) to generate a draft ($10–40), then a 30-minute lawyer review ($200–400).
  - **Time:** ~4 hours of your time + lawyer turnaround.

- [ ] **Refund & data deletion policy**
  - **Why:** Apple requires a clear "delete my account and all data" path inside the app, plus a written policy.
  - **In-app:** account deletion affordance in Profile.
  - **Document:** disclosed in ToS or privacy policy.

- [ ] **Privacy policy review (annual)**
  - Currently at `blissfulcatholic.com/privacy`.
  - Review when: new third-party SDK added; new data type collected; pricing/Plus shipped; annual minimum.

### Business entity

- [ ] **LLC formation** — `$300–800/year` depending on state
  - **Why:** Shields personal assets from app-related lawsuits (e.g., user claims AI gave harmful spiritual advice).
  - **When:** before flipping Plus on / before income meaningfully arrives.
  - **How:** state Secretary of State website + a registered agent.

- [ ] **Business bank account separation** — open a dedicated business checking once the LLC is formed.

- [ ] **EIN (free)** — apply via IRS website; needed for business bank account.

- [ ] **Sales tax registration (state-dependent)** — only relevant if you sell physical goods or in states that tax SaaS.

### Apple Developer account

- [ ] **Decide individual vs entity Developer account**
  - Currently individual. Moving to entity (LLC) requires a re-enrollment with a D-U-N-S number — Apple's process takes 2–4 weeks.
  - Recommend: stay individual through public launch; convert to entity in year 1 when LLC + revenue justify it.

---

## Tier 2 — Should do for credibility (especially for a faith app)

### Catholic theological review

- [ ] **Find a spiritual advisor for content review**
  - **Why:** Single biggest credibility differentiator for a faith app. Most non-Catholic founders skip it.
  - **Who:** priest, deacon, or theologically-trained layperson.
  - **What they review:** AI foundation prompt, monthly devotion text, saint blurbs, daily reflection content.
  - **Cost:** $0–200/mo informal arrangement; could be free with a sympathetic priest.
  - **Bonus:** "Reviewed by Fr. X" in About page massively boosts trust.

- [ ] **Imprimatur / Nihil Obstat (if publishing print companion)**
  - Formal ecclesiastical approval from a bishop. Granted to *texts*, not apps.
  - 3–6 month process, requires diocesan censor's review.
  - Worth pursuing only if/when a print devotional companion is published.

- [ ] **Diocesan endorsement** — get a parish or diocese to officially recommend the app. Requires relationship building.

### Intellectual property

- [ ] **Trademark search** — "Blissful Catholic" on [USPTO database](https://tmsearch.uspto.gov) (free).

- [ ] **Trademark registration** — if search is clean, basic federal registration is ~$250–350 filing fees.
  - Time: 6–12 months for full registration; can use TM symbol immediately on filing.

- [ ] **Logo / brand mark copyright** — automatic on creation, but worth saving the source files in version control and noting authorship.

### Insurance

- [ ] **Cyber liability insurance** — ~$500–1,500/year for a small app. Covers data breach response.
  - When: once user base is non-trivial (10k+ MAU or any Plus subscribers).
  - Provider examples: Hiscox, Coalition, The Hartford.

- [ ] **General liability** — usually packaged with cyber for tiny businesses. Marginal cost.

### Domain & infra protection

- [ ] **Defensive domain registrations** — `.app`, `.org` (~$15/yr each).

- [ ] **Domain lock at registrar** — prevent transfer hijacking.

- [ ] **DNS records exported** — keep an offline copy of the Vercel DNS config and registrar settings.

---

## Tier 3 — Operational hygiene

### User support infrastructure

- [ ] **Branded support email** — `support@blissfulcatholic.com` (Vercel/Google Workspace).
  - Current: `jesus.flores1008@gmail.com` (fine for now).

- [ ] **Help / FAQ docs** — could be a simple Notion page linked from Profile.

- [ ] **Personal SLA** — commit to a response time ("I answer support email within 48 hours").

- [ ] **Bug report workflow** — currently TestFlight's built-in; eventually a simple email is enough at this scale.

### Crisis & pastoral protocols

The unique-to-faith-apps section. Worth thinking through ahead of time.

- [ ] **Crisis response playbook (1-page doc)**
  - **Trigger:** user sends feedback that reads like a mental health crisis.
  - **Response template:** thank them for reaching out, gentle de-escalation language, **988 Suicide and Crisis Lifeline**, Catholic counselor referral (e.g., Catholic Therapists directory), prayer.
  - **What you do NOT do:** offer spiritual counseling beyond your competence, diagnose, or stay silent.

- [ ] **AI heterodoxy fix process**
  - **Trigger:** a user reports the AI said something theologically wrong.
  - **Response:** acknowledge → log to bug tracker → review with theological advisor → fix foundation prompt → ship update → reply to user with what was changed.
  - Documents your editorial integrity if anyone publicly criticizes the app.

- [ ] **Editorial policy on AI-generated content (1-page doc)**
  - States: AI reflections are tools, not substitutes for prayer or a confessor; reviewed against foundation rules; users encouraged to discuss serious matters with a real priest.
  - Include in ToS or About page.

### Analytics decisions

- [ ] **Decide what NOT to track** — journal content, prayer intentions, confession prep text, AI conversations. Document this.

- [ ] **Pick privacy-respecting analytics tool** — Plausible or Fathom (no cookies, no PII). Avoid Google Analytics.

- [ ] **Decide what to track** — DAU/MAU, screen views (sans content), feature engagement counts, retention cohorts.

### Backup & continuity

- [ ] **Verify Supabase backup retention** — daily backups, 7-day retention on free tier, longer on paid.

- [ ] **Export DNS + registrar settings to an offline file** — recoverable if account is compromised.

- [ ] **Code backups** — GitHub handles this; verify both repos (`iOS: 55jflores/blissfullcatholic`, `web: 55jflores/blissfulcatholicweb`) are pushed regularly.

- [ ] **Incident response checklist (1-page doc)** — what to do if Vercel/Anthropic/Supabase goes down, or there's a data breach.

---

## Tier 4 — Growth & marketing (after public launch)

These don't gate launch but determine whether anyone finds the app.

### Press & PR

- [ ] **Press kit** — 1-page PDF with screenshots, founder story, key features. Email-friendly.

- [ ] **Catholic media outreach list** — National Catholic Register, Catholic World Report, EWTN, The Pillar, Our Sunday Visitor, Aleteia, Catholic News Agency, Catholic Stand.

- [ ] **Catholic podcast pitch list** — Word on Fire (Bishop Barron), Pints with Aquinas (Matt Fradd), Catholic Stuff You Should Know, Renewed Mind, The Catholic Project, Mass of the Air.

- [ ] **Catholic social-media accounts** — Catholic Twitter/X, Catholic Instagram, Catholic Substacks (Brandon McGinley, Sohrab Ahmari, etc.). Curate a list of high-engagement accounts.

### Parish distribution

- [ ] **Parish bulletin software outreach** — LPi, J.S. Paluch carry app recommendations. Relatively cheap channel.

- [ ] **Diocesan media office outreach** — most dioceses have a communications office. Pitch the app for inclusion in diocesan resources.

- [ ] **In-person parish demos** — start with your own parish; one Sunday demo can yield 50+ installs.

### App Store presence

- [ ] **App Store Optimization (ASO) research** — keywords competitors use, search volume estimates. Tools: AppFollow, Sensor Tower (paid; or free tier).

- [ ] **Screenshots set** — 6–10 polished phone screenshots showing the actual app, not marketing fluff. Liturgical-season variations are visually striking.

- [ ] **App preview video (optional)** — 30-second video of the app in use; can lift conversion 20–30%.

- [ ] **Localization decision** — Spanish covers ~40% of US Catholics. Worth doing for v2.

---

## Tier 5 — Park for later

Real concerns; revisit when relevant.

- [ ] **GDPR compliance specifics** — broad strokes covered by current privacy policy; serious only if EU traffic becomes meaningful.

- [ ] **CCPA / state privacy laws** — California, Virginia, Colorado, etc. Mostly covered by privacy policy; review annually.

- [ ] **COPPA** — only relevant if app targets under-13 users. Currently targets adults; verify positioning.

- [ ] **Multi-platform expansion** — Android, web app. Defer.

- [ ] **Partnership pitches** — Ignatius Press, Word on Fire, Augustine Institute, Hallow (unlikely), Catholic Press Association. Wait until product traction.

- [ ] **Catholic Press Association membership** — $350/yr. Wait until publishing more substantial content.

- [ ] **Print companion product** — devotional book, journal, prayer cards. Year 2+ idea.

---

## Tier 6 — The traps to avoid

Common first-time-founder pitfalls for solo Catholic-app devs:

- [ ] **DON'T treat Apple's Standard EULA as sufficient forever.** Fine for v1; not for ongoing user content + subscriptions.

- [ ] **DON'T skip the theological review.** For a faith app this is the single biggest credibility differentiator and most people skip it.

- [ ] **DON'T stay an individual once income is meaningful.** Personal liability shield via LLC matters.

- [ ] **DON'T launch with no crisis playbook.** Eventually a user will email something heavy. Having a one-page response template saves you from a bad day.

- [ ] **DON'T add Google Analytics or third-party tracking SDKs.** Once added, you're declaring more on the App Privacy nutrition label and re-entering a different ethical zone for a prayer app.

- [ ] **DON'T sell user content or train AI on user journals.** Both ethically wrong and legally risky for a religious app. Document the negative commitment in your privacy policy.

- [ ] **DON'T promise more than the AI can deliver.** Marketing copy that says "your personal Catholic AI confessor" invites theological complaint. Frame as "companion," "guide," "tool" — never "confessor," "spiritual director," "priest."

---

## Recommended 60-day priority list

If you want a concrete starting point when ready to pick this up:

1. **Custom ToS draft** (Termly + lawyer skim) — ~$300, ~4 hours of your time
2. **In-app account deletion affordance** — needed for App Store
3. **Find a priest or theologically-trained reviewer** — networking, no cost
4. **Trademark search + filing** for "Blissful Catholic" — ~$300, 2 hours
5. **Crisis response playbook** — 1 page, takes an hour to draft

Everything else can wait until after TestFlight feedback is in and the public-launch path is clearer.

---

## See also

- [`monetization.md`](./monetization.md) — Phase 5 implementation reference (RevenueCat, StoreKit 2, Stripe, product IDs, server-side gating)
- [`monetization-strategy.md`](./monetization-strategy.md) — Catholic theological framing, market landscape, layered revenue model, launch sequencing strategy
