# Design: More Sections and a Live Feed

- **Date:** 2026-09-27
- **Status:** Approved in conversation; awaiting written-spec review
- **Builds on:** `2026-09-26-computed-vs-struct-views-design.md` and `2026-09-27-tap-to-display-latency-design.md` (their constraints still apply)
- **Conversation record:** `SessionLog.md`

## 1. Purpose

On an iPhone SE (2nd generation), the HUD shows the Computed app doing more work, but the app doesn't *feel* laggy.
The user wants lag that viewers notice without reading the HUD, while the Structs app visibly stays smooth.

People notice lag in two situations. The first is a continuous motion that drops frames, such as a stuttering scroll or
a slider thumb trailing the finger. The second is a single response slower than about 100–150 ms. Two levers push the
Computed app across that line:

1. **More sections (user's idea).** Ten new sections, each doing real derived work and none reading the changed state.
   Every update in the Computed app re-runs all of them; the Structs app skips them.
2. **A live feed (chosen in conversation).** A card updated 10 times a second from the dashboard's own `@State`. In the
   Computed app every tick re-runs **all 17 sections**, so the dashboard stutters while you merely scroll. In the Structs
   app only the live card re-runs.

As before, predictions are stated up front and whatever the devices show gets reported as measured.

## 2. Success criteria

1. Both dashboards have the same 17 sections in the same order, with section bodies textually identical between the
   apps (`Scripts/check-section-parity.sh` covers all 17).
2. With live updates on and nothing touched, the Computed app's badges all climb continuously; in the Structs app only
   the live card's badge climbs.
3. A **Live updates** setting (default **on**) and a `-liveUpdates off` launch argument turn the feed off. The HUD shows
   "Live on" or "Live off".
4. Package tests, SwiftLint (0 violations), parity, and Debug/Release builds of both apps pass.
5. `DemoShell`'s public API and the `App` structs are unchanged.

## 3. The sections

Final order, top to bottom: **live**, summary, timeRange, budget, chart, categories, transactions, cashFlow,
topMerchants, largestTransactions, weekdayPattern, spendingCalendar, categoryTrends, versusPrevious, upcomingBills,
subscriptions, savingsGoal. That's `DashboardSection` gaining 11 cases, with each name used as its parity marker and its
badge label.

| Section (marker) | Title | Inputs (Structs app) | Body work (via `TransactionMath`) |
|---|---|---|---|
| live | Live activity | `arrivals: [LiveArrival]` | Latest arrival (merchant, amount), sum of shown arrivals, sparkline of their amounts |
| cashFlow | Cash flow | transactions, timeRange | `dailyBalances`: running net per day across the range, as a `LineMark` chart |
| topMerchants | Top merchants | transactions, timeRange | `topMerchants(limit: 10)`: horizontal bars |
| largestTransactions | Largest expenses | transactions, timeRange | `largestExpenses(limit: 10)`: rows with merchant, date, and amount |
| weekdayPattern | By weekday | transactions, timeRange | `weekdayAverages`: 7 bars (average daily spend per weekday) |
| spendingCalendar | Spending calendar | transactions, timeRange | `dailySpend` (every day, zeros included) as a grid of colored day cells, 7 per row |
| categoryTrends | Category trends | transactions, timeRange | `categorySeries`: 8 small sparkline charts |
| versusPrevious | Versus previous period | transactions, timeRange | `categoryComparison` of the range vs `TimeRange.previousDateRange()`, one row per category |
| upcomingBills | Upcoming bills | transactions | `recurringCharges` → `upcomingBills(within: 30 days of the anchor)`, sorted by due date |
| subscriptions | Subscriptions | transactions | `recurringCharges`: list plus monthly total |
| savingsGoal | Savings goal | transactions | Year-to-date net vs a goal of 20% of year income, via `savingsProgress`, as a `Gauge` |

None of the new sections reads the budget, balance-visibility, pending-only, or live state. Sections 15–17
(upcomingBills, subscriptions, savingsGoal) also ignore the time range. So in the Structs app a time-range change
re-runs 13 of 17 sections, while the Computed app re-runs all 17.

The Computed app's `DashboardView` may exceed SwiftLint's `type_body_length`. If it does, a scoped, commented
`swiftlint:disable:next type_body_length` is allowed there, and only there.

## 4. Data changes (DashboardKit)

### Sample data (`SampleDataGenerator`)

- **Monthly recurring charges.** When `count >= 720`, the generator adds six fixed monthly charges on fixed days for each
  of the 12 months in the year window (72 transactions), carved out of `count` so every intensity keeps its total:

  | Merchant | Category | Amount | Day of month |
  |---|---|---|---|
  | Apartment Rent | home | $1,450.00 | 1 |
  | Gym Membership | health | $45.00 | 1 |
  | StreamBox | entertainment | $15.99 | 3 |
  | Fiber Internet Plan | utilities | $70.00 | 8 |
  | Mobile Plan | utilities | $55.00 | 12 |
  | Cloud Storage | shopping | $2.99 | 20 |

  They're dated at 10:00 GMT and are never pending. These merchant names aren't used by the random charges.
- **Paycheck scaling.** Each of the (up to 26) paychecks is `round(total spending × 1.1 / paycheck count, cents)`,
  so yearly income is about 110% of yearly spending and the savings goal is meaningful at every intensity.
  Determinism is unchanged.

### New `TransactionMath` functions and value types

- `DailyValue { day: Date; value: Decimal; amount: Double }` (Identifiable by `day`).
- `dailyBalances(of:in:calendar:) -> [DailyValue]`: one entry per day in the range; the running sum of net amounts from
  the range start (starting at 0 before the first day).
- `dailySpend(of:in:calendar:) -> [DailyValue]`: spending per day for every day in the range, zeros included.
- `MerchantTotal { merchant: String; total: Decimal; count: Int }` and `topMerchants(of:limit:)`: spending only, sorted
  by total descending, then merchant ascending.
- `largestExpenses(of:limit:) -> [AccountTransaction]`: by amount magnitude descending, then date descending.
- `WeekdayAverage { weekday: Int; average: Decimal }` and `weekdayAverages(of:in:calendar:)`: 7 entries (weekday
  1…7 in the calendar's numbering), each the average daily spend over the days in the range falling on that weekday
  (days without spending count as 0).
- `CategorySeries { category; points: [DailyValue] }` and `categorySeries(of:in:calendar:)`: one series per spending
  category, one point per day in the range.
- `TimeRange.previousDateRange(endingOn:calendar:) -> Range<Date>`: the equally long range ending where `dateRange`
  starts.
- `CategoryChange { category; current: Decimal; previous: Decimal }` and
  `categoryComparison(current:previous:) -> [CategoryChange]`: all 8 spending categories in category order.
- `RecurringCharge { merchant; category; amount: Decimal; lastDate: Date; nextDate: Date }` and
  `recurringCharges(of:calendar:)`. A merchant is recurring when it has ≥ 3 expenses, all with the same amount, and
  consecutive dates 27–32 days apart. `nextDate` is `lastDate` plus 1 month. Results are sorted by merchant.
- `upcomingBills(_ charges: [RecurringCharge], after anchor: Date, within days: Int, calendar:)`: charges whose
  `nextDate` falls in (anchor, anchor + days], sorted by `nextDate`.
- `savingsProgress(net: Decimal, goal: Decimal) -> Double`: clamped to 0…1. A goal ≤ 0 gives 1 if net > 0, else 0.

### Live feed

- `LiveArrival: Identifiable, Hashable, Sendable { id: Int; merchant: String; amount: Decimal }`.
- `enum LiveFeed`:
  - `static func arrival(at tick: Int, seed: UInt64 = SampleDataGenerator.defaultSeed) -> LiveArrival`: deterministic;
    merchant from a fixed list of 8 coffee, transit, and snack merchants; amount $0.99–$25.00.
  - `static func next(after arrivals: [LiveArrival], limit: Int = 30) -> [LiveArrival]`: appends the next arrival (tick
    = last id + 1, or 0) and keeps the last `limit`.
- **Settings.** `DemoSettings.liveUpdatesEnabled` (default true) comes from `LaunchArguments.liveUpdatesEnabled(from:)`,
  where `-liveUpdates off` means false. There's a Settings-menu toggle **Live updates**.
- **Environment.** `@Entry var liveUpdatesEnabled = true`, set by `DemoShell` from settings. The HUD gets it as an input
  and shows "Live on" or "Live off" after the intensity.

## 5. Dashboard wiring (both apps, identical)

- `DashboardView` gains `@State private var liveArrivals: [LiveArrival] = []` and reads
  `@Environment(\.liveUpdatesEnabled)`.
- `.task(id: liveUpdatesEnabled)`: when enabled, loop `try? await Task.sleep(for: .milliseconds(100))`, then
  `liveArrivals = LiveFeed.next(after: liveArrivals)`, until cancelled. The sleep comes *after* each update, so a busy
  main thread slows the ticks instead of queueing them.
- **Computed app:** 11 new `private var …: some View` sections with marker blocks.
- **Structs app:** 11 new files in `StructDashboard/Sections/`, generated from the Computed app's marker blocks by the same
  mechanical copy as before. The parent forwards only each section's inputs.
- The parity script's section list grows to all 17 names.

## 6. Testing and verification

### Unit tests (Swift Testing; add to `DashboardKit/Tests/TestList.md` before writing them)

- **Generator:**
  - With count ≥ 720, the 72 monthly charges appear (6 merchants × 12, correct days and amounts, never pending).
  - With count < 720, none appear.
  - The total count is unchanged.
  - Yearly income is within 1% of 110% of yearly spending.
- **`TransactionMath`:**
  - `dailyBalances`: running sums, one entry per day.
  - `dailySpend`: zero days included.
  - `topMerchants`: order and tie-break.
  - `largestExpenses`: order and limit.
  - `weekdayAverages`: 7 entries, zero days counted.
  - `categorySeries`: 8 series, one point per day.
  - `previousDateRange`: length and adjacency for each range.
  - `categoryComparison`: all 8 categories.
  - `recurringCharges`: detects the fixed monthly charges; rejects varying amounts and irregular gaps.
  - `upcomingBills`: window boundaries and order.
  - `savingsProgress`: clamping and goal ≤ 0.
- **`LiveFeed`:** determinism per tick, the amount range, `next` appending and trimming to the limit, and ids increasing
  by 1.
- **Settings:** `-liveUpdates off` gives false; absent gives true.

### Simulator verification

1. The parity script passes for 17 sections. Debug and Release builds of both apps pass.
2. **Badges** (`-showEvaluationBadges`, Live on, nothing touched for 5 s): every badge climbs in the Computed app. In the
   Structs app, only `live` climbs.
3. **Scrolling** with Live on at Realistic in each app: read HUD FPS and hitches after scrolling for about 10 s.
   Simulator numbers go to the working ledger, **not** the Journal.
4. **Tap timings** with `-liveUpdates off`: open and eye readings still behave as before.

## 7. Risks

- **With Live on, the Computed app may become sluggish to operate at higher intensities.** That's the point of the demo.
  The switch and the self-throttling loop keep the app usable.
- **Recurring-charge detection is heuristic.** The rules (equal amounts, 27–32 day gaps, ≥ 3 occurrences) are pinned by
  tests, and the fixed charges are designed to match them. Random charges vary in amount, so they don't.
- **Opening the dashboard gets slower** with 17 sections in both apps. It remains a control case.
- **Tap timings can include live-tick rebuilds** when Live is on. The capture guide says to time taps with Live off.
- **The Structs parent re-renders 10 times a second** to forward the new arrivals. It only forwards inputs; badges verify
  that no other section re-runs.

## 8. Documentation and repository

- Work on a new local branch, `feature/more-sections`, cut from `main`. Nothing gets pushed. Merge when the user says so.
- `CLAUDE.md`: the 17-section list, the live feed, and the switch and launch argument.
- `Captures/README.md`: film scrolling with Live on, time taps with Live off; note the setting in `CaptureNotes.md`.
- `Journal.md`: a feature entry only, with **no measured numbers**.
- `SessionLog.md` keeps recording every turn.
