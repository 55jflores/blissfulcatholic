# Liturgical Discipline — Holy Days of Obligation & Fasting/Abstinence

The rules behind the "holy day & fasting" notification (Tier-1). This data is
**not** available from romcal or our `/api/liturgy` (rank alone is not a proxy —
many solemnities are not obligation days, and the set is country-specific). So we
encode it ourselves as a pure, on-device, unit-testable rules type:
`Services/Liturgy/LiturgicalDiscipline.swift`. No API, no AI — just date logic.

Scope: **United States** norms (matches our romcal `country: "unitedStates"`).
A country setting can come later.

---

## 1. Holy Days of Obligation (US)

Six in the US. The fiddly part is the **abrogation rule**: three of them lose the
obligation when they fall on a Saturday or a Monday (so the faithful aren't bound
to Mass on two consecutive days).

| Solemnity | Date | Obligation rule |
|---|---|---|
| Mary, Mother of God | Jan 1 | abrogated if **Sat or Mon** |
| The Assumption | Aug 15 | abrogated if **Sat or Mon** |
| All Saints | Nov 1 | abrogated if **Sat or Mon** |
| The Immaculate Conception | Dec 8 | **always** (US patronal feast) |
| The Nativity (Christmas) | Dec 25 | **always** |
| The Ascension | Easter + 39 (Thu) | **deferred — see below** |

USCCB norm: *"Whenever Jan 1, Aug 15, or Nov 1 falls on a Saturday or a Monday,
the precept to attend Mass is abrogated."* Dec 8 and Dec 25 are never abrogated.

### Ascension — deliberately deferred in v1

Ascension is **province-dependent**: it remains on Thursday in a handful of US
provinces (Boston, Hartford, New York, Newark, Philadelphia, Omaha) but is
transferred to the 7th Sunday of Easter in most. For the Sunday provinces a
separate alert is redundant (Sunday Mass is already obligatory). Handling it
correctly needs either a province setting or a majority-rule assumption, so it's
cleaner as a follow-up than a v1 complication.

### Known limitation — Dec 8 on a Sunday

When Dec 8 falls on a Sunday, the Immaculate Conception is transferred to Monday
Dec 9, and the obligation handling has genuine canonical nuance (it has been
resolved differently in different years). v1 uses the simple "Dec 8 is the
obligation day" rule and does not model the transfer. Flagged here so it's a
known approximation, not a silent bug.

---

## 2. Fasting & Abstinence (US)

Derived from Easter (computed locally via the Gregorian computus), so no calendar
data is needed.

| Day | When | Abstinence (no meat) | Fasting (limited food) |
|---|---|---|---|
| Ash Wednesday | Easter − 46 | ✅ | ✅ |
| Fridays of Lent | Fridays between Ash Wed and Good Friday | ✅ | — |
| Good Friday | Easter − 2 | ✅ | ✅ |

### Important: NOT year-round Fridays

In the US, all Fridays are days of penance, but **outside Lent the abstinence
from meat may be substituted** with another penance. So we do **not** send a
"no meat today" alert on ordinary Fridays — only the Lenten Fridays + Ash
Wednesday + Good Friday above, where abstinence is obligatory.

---

## 3. API surface (`LiturgicalDiscipline`)

```
holyDayOfObligation(on: Date) -> HolyDay?     // nil unless an (un-abrogated) HDO
penitential(on: Date)        -> Penitential?  // nil unless Ash Wed / Lenten Fri / Good Fri
easter(year: Int)            -> Date          // Western/Gregorian Easter Sunday
```

`HolyDay` carries a display `name`; `Penitential` carries `name` + `abstinence` /
`fasting` flags. Both are value types so the scheduler can format notification
copy ("Tomorrow: The Assumption — a holy day of obligation").

---

## 4. Surfaces (in-app card + notifications)

Both the Daily card and the notifications are driven by the same rules, so they
can't disagree. The timing differs by *kind* of day, because holy days need
planning runway (weekday Mass) while penitential days are a day-of decision.

**Daily card** (`DailyView.disciplineCard`):
- **Holy days** — a **7-day countdown** card: "Tuesday, Dec 8 · in 7 days. Plan
  to attend Mass" → "Tomorrow…" → "Today — obliged to attend Mass."
- **Penitential** — **day-of** only, plus a **day-before** card for the two
  fasting days people plan around (Ash Wednesday / Good Friday). No week-ahead —
  Lent's Fridays are 7 days apart, so a countdown would carpet all of Lent.
- Shown regardless of the notification toggles (it's informational, not a nag).

**Notifications** (`NotificationService.scheduleDiscipline`). All fixed times,
device-local:
- **Holy days** — an **advance planning notice** at the user's chosen lead
  (`holyDayLeadDays`, options **1 / 3 / 7**, default 3) at **9 AM**, **plus** an
  always-on vigil-aware notice the evening before at **4 PM** (early enough to
  catch an evening vigil Mass). Lead == 1 suppresses the advance notice (it
  would collide with the evening-before one).
- **Penitential** — a **morning-of** notice at **7 AM**, plus a **6 PM
  evening-before** heads-up for Ash Wednesday / Good Friday.

The Gospel reminder is a separate, fixed **8 AM** (no longer user-configurable).

Both gated by `ReminderSettings` toggles (default on — informational, rare).
Copy is informative, never scolding.

---

## 5. Why a rules type (not the API)

- The data isn't in romcal/our API (verified — only a code comment mentions
  "obligation"; no field).
- Rank is not a proxy (St. Joseph, the Annunciation, etc. are solemnities but not
  obligation days).
- The abrogation + computus logic is small, fixed, and deterministic — exactly
  what belongs in a pure, unit-tested function rather than a network call.
