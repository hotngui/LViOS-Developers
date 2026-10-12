# More Sections and a Live Feed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow both dashboards from 6 to 17 sections (10 data sections plus a live-activity card updated 10 times a second from the dashboard's `@State`), so that the Computed app's lag is felt, not just measured, while the Structs app stays smooth.

**Architecture:**
- New pure, tested math in `DashboardKit`: new `TransactionMath` functions and value types, `TimeRange.previousDateRange`, a `LiveFeed`, and sample-data changes (monthly recurring charges, scaled paychecks).
- A **Live updates** setting (environment + launch argument + HUD label).
- In the apps: 11 new marker-delimited section bodies written once in the Computed app and copied mechanically into 11 Structs-app section structs, plus an identical `.task` live loop in both parents.

**Tech Stack:** Swift 6.4 (Swift 6 mode), SwiftUI + Swift Charts (iOS 27 SDK), Swift Testing, Xcode 27.1, SwiftLint 0.65.1.

**Spec:** `docs/superpowers/specs/2026-09-27-more-sections-live-feed-design.md`

## Global Constraints

- All constraints of the earlier plans still apply:
  - iOS 27.0; Swift 6 strict concurrency; `@MainActor` on `@Observable`.
  - One type per file; no force unwraps; no hard-coded padding or font sizes; Swift Testing only.
  - SwiftLint at 0 violations before every commit (`swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml`).
  - Always pass `-configuration` to `xcodebuild` (the shared schemes default to Release).
- Local branch **`feature/more-sections`** cut from `main`. **Never push.** End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Section bodies are textually identical between the apps. `Scripts/check-section-parity.sh` must pass for all 17 sections.
- The existing six section bodies don't change. `DemoShell`'s public API and the `App` structs don't change.
- Only the Computed app's `DashboardView` may carry a scoped, commented `// swiftlint:disable:next type_body_length`.
- `Journal.md` gets a feature entry with **no measured numbers**. Simulator readings go only to the working ledger.
- `SessionLog.md` is maintained by the main session only.
- Repo root: `/Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView`. Simulator: `SIM=B9BB0E3F-E390-472F-AD17-952DA5298A94` (iPhone 18 Pro, iOS 27.0).
- Section order and marker names: `live, summary, timeRange, budget, chart, categories, transactions, cashFlow, topMerchants, largestTransactions, weekdayPattern, spendingCalendar, categoryTrends, versusPrevious, upcomingBills, subscriptions, savingsGoal`.

## Review Focus

1. **Leaving the dashboard (Back) stops the live loop.** Back on the start screen, FPS returns to normal and no section badge keeps climbing. → Task 6, Step 3.
2. **Turning Live updates off mid-run stops the ticks at once.** The live card freezes and the badges stop. → Task 6, Step 3.
3. **With Live on at Heavy, the Computed app stays operable.** Back, the gear menu, and the Live toggle still respond, since the loop sleeps after each update. → Task 6, Step 4.
4. **A previous period with no data** (before the generated year) compares against zeros, never crashes or produces NaN. → Task 2, `categoryComparisonFillsAllCategoriesWithZeros` and `savingsProgressClampsAndHandlesAZeroGoal`.
5. **The Structs parent's 10 Hz re-renders** re-run only the live card, not any other section. → Task 6, Step 2 (badges).

---

### Task 1: Branch, monthly charges, and scaled paychecks

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Data/MonthlyCharge.swift`
- Modify (replace entirely): `DashboardKit/Sources/DashboardKit/Data/SampleDataGenerator.swift`
- Modify: `DashboardKit/Tests/DashboardKitTests/SampleDataGeneratorTests.swift`, `DashboardKit/Tests/TestList.md`

**Interfaces:**
- Produces:
  - `struct MonthlyCharge { merchant: String; category: TransactionCategory; cents: Int; day: Int }` (internal)
  - `SampleDataGenerator.monthlyCharges: [MonthlyCharge]` (6 entries)
  - `SampleDataGenerator.monthlyChargeThreshold = 720`
  - `SampleDataGenerator.incomeToSpendingRatio: Decimal = 1.1`
- `makeTransactions(count:seed:anchor:calendar:)` keeps its signature and its guarantees (count, determinism, newest first, ids `0..<count`).

- [ ] **Step 1: Branch**

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
git switch -c feature/more-sections
```

- [ ] **Step 2: Add to `DashboardKit/Tests/TestList.md` (before writing tests)**

```markdown

## More sections: sample data (SampleDataGeneratorTests)
- With count ≥ 720, 72 monthly charges appear: 6 merchants × 12, on their fixed days, with fixed amounts, never pending.
- With count < 720, no monthly charges appear.
- The total count is unchanged when monthly charges are added.
- Yearly income is within 1% of 110% of yearly spending.

## More sections: TransactionMath insights (TransactionInsightsTests)
- dailyBalances: one entry per day in the range, running net from zero.
- dailySpend: one entry per day in the range, zero days included, income ignored.
- topMerchants: spending only, total descending, ties by merchant name, limited.
- largestExpenses: magnitude descending, ties newest first, limited, income ignored.
- weekdayAverages: seven entries; averages over the range's days (zero days count).
- categorySeries: eight series, one point per day.
- previousDateRange: same length, ends where dateRange starts, for every range.
- categoryComparison fills all eight categories, with zeros where there's no spending. (Review Focus 4)
- recurringCharges detects equal-amount monthly charges and rejects varying amounts, irregular gaps, and < 3 charges.
- recurringCharges on generated data (count 1,000) finds exactly the six monthly merchants.
- upcomingBills keeps (anchor, anchor + days], sorted by next date.
- savingsProgress clamps to 0…1 and handles a goal ≤ 0. (Review Focus 4)

## More sections: live feed and setting (LiveFeedTests, IntensityTests, DemoSettingsTests)
- arrival(at:) is deterministic per tick; amounts stay within $0.99–$25.00.
- next(after:) appends tick last + 1 (0 first) and keeps the last 30.
- -liveUpdates off (any case) disables live updates; absent or "on" enables them.
```

- [ ] **Step 3: Write the failing generator tests**

Append these tests inside `SampleDataGeneratorTests` (before its closing brace) in `DashboardKit/Tests/DashboardKitTests/SampleDataGeneratorTests.swift`:

```swift
    static let large = make(count: 1_000)
    static let monthlyMerchants = Set(SampleDataGenerator.monthlyCharges.map(\.merchant))

    @Test func largeCountsIncludeTwelveOfEachMonthlyCharge() {
        let monthly = Self.large.filter { Self.monthlyMerchants.contains($0.merchant) }
        #expect(monthly.count == 72)
        for charge in SampleDataGenerator.monthlyCharges {
            let matches = monthly.filter { $0.merchant == charge.merchant }
            #expect(matches.count == 12)
            #expect(matches.allSatisfy { $0.amount == -Decimal(charge.cents) / 100 && !$0.isPending })
            #expect(matches.allSatisfy { DemoClock.calendar.component(.day, from: $0.date) == charge.day })
        }
    }

    @Test func smallCountsHaveNoMonthlyCharges() {
        #expect(!Self.sample.contains { Self.monthlyMerchants.contains($0.merchant) })
    }

    @Test func monthlyChargesDoNotChangeTheTotalCount() {
        #expect(Self.large.count == 1_000)
    }

    @Test func yearlyIncomeIsAboutTenPercentAboveSpending() {
        let income = NSDecimalNumber(decimal: TransactionMath.income(of: Self.large)).doubleValue
        let spending = NSDecimalNumber(decimal: TransactionMath.expenses(of: Self.large)).doubleValue
        #expect(abs(income / spending - 1.1) < 0.011)
    }
```

Run: `swift test --package-path DashboardKit --filter SampleDataGeneratorTests`
Expected: build failure: `type 'SampleDataGenerator' has no member 'monthlyCharges'`.

- [ ] **Step 4: Implement**

`DashboardKit/Sources/DashboardKit/Data/MonthlyCharge.swift`:

```swift
/// A fixed charge the sample data repeats every month, so the recurring-charge sections have something real to find.
struct MonthlyCharge: Sendable {
    let merchant: String
    let category: TransactionCategory
    let cents: Int
    /// Day of the month it posts (at 10:00 GMT).
    let day: Int
}
```

Replace `DashboardKit/Sources/DashboardKit/Data/SampleDataGenerator.swift` with:

```swift
import Foundation

/// Builds a deterministic year of account activity, so both demo apps show exactly the same transactions.
public enum SampleDataGenerator {
    public static let defaultSeed: UInt64 = 2_026

    /// At most this many paychecks, one every 14 days.
    static let paydayCount = 26
    static let secondsPerDay: TimeInterval = 86_400
    /// Monthly charges are included only when there's room for them (6 × 12 = 72 transactions).
    static let monthlyChargeThreshold = 720
    /// Paychecks are sized so a year's income is this multiple of its spending.
    static let incomeToSpendingRatio: Decimal = 1.1

    static let monthlyCharges: [MonthlyCharge] = [
        MonthlyCharge(merchant: "Apartment Rent", category: .home, cents: 145_000, day: 1),
        MonthlyCharge(merchant: "Gym Membership", category: .health, cents: 4_500, day: 1),
        MonthlyCharge(merchant: "StreamBox", category: .entertainment, cents: 1_599, day: 3),
        MonthlyCharge(merchant: "Fiber Internet Plan", category: .utilities, cents: 7_000, day: 8),
        MonthlyCharge(merchant: "Mobile Plan", category: .utilities, cents: 5_500, day: 12),
        MonthlyCharge(merchant: "Cloud Storage", category: .shopping, cents: 299, day: 20)
    ]

    /// Generates `count` transactions for the year ending on the demo anchor date, off the main actor.
    @concurrent
    public static func transactions(count: Int, seed: UInt64 = defaultSeed) async -> [AccountTransaction] {
        makeTransactions(count: count, seed: seed, anchor: DemoClock.anchorDate, calendar: DemoClock.calendar)
    }

    /// The synchronous core. Returns newest first, with ids `0..<count`.
    static func makeTransactions(count: Int, seed: UInt64, anchor: Date, calendar: Calendar) -> [AccountTransaction] {
        guard count > 0 else { return [] }
        var generator = SeededRandomGenerator(seed: seed)
        let year = TimeRange.year.dateRange(endingOn: anchor, calendar: calendar)
        let incomeCount = min(paydayCount, count / 10)
        let monthly = count >= monthlyChargeThreshold ? monthlyTransactions(in: year, calendar: calendar) : []
        let randomCount = max(count - incomeCount - monthly.count, 0)
        let expenses = monthly + randomExpenses(count: randomCount, in: year, using: &generator)
        let spent = expenses.reduce(Decimal.zero) { $0 - $1.amount }
        let paycheck = incomeCount > 0 ? roundedToCents(spent * incomeToSpendingRatio / Decimal(incomeCount)) : 0
        var entries = paychecks(count: incomeCount, amount: paycheck, in: year) + expenses
        entries.sort { $0.date > $1.date }
        return entries.enumerated().map { $0.element.withID($0.offset) }
    }

    static func paychecks(count: Int, amount: Decimal, in year: Range<Date>) -> [AccountTransaction] {
        (0..<count).map { index in
            let payday = year.lowerBound.addingTimeInterval(TimeInterval(index * 14) * secondsPerDay + 9 * 3_600)
            return AccountTransaction(
                id: 0, date: payday, merchant: "Employer Payroll", category: .income, amount: amount, isPending: false
            )
        }
    }

    static func monthlyTransactions(in year: Range<Date>, calendar: Calendar) -> [AccountTransaction] {
        (0..<12).flatMap { month in
            let monthStart = calendar.date(byAdding: .month, value: month, to: year.lowerBound) ?? year.lowerBound
            return monthlyCharges.map { charge in
                let day = calendar.date(byAdding: .day, value: charge.day - 1, to: monthStart) ?? monthStart
                return AccountTransaction(
                    id: 0, date: day.addingTimeInterval(10 * 3_600), merchant: charge.merchant, category: charge.category,
                    amount: -Decimal(charge.cents) / 100, isPending: false
                )
            }
        }
    }

    static func randomExpenses(count: Int, in year: Range<Date>, using generator: inout SeededRandomGenerator) -> [AccountTransaction] {
        let span = year.upperBound.timeIntervalSince(year.lowerBound)
        let spending = TransactionCategory.spending
        return (0..<count).map { _ in
            let category = spending[Int.random(in: 0..<spending.count, using: &generator)]
            let names = merchants(for: category)
            let merchant = names[Int.random(in: 0..<names.count, using: &generator)]
            let cents = Int.random(in: centsRange(for: category), using: &generator)
            let date = year.lowerBound.addingTimeInterval(Double.random(in: 0..<span, using: &generator))
            let isPending = Int.random(in: 0..<20, using: &generator) == 0
            return AccountTransaction(
                id: 0, date: date, merchant: merchant, category: category, amount: -Decimal(cents) / 100, isPending: isPending
            )
        }
    }

    static func roundedToCents(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    static func merchants(for category: TransactionCategory) -> [String] {
        switch category {
        case .income: ["Employer Payroll"]
        case .groceries: ["Green Basket Market", "Corner Grocer", "FreshCo", "Harvest Foods"]
        case .dining: ["Blue Door Café", "Noodle Bar", "Taco Stand", "Slice Pizza"]
        case .transport: ["Metro Transit", "City Rideshare", "Fuel Stop", "Parking Garage"]
        case .home: ["Hardware Depot", "Home Goods", "Garden Center", "Furniture Barn"]
        case .utilities: ["Power & Light", "Water Utility", "Fiber Internet", "Mobile Carrier"]
        case .entertainment: ["Cinema 8", "Streaming Plus", "Game Shop", "Concert Hall"]
        case .shopping: ["Department Store", "Bookshop", "Shoe Outlet", "Online Market"]
        case .health: ["Pharmacy", "Clinic Copay", "Fitness Club", "Dental Care"]
        }
    }

    /// Amount range in cents for one transaction of the category.
    static func centsRange(for category: TransactionCategory) -> ClosedRange<Int> {
        switch category {
        case .income: 325_000...325_000
        case .groceries: 500...12_000
        case .dining: 400...6_000
        case .transport: 200...4_500
        case .home: 500...15_000
        case .utilities: 2_000...15_000
        case .entertainment: 300...6_000
        case .shopping: 500...20_000
        case .health: 500...12_000
        }
    }
}

private extension AccountTransaction {
    func withID(_ id: Int) -> AccountTransaction {
        AccountTransaction(id: id, date: date, merchant: merchant, category: category, amount: amount, isPending: isPending)
    }
}
```

The random expenses are drawn in the same order as before, so the random part of the data is unchanged.

- [ ] **Step 5: Run, lint, commit**

Run: `swift test --package-path DashboardKit` → all pass (including the 4 new tests).
Run SwiftLint → 0 violations. If the `randomExpenses` definition line exceeds 132 characters, wrap its parameters onto their own lines, which AGENTS.md allows when the one-line definition would be too long.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add monthly recurring charges and scale paychecks to spending

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: TransactionMath insights and `previousDateRange`

**Files:**
- Create in `DashboardKit/Sources/DashboardKit/Math/`: `DailyValue.swift`, `MerchantTotal.swift`, `WeekdayAverage.swift`, `CategorySeries.swift`, `CategoryChange.swift`, `RecurringCharge.swift`, `TransactionMath+Insights.swift`
- Modify: `DashboardKit/Sources/DashboardKit/Model/TimeRange.swift` (add `previousDateRange`)
- Modify: `DashboardKit/Tests/DashboardKitTests/Fixture.swift` (add a `merchant:` parameter)
- Test: `DashboardKit/Tests/DashboardKitTests/TransactionInsightsTests.swift`

**Interfaces (all `public` unless noted):**
- `struct DailyValue: Identifiable, Hashable, Sendable { day: Date; value: Decimal; id: Date; amount: Double }`
- `struct MerchantTotal: Identifiable, Hashable, Sendable { merchant: String; total: Decimal; count: Int; id: String; amount: Double }`
- `struct WeekdayAverage: Identifiable, Hashable, Sendable { weekday: Int; average: Decimal; id: Int; amount: Double }`
- `struct CategorySeries: Identifiable, Hashable, Sendable { category: TransactionCategory; points: [DailyValue]; id }`
- `struct CategoryChange: Identifiable, Hashable, Sendable { category; current: Decimal; previous: Decimal; id; difference: Decimal }`
- `struct RecurringCharge: Identifiable, Hashable, Sendable { merchant: String; category; amount: Decimal; lastDate: Date; nextDate: Date; id: String }`
- `TransactionMath`:
  - `dailyBalances(of:in:calendar:)`, `dailySpend(of:in:calendar:)`
  - `topMerchants(of:limit:)`, `largestExpenses(of:limit:)`
  - `weekdayAverages(of:in:calendar:)`, `categorySeries(of:in:calendar:)`
  - `categoryComparison(current:previous:)`
  - `recurringCharges(of:calendar:)`, `upcomingBills(_:after:within:calendar:)`
  - `savingsProgress(net:goal:)`
  - internal `days(in:calendar:)`
- `TimeRange.previousDateRange(endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar) -> Range<Date>`

- [ ] **Step 1: Extend the test fixture**

In `DashboardKit/Tests/DashboardKitTests/Fixture.swift`, replace the `transaction` function with:

```swift
    static func transaction(
        _ amount: Decimal, _ category: TransactionCategory, on date: Date, merchant: String = "Test Merchant", isPending: Bool = false
    ) -> AccountTransaction {
        AccountTransaction(id: 0, date: date, merchant: merchant, category: category, amount: amount, isPending: isPending)
    }
```

- [ ] **Step 2: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/TransactionInsightsTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct TransactionInsightsTests {
    let week = TimeRange.week.dateRange()
    let calendar = DemoClock.calendar

    func day(_ offset: Int) -> Date { Fixture.date(dayOffset: offset, hour: 0) }

    @Test func dailyBalancesRunFromZeroOneEntryPerDay() {
        let sample = [
            Fixture.transaction(100, .income, on: Fixture.date(dayOffset: -2)),
            Fixture.transaction(-30, .dining, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-20, .dining, on: Fixture.date(dayOffset: 0))
        ]
        let balances = TransactionMath.dailyBalances(of: sample, in: week, calendar: calendar)
        #expect(balances.map(\.day) == (-6...0).map(day))
        #expect(balances.map(\.value) == [0, 0, 0, 0, 100, 70, 50])
    }

    @Test func dailySpendIncludesZeroDaysAndIgnoresIncome() {
        let sample = [
            Fixture.transaction(-12, .home, on: Fixture.date(dayOffset: -3)),
            Fixture.transaction(500, .income, on: Fixture.date(dayOffset: -3))
        ]
        let spend = TransactionMath.dailySpend(of: sample, in: week, calendar: calendar)
        #expect(spend.count == 7)
        #expect(spend.map(\.value) == [0, 0, 0, 12, 0, 0, 0])
    }

    @Test func topMerchantsSortByTotalThenNameAndHonorTheLimit() {
        let sample = [
            Fixture.transaction(-10, .dining, on: day(-1), merchant: "A"),
            Fixture.transaction(-5, .dining, on: day(-1), merchant: "A"),
            Fixture.transaction(-15, .dining, on: day(-1), merchant: "B"),
            Fixture.transaction(-20, .dining, on: day(-1), merchant: "C"),
            Fixture.transaction(99, .income, on: day(-1), merchant: "Payroll")
        ]
        let top = TransactionMath.topMerchants(of: sample, limit: 2)
        #expect(top.map(\.merchant) == ["C", "A"])
        #expect(top.map(\.total) == [20, 15])
        #expect(top.last?.count == 2)
    }

    @Test func largestExpensesSortByMagnitudeThenNewestFirst() {
        let older = Fixture.transaction(-20, .home, on: day(-3), merchant: "Older")
        let newer = Fixture.transaction(-20, .home, on: day(-1), merchant: "Newer")
        let sample = [Fixture.transaction(-5, .home, on: day(-2)), older, Fixture.transaction(-50, .home, on: day(-2)), newer,
                      Fixture.transaction(100, .income, on: day(-2))]
        let largest = TransactionMath.largestExpenses(of: sample, limit: 3)
        #expect(largest.map(\.amount) == [-50, -20, -20])
        #expect(largest.map(\.merchant).suffix(2) == ["Newer", "Older"])
    }

    @Test func weekdayAveragesCoverSevenWeekdaysIncludingZeroDays() {
        let sample = [Fixture.transaction(-14, .dining, on: Fixture.date(dayOffset: 0))]
        let averages = TransactionMath.weekdayAverages(of: sample, in: week, calendar: calendar)
        let anchorWeekday = calendar.component(.weekday, from: DemoClock.anchorDate)
        #expect(averages.map(\.weekday) == Array(1...7))
        #expect(averages.first { $0.weekday == anchorWeekday }?.average == 14)
        #expect(averages.filter { $0.weekday != anchorWeekday }.allSatisfy { $0.average == 0 })
    }

    @Test func categorySeriesHasEightSeriesWithOnePointPerDay() {
        let sample = [Fixture.transaction(-9, .transport, on: Fixture.date(dayOffset: -2))]
        let series = TransactionMath.categorySeries(of: sample, in: week, calendar: calendar)
        #expect(series.map(\.category) == TransactionCategory.spending)
        #expect(series.allSatisfy { $0.points.count == 7 })
        #expect(series.first { $0.category == .transport }?.points.map(\.value) == [0, 0, 0, 0, 9, 0, 0])
    }

    @Test(arguments: TimeRange.allCases)
    func previousDateRangeHasTheSameLengthAndEndsWhereTheRangeStarts(range: TimeRange) {
        let current = range.dateRange()
        let previous = range.previousDateRange()
        #expect(previous.upperBound == current.lowerBound)
        #expect(previous.upperBound.timeIntervalSince(previous.lowerBound) == current.upperBound.timeIntervalSince(current.lowerBound))
    }

    @Test func categoryComparisonFillsAllCategoriesWithZeros() {
        let current = [Fixture.transaction(-10, .dining, on: day(-1))]
        let previous = [Fixture.transaction(-4, .dining, on: day(-9)), Fixture.transaction(-6, .groceries, on: day(-9))]
        let changes = TransactionMath.categoryComparison(current: current, previous: previous)
        #expect(changes.map(\.category) == TransactionCategory.spending)
        #expect(changes.first { $0.category == .dining }.map { [$0.current, $0.previous] } == [10, 4])
        #expect(changes.first { $0.category == .groceries }.map { [$0.current, $0.previous] } == [0, 6])
        #expect(changes.first { $0.category == .health }?.difference == 0)
    }

    @Test func recurringChargesFindEqualMonthlyChargesOnly() {
        let start = Fixture.date(dayOffset: -120)
        func monthly(_ months: Int) -> Date { calendar.date(byAdding: .month, value: months, to: start) ?? start }
        let sample = (0..<4).map { Fixture.transaction(-45, .health, on: monthly($0), merchant: "Gym") }
            + (0..<4).map { Fixture.transaction(Decimal(-10 - $0), .dining, on: monthly($0), merchant: "Varying") }
            + (0..<4).map { Fixture.transaction(-9, .shopping, on: start.addingTimeInterval(Double($0) * 10 * 86_400), merchant: "Irregular") }
            + (0..<2).map { Fixture.transaction(-5, .shopping, on: monthly($0), merchant: "Twice") }
        let charges = TransactionMath.recurringCharges(of: sample, calendar: calendar)
        #expect(charges.map(\.merchant) == ["Gym"])
        #expect(charges.first?.amount == 45)
        #expect(charges.first?.nextDate == monthly(4))
    }

    @Test func recurringChargesOnGeneratedDataFindTheSixMonthlyMerchants() {
        let data = SampleDataGenerator.makeTransactions(
            count: 1_000, seed: SampleDataGenerator.defaultSeed, anchor: DemoClock.anchorDate, calendar: calendar
        )
        let merchants = TransactionMath.recurringCharges(of: data, calendar: calendar).map(\.merchant)
        #expect(merchants == SampleDataGenerator.monthlyCharges.map(\.merchant).sorted())
    }

    @Test func upcomingBillsKeepTheWindowAndSortByDate() {
        let anchor = DemoClock.anchorDate
        func charge(_ name: String, dueIn days: Double) -> RecurringCharge {
            RecurringCharge(merchant: name, category: .utilities, amount: 10, lastDate: anchor,
                            nextDate: anchor.addingTimeInterval(days * 86_400))
        }
        let charges = [charge("Late", dueIn: 31), charge("Second", dueIn: 20), charge("Now", dueIn: 0), charge("First", dueIn: 1)]
        let bills = TransactionMath.upcomingBills(charges, after: anchor, within: 30, calendar: calendar)
        #expect(bills.map(\.merchant) == ["First", "Second"])
    }

    @Test func savingsProgressClampsAndHandlesAZeroGoal() {
        #expect(TransactionMath.savingsProgress(net: 50, goal: 100) == 0.5)
        #expect(TransactionMath.savingsProgress(net: 150, goal: 100) == 1)
        #expect(TransactionMath.savingsProgress(net: -10, goal: 100) == 0)
        #expect(TransactionMath.savingsProgress(net: 5, goal: 0) == 1)
        #expect(TransactionMath.savingsProgress(net: 0, goal: 0) == 0)
    }
}
```

Run: `swift test --package-path DashboardKit --filter TransactionInsightsTests`
Expected: build failure: `type 'TransactionMath' has no member 'dailyBalances'` (and similar).
If any test line exceeds 132 characters under SwiftLint, wrap the call's arguments; don't change the assertions.

- [ ] **Step 3: Implement the value types**

`Math/DailyValue.swift`:

```swift
import Foundation

/// One value for one day, e.g. a running balance or that day's spending.
public struct DailyValue: Identifiable, Hashable, Sendable {
    public let day: Date
    public let value: Decimal

    public var id: Date { day }
    /// `value` as a `Double`, the type Swift Charts plots.
    public var amount: Double { NSDecimalNumber(decimal: value).doubleValue }
}
```

`Math/MerchantTotal.swift`:

```swift
import Foundation

/// Spending at one merchant within a range.
public struct MerchantTotal: Identifiable, Hashable, Sendable {
    public let merchant: String
    /// Positive amount spent.
    public let total: Decimal
    public let count: Int

    public var id: String { merchant }
    public var amount: Double { NSDecimalNumber(decimal: total).doubleValue }
}
```

`Math/WeekdayAverage.swift`:

```swift
import Foundation

/// Average daily spending on one weekday (1…7, in the calendar's numbering) within a range.
public struct WeekdayAverage: Identifiable, Hashable, Sendable {
    public let weekday: Int
    public let average: Decimal

    public var id: Int { weekday }
    public var amount: Double { NSDecimalNumber(decimal: average).doubleValue }
}
```

`Math/CategorySeries.swift`:

```swift
/// One spending category's daily totals across a range, for a sparkline.
public struct CategorySeries: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    public let points: [DailyValue]

    public var id: TransactionCategory { category }
}
```

`Math/CategoryChange.swift`:

```swift
import Foundation

/// Spending in one category for the current range and the equally long range before it.
public struct CategoryChange: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    public let current: Decimal
    public let previous: Decimal

    public var id: TransactionCategory { category }
    public var difference: Decimal { current - previous }
}
```

`Math/RecurringCharge.swift`:

```swift
import Foundation

/// A charge that repeats monthly for the same amount, with its projected next date.
public struct RecurringCharge: Identifiable, Hashable, Sendable {
    public let merchant: String
    public let category: TransactionCategory
    /// Positive monthly amount.
    public let amount: Decimal
    public let lastDate: Date
    public let nextDate: Date

    public var id: String { merchant }
}
```

- [ ] **Step 4: Implement the functions**

`Math/TransactionMath+Insights.swift`:

```swift
import Foundation

/// Derived work for the ten additional dashboard sections. Pure functions, like the rest of `TransactionMath`.
extension TransactionMath {
    /// The start of every day in `range`.
    static func days(in range: Range<Date>, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: range.lowerBound)
        while day < range.upperBound {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The running net amount at the end of each day in `range`, starting from zero.
    public static func dailyBalances(of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar) -> [DailyValue] {
        var netByDay: [Date: Decimal] = [:]
        for transaction in transactions where range.contains(transaction.date) {
            netByDay[calendar.startOfDay(for: transaction.date), default: 0] += transaction.amount
        }
        var running = Decimal.zero
        return days(in: range, calendar: calendar).map { day in
            running += netByDay[day, default: 0]
            return DailyValue(day: day, value: running)
        }
    }

    /// Spending on each day in `range`, including days with none.
    public static func dailySpend(of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar) -> [DailyValue] {
        var spendByDay: [Date: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 && range.contains(transaction.date) {
            spendByDay[calendar.startOfDay(for: transaction.date), default: 0] -= transaction.amount
        }
        return days(in: range, calendar: calendar).map { DailyValue(day: $0, value: spendByDay[$0, default: 0]) }
    }

    /// Merchants by spending, largest first (ties by name).
    public static func topMerchants(of transactions: [AccountTransaction], limit: Int) -> [MerchantTotal] {
        var totals: [String: Decimal] = [:]
        var counts: [String: Int] = [:]
        for transaction in transactions where transaction.amount < 0 {
            totals[transaction.merchant, default: 0] -= transaction.amount
            counts[transaction.merchant, default: 0] += 1
        }
        let sorted = totals
            .map { MerchantTotal(merchant: $0.key, total: $0.value, count: counts[$0.key, default: 0]) }
            .sorted { $0.total != $1.total ? $0.total > $1.total : $0.merchant < $1.merchant }
        return Array(sorted.prefix(limit))
    }

    /// The biggest expenses, largest first (ties newest first).
    public static func largestExpenses(of transactions: [AccountTransaction], limit: Int) -> [AccountTransaction] {
        let sorted = transactions
            .filter { $0.amount < 0 }
            .sorted { $0.amount != $1.amount ? $0.amount < $1.amount : $0.date > $1.date }
        return Array(sorted.prefix(limit))
    }

    /// Average daily spending per weekday over the days in `range` (days without spending count as zero).
    public static func weekdayAverages(of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar) -> [WeekdayAverage] {
        var sums: [Int: Decimal] = [:]
        var dayCounts: [Int: Int] = [:]
        for day in dailySpend(of: transactions, in: range, calendar: calendar) {
            let weekday = calendar.component(.weekday, from: day.day)
            sums[weekday, default: 0] += day.value
            dayCounts[weekday, default: 0] += 1
        }
        return (1...7).map { weekday in
            let dayCount = dayCounts[weekday, default: 0]
            let average = dayCount > 0 ? sums[weekday, default: 0] / Decimal(dayCount) : 0
            return WeekdayAverage(weekday: weekday, average: average)
        }
    }

    /// Each spending category's daily totals across `range`.
    public static func categorySeries(of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar) -> [CategorySeries] {
        var lookup: [DailyCategoryTotal.Key: Decimal] = [:]
        for bin in dailyTotals(of: transactions.filter { range.contains($0.date) }, calendar: calendar) {
            lookup[bin.key] = bin.total
        }
        let allDays = days(in: range, calendar: calendar)
        return TransactionCategory.spending.map { category in
            let points = allDays.map { day in
                DailyValue(day: day, value: lookup[DailyCategoryTotal.Key(day: day, category: category), default: 0])
            }
            return CategorySeries(category: category, points: points)
        }
    }

    /// Spending per category now vs the previous period, for all eight spending categories.
    public static func categoryComparison(current: [AccountTransaction], previous: [AccountTransaction]) -> [CategoryChange] {
        let now = categoryTotals(of: current)
        let before = categoryTotals(of: previous)
        return TransactionCategory.spending.map { category in
            CategoryChange(
                category: category,
                current: now.first { $0.category == category }?.total ?? 0,
                previous: before.first { $0.category == category }?.total ?? 0
            )
        }
    }

    /// Merchants charged the same amount at least three times, 27–32 days apart. Sorted by merchant.
    public static func recurringCharges(of transactions: [AccountTransaction], calendar: Calendar) -> [RecurringCharge] {
        let byMerchant = Dictionary(grouping: transactions.filter { $0.amount < 0 }, by: \.merchant)
        var result: [RecurringCharge] = []
        for (merchant, charges) in byMerchant where charges.count >= 3 {
            let sorted = charges.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last, sorted.allSatisfy({ $0.amount == first.amount }) else { continue }
            let isMonthly = zip(sorted, sorted.dropFirst()).allSatisfy { earlier, later in
                (27.0...32.0).contains(later.date.timeIntervalSince(earlier.date) / 86_400)
            }
            guard isMonthly, let next = calendar.date(byAdding: .month, value: 1, to: last.date) else { continue }
            result.append(
                RecurringCharge(merchant: merchant, category: first.category, amount: -first.amount, lastDate: last.date, nextDate: next)
            )
        }
        return result.sorted { $0.merchant < $1.merchant }
    }

    /// Charges due after `anchor` and no later than `days` days after it, soonest first.
    public static func upcomingBills(_ charges: [RecurringCharge], after anchor: Date, within days: Int, calendar: Calendar) -> [RecurringCharge] {
        let end = calendar.date(byAdding: .day, value: days, to: anchor) ?? anchor
        return charges.filter { $0.nextDate > anchor && $0.nextDate <= end }.sorted { $0.nextDate < $1.nextDate }
    }

    /// Fraction of the savings goal reached, clamped to 0…1. A goal ≤ 0 reads as reached if anything was saved.
    public static func savingsProgress(net: Decimal, goal: Decimal) -> Double {
        guard goal > 0 else { return net > 0 ? 1 : 0 }
        return min(max(NSDecimalNumber(decimal: net / goal).doubleValue, 0), 1)
    }
}
```

Add to `Model/TimeRange.swift`, after `dateRange(endingOn:calendar:)`:

```swift
    /// The equally long range that ends where `dateRange` starts.
    public func previousDateRange(endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar) -> Range<Date> {
        let current = dateRange(endingOn: anchor, calendar: calendar)
        let start = calendar.date(byAdding: .day, value: -dayCount, to: current.lowerBound) ?? current.lowerBound
        return start..<current.lowerBound
    }
```

Where a definition line exceeds 132 characters, wrap its parameters onto their own lines (AGENTS.md allows this).

- [ ] **Step 5: Run, lint, commit**

Run: `swift test --package-path DashboardKit --filter TransactionInsightsTests` → PASS (12 tests, 15 cases). Then the full suite. Then SwiftLint → 0 violations.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add transaction insights for the new dashboard sections

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Live feed, setting, environment, HUD, and menu

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Live/LiveArrival.swift`, `DashboardKit/Sources/DashboardKit/Live/LiveFeed.swift`, `DashboardKit/Sources/DashboardKit/Shell/EnvironmentValues+LiveUpdates.swift`
- Modify:
  - `Settings/LaunchArguments.swift` and `Settings/DemoSettings.swift`
  - `Shell/SettingsMenu.swift` and `Shell/DemoShell.swift`
  - `Diagnostics/FrameMeterView.swift`
  - `Model/DashboardSection.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/LiveFeedTests.swift`, plus additions to `IntensityTests.swift` and `DemoSettingsTests.swift`

**Interfaces:**
- `struct LiveArrival: Identifiable, Hashable, Sendable { id: Int; merchant: String; amount: Decimal; value: Double }`
- `enum LiveFeed { static func arrival(at:seed:) -> LiveArrival; static func next(after:limit:) -> [LiveArrival] }`
- `LaunchArguments.liveUpdatesEnabled(from:) -> Bool`
- `DemoSettings.liveUpdatesEnabled: Bool`
- `EnvironmentValues.liveUpdatesEnabled` (`@Entry`, default `true`)
- `FrameMeterView(variant:intensity:liveUpdates:)`
- `DashboardSection` gains `live, cashFlow, topMerchants, largestTransactions, weekdayPattern, spendingCalendar, categoryTrends, versusPrevious, upcomingBills, subscriptions, savingsGoal`

- [ ] **Step 1: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/LiveFeedTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct LiveFeedTests {
    @Test func arrivalsAreDeterministicPerTickAndWithinRange() {
        #expect(LiveFeed.arrival(at: 5) == LiveFeed.arrival(at: 5))
        let arrivals = (0..<200).map { LiveFeed.arrival(at: $0) }
        #expect(Set(arrivals.map(\.merchant)).count > 1)
        #expect(arrivals.allSatisfy { $0.amount >= Decimal(99) / 100 && $0.amount <= 25 })
        #expect(arrivals.map(\.id) == Array(0..<200))
    }

    @Test func nextAppendsTheFollowingTickAndKeepsTheLastThirty() {
        var arrivals = LiveFeed.next(after: [])
        #expect(arrivals.map(\.id) == [0])
        for _ in 0..<34 {
            arrivals = LiveFeed.next(after: arrivals)
        }
        #expect(arrivals.count == 30)
        #expect(arrivals.map(\.id) == Array(5...34))
    }
}
```

Append inside `IntensityTests`:

```swift
    @Test func liveUpdatesFollowTheLaunchArgument() {
        #expect(!LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "off"]))
        #expect(!LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "OFF"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "on"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["App"]))
    }
```

Append inside `DemoSettingsTests`:

```swift
    @Test func liveUpdatesDefaultToOnAndReadTheLaunchArgument() {
        #expect(DemoSettings(arguments: ["App"]).liveUpdatesEnabled)
        #expect(!DemoSettings(arguments: ["App", "-liveUpdates", "off"]).liveUpdatesEnabled)
    }
```

Run: `swift test --package-path DashboardKit --filter "LiveFeedTests|IntensityTests|DemoSettingsTests"`
Expected: build failure: `cannot find 'LiveFeed' in scope` and `has no member 'liveUpdatesEnabled'`.

- [ ] **Step 2: Implement the feed and the setting**

`Live/LiveArrival.swift`:

```swift
import Foundation

/// One simulated pending charge arriving in the live-activity card.
public struct LiveArrival: Identifiable, Hashable, Sendable {
    /// The tick that produced it; increases by one per arrival.
    public let id: Int
    public let merchant: String
    /// Positive amount charged.
    public let amount: Decimal

    /// `amount` as a `Double`, the type Swift Charts plots.
    public var value: Double { NSDecimalNumber(decimal: amount).doubleValue }
}
```

`Live/LiveFeed.swift`:

```swift
import Foundation

/// A deterministic stream of small pending charges, standing in for a live data feed.
public enum LiveFeed {
    static let merchants = [
        "Corner Coffee", "Metro Tap", "Snack Bar", "Bakery", "Bike Share", "Tea House", "Newsstand", "Juice Stand"
    ]

    /// The arrival for `tick`. The same tick always gives the same arrival.
    public static func arrival(at tick: Int, seed: UInt64 = SampleDataGenerator.defaultSeed) -> LiveArrival {
        var generator = SeededRandomGenerator(seed: seed &+ UInt64(truncatingIfNeeded: tick) &* 0x9E37_79B9)
        let merchant = merchants[Int.random(in: 0..<merchants.count, using: &generator)]
        let cents = Int.random(in: 99...2_500, using: &generator)
        return LiveArrival(id: tick, merchant: merchant, amount: Decimal(cents) / 100)
    }

    /// `arrivals` plus the next arrival, keeping only the last `limit`.
    public static func next(after arrivals: [LiveArrival], limit: Int = 30) -> [LiveArrival] {
        let tick = (arrivals.last?.id ?? -1) + 1
        return Array((arrivals + [arrival(at: tick)]).suffix(limit))
    }
}
```

In `Settings/LaunchArguments.swift`, add:

```swift
    /// `-liveUpdates off` (any case) turns the live feed off; it's on otherwise.
    public static func liveUpdatesEnabled(from arguments: [String]) -> Bool {
        guard let flagIndex = arguments.firstIndex(of: "-liveUpdates") else { return true }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return true }
        return arguments[valueIndex].lowercased() != "off"
    }
```

In `Settings/DemoSettings.swift`:
- Add `public var liveUpdatesEnabled: Bool` after `showsEvaluationBadges`.
- In `init(arguments:)`, add `liveUpdatesEnabled = LaunchArguments.liveUpdatesEnabled(from: arguments)`.

- [ ] **Step 3: Run the tests**

Run: `swift test --package-path DashboardKit --filter "LiveFeedTests|IntensityTests|DemoSettingsTests"` → PASS.

- [ ] **Step 4: Wire the environment, the HUD, the menu, and the section cases**

`Shell/EnvironmentValues+LiveUpdates.swift`:

```swift
import SwiftUI

extension EnvironmentValues {
    /// Whether the dashboard's live-activity feed ticks. On by default; `-liveUpdates off` or the settings menu turns it off.
    @Entry public var liveUpdatesEnabled = true
}
```

`Model/DashboardSection.swift`: replace the `case` line with:

```swift
    case live, summary, timeRange, budget, chart, categories, transactions
    case cashFlow, topMerchants, largestTransactions, weekdayPattern, spendingCalendar, categoryTrends, versusPrevious
    case upcomingBills, subscriptions, savingsGoal
```

In `Shell/SettingsMenu.swift`, after the "Show re-evaluations" toggle, add:

```swift
            Toggle("Live updates", isOn: $settings.liveUpdatesEnabled)
```

In `Diagnostics/FrameMeterView.swift`:
- Add `let liveUpdates: Bool` after `let intensity: Intensity`.
- After `Text(intensity.title)` in the first `HStack`, add:

```swift
                    if liveUpdates {
                        Text("Live on")
                    } else {
                        Text("Live off")
                    }
```

In `Shell/DemoShell.swift`:
- Change `FrameMeterView(variant: variant, intensity: settings.intensity)` to `FrameMeterView(variant: variant, intensity: settings.intensity, liveUpdates: settings.liveUpdatesEnabled)`.
- After `.environment(\.evaluationBadgeResetGeneration, settings.badgeResetGeneration)`, add `.environment(\.liveUpdatesEnabled, settings.liveUpdatesEnabled)`.

- [ ] **Step 5: Build, test, lint, commit**

Run: `swift build --package-path DashboardKit` → `Build complete!`. `swift test --package-path DashboardKit` → all pass. SwiftLint → 0 violations. The apps don't compile against the new section cases yet only if a `switch` over `DashboardSection` exists. None does, so both apps should still build: run the two-app Debug build to confirm.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add live feed, live-updates setting, and new section identifiers

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: The Computed app's 11 new sections and live loop

Invoke the `swiftui-specialist` skill before writing these views (AGENTS.md requirement).

**Files:** Modify `ComputedDashboard/DashboardView.swift`.

**Interfaces:**
- Consumes (Tasks 2–3): the `TransactionMath` insights and value types, `TimeRange.previousDateRange()`, `LiveArrival`, `LiveFeed.next(after:)`, `EnvironmentValues.liveUpdatesEnabled`, and the new `DashboardSection` cases.
- Produces: 11 new marker blocks named as in Global Constraints. Their bodies reference only `transactions`, `timeRange`, and `liveArrivals`.

- [ ] **Step 1: Add the state, environment, body order, and live loop**

In `ComputedDashboard/DashboardView.swift`:
- After `@State private var timeRange = TimeRange.month`, add:

```swift
    @State private var liveArrivals: [LiveArrival] = []
    @Environment(\.liveUpdatesEnabled) private var liveUpdatesEnabled
```

- Replace the `var body` with:

```swift
    var body: some View {
        ScrollView {
            VStack {
                liveActivity
                accountSummary
                timeRangePicker
                budgetCard
                spendingChart
                categoryBreakdown
                recentTransactions
                cashFlow
                topMerchants
                largestExpenses
                weekdayPattern
                spendingCalendar
                categoryTrends
                versusPrevious
                upcomingBills
                subscriptions
                savingsGoal
            }
            .padding()
        }
        .task(id: liveUpdatesEnabled) {
            // Identical in both apps: ten arrivals a second from the dashboard's own state.
            guard liveUpdatesEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                liveArrivals = LiveFeed.next(after: liveArrivals)
            }
        }
    }
```

- [ ] **Step 2: Add the 11 sections**

Append these computed properties inside `DashboardView`, after `recentTransactions`. Keep each marker line exactly as written.

```swift
    @ViewBuilder
    private var liveActivity: some View {
        // BEGIN SECTION BODY: live
        let evaluationCount = EvaluationCounter.shared.record(.live)
        let shownTotal = liveArrivals.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            HStack {
                Label("Live activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                Text("\(liveArrivals.count) recent")
                    .foregroundStyle(.secondary)
            }
            if let latest = liveArrivals.last {
                LabeledContent(latest.merchant) {
                    Text(latest.amount, format: .currency(code: "USD"))
                }
            } else {
                Text("Waiting for activity…")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Pending (shown)") {
                Text(shownTotal, format: .currency(code: "USD"))
            }
            Chart(liveArrivals) { arrival in
                LineMark(x: .value("Arrival", arrival.id), y: .value("Amount", arrival.value))
            }
            .chartXAxis(.hidden)
            .frame(minHeight: 60)
            EvaluationBadge(section: .live, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: live
    }

    @ViewBuilder
    private var cashFlow: some View {
        // BEGIN SECTION BODY: cashFlow
        let evaluationCount = EvaluationCounter.shared.record(.cashFlow)
        let balances = TransactionMath.dailyBalances(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Cash flow")
                .font(.headline)
            Chart(balances) { point in
                LineMark(x: .value("Day", point.day, unit: .day), y: .value("Net", point.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .cashFlow, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: cashFlow
    }

    @ViewBuilder
    private var topMerchants: some View {
        // BEGIN SECTION BODY: topMerchants
        let evaluationCount = EvaluationCounter.shared.record(.topMerchants)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let merchants = TransactionMath.topMerchants(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Top merchants")
                .font(.headline)
            Chart(merchants) { merchant in
                BarMark(x: .value("Spent", merchant.amount), y: .value("Merchant", merchant.merchant))
            }
            .frame(minHeight: 240)
            EvaluationBadge(section: .topMerchants, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: topMerchants
    }

    @ViewBuilder
    private var largestExpenses: some View {
        // BEGIN SECTION BODY: largestTransactions
        let evaluationCount = EvaluationCounter.shared.record(.largestTransactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let largest = TransactionMath.largestExpenses(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Largest expenses")
                .font(.headline)
            ForEach(largest) { transaction in
                LabeledContent {
                    Text(transaction.amount, format: .currency(code: "USD"))
                } label: {
                    Text(transaction.merchant)
                    Text(transaction.date, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .largestTransactions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: largestTransactions
    }

    @ViewBuilder
    private var weekdayPattern: some View {
        // BEGIN SECTION BODY: weekdayPattern
        let evaluationCount = EvaluationCounter.shared.record(.weekdayPattern)
        let averages = TransactionMath.weekdayAverages(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let symbols = DemoClock.calendar.shortWeekdaySymbols
        VStack(alignment: .leading) {
            Text("By weekday")
                .font(.headline)
            Chart(averages) { average in
                BarMark(x: .value("Weekday", symbols[average.weekday - 1]), y: .value("Average", average.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .weekdayPattern, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: weekdayPattern
    }

    @ViewBuilder
    private var spendingCalendar: some View {
        // BEGIN SECTION BODY: spendingCalendar
        let evaluationCount = EvaluationCounter.shared.record(.spendingCalendar)
        let days = TransactionMath.dailySpend(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let busiest = days.map(\.amount).max() ?? 0
        VStack(alignment: .leading) {
            Text("Spending calendar")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red.opacity(busiest > 0 ? day.amount / busiest : 0))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(Text(day.day, format: .dateTime.month().day()))
                        .accessibilityValue(Text(day.value, format: .currency(code: "USD")))
                }
            }
            EvaluationBadge(section: .spendingCalendar, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: spendingCalendar
    }

    @ViewBuilder
    private var categoryTrends: some View {
        // BEGIN SECTION BODY: categoryTrends
        let evaluationCount = EvaluationCounter.shared.record(.categoryTrends)
        let series = TransactionMath.categorySeries(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Category trends")
                .font(.headline)
            ForEach(series) { categorySeries in
                HStack {
                    Label {
                        Text(categorySeries.category.title)
                    } icon: {
                        Image(systemName: categorySeries.category.systemImage)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Chart(categorySeries.points) { point in
                        LineMark(x: .value("Day", point.day, unit: .day), y: .value("Spent", point.amount))
                            .foregroundStyle(categorySeries.category.color)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(minHeight: 36)
                }
            }
            EvaluationBadge(section: .categoryTrends, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categoryTrends
    }

    @ViewBuilder
    private var versusPrevious: some View {
        // BEGIN SECTION BODY: versusPrevious
        let evaluationCount = EvaluationCounter.shared.record(.versusPrevious)
        let current = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let previous = TransactionMath.transactions(transactions, in: timeRange.previousDateRange())
        let changes = TransactionMath.categoryComparison(current: current, previous: previous)
        VStack(alignment: .leading) {
            Text("Versus previous period")
                .font(.headline)
            ForEach(changes) { change in
                let before = Text(change.previous, format: .currency(code: "USD"))
                let after = Text(change.current, format: .currency(code: "USD"))
                LabeledContent {
                    Text(change.difference, format: .currency(code: "USD").sign(strategy: .always()))
                } label: {
                    Text(change.category.title)
                    Text("\(before) → \(after)")
                }
            }
            EvaluationBadge(section: .versusPrevious, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: versusPrevious
    }

    @ViewBuilder
    private var upcomingBills: some View {
        // BEGIN SECTION BODY: upcomingBills
        let evaluationCount = EvaluationCounter.shared.record(.upcomingBills)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let bills = TransactionMath.upcomingBills(charges, after: DemoClock.anchorDate, within: 30, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Upcoming bills")
                .font(.headline)
            if bills.isEmpty {
                Text("No bills due in the next 30 days")
                    .foregroundStyle(.secondary)
            }
            ForEach(bills) { bill in
                LabeledContent {
                    Text(bill.amount, format: .currency(code: "USD"))
                } label: {
                    Text(bill.merchant)
                    Text(bill.nextDate, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .upcomingBills, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: upcomingBills
    }

    @ViewBuilder
    private var subscriptions: some View {
        // BEGIN SECTION BODY: subscriptions
        let evaluationCount = EvaluationCounter.shared.record(.subscriptions)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let monthlyTotal = charges.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            Text("Subscriptions")
                .font(.headline)
            ForEach(charges) { charge in
                LabeledContent(charge.merchant) {
                    Text(charge.amount, format: .currency(code: "USD"))
                }
            }
            LabeledContent("Monthly total") {
                Text(monthlyTotal, format: .currency(code: "USD"))
                    .bold()
            }
            EvaluationBadge(section: .subscriptions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: subscriptions
    }

    @ViewBuilder
    private var savingsGoal: some View {
        // BEGIN SECTION BODY: savingsGoal
        let evaluationCount = EvaluationCounter.shared.record(.savingsGoal)
        let year = TransactionMath.transactions(transactions, in: TimeRange.year.dateRange())
        let net = TransactionMath.net(of: year)
        let goal = TransactionMath.income(of: year) / 5
        VStack(alignment: .leading) {
            Text("Savings goal")
                .font(.headline)
            Gauge(value: TransactionMath.savingsProgress(net: net, goal: goal)) {
                Text("Saved this year")
            } currentValueLabel: {
                Text(net, format: .currency(code: "USD"))
            }
            Text("Goal: \(goal, format: .currency(code: "USD"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(section: .savingsGoal, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: savingsGoal
    }
```

- [ ] **Step 3: Build and lint**

Run: `xcodebuild -project ComputedPropertiesView.xcodeproj -scheme ComputedDashboard -configuration Debug -destination "id=B9BB0E3F-E390-472F-AD17-952DA5298A94" -derivedDataPath build/DerivedData build -quiet` → success, no warnings.
Run SwiftLint. If `type_body_length` fires on `DashboardView`, add these two lines directly above `struct DashboardView: View {` (only in this file):

```swift
// Seventeen computed-property sections are the anti-pattern under test, so this type is long on purpose.
// swiftlint:disable:next type_body_length
```

If any line exceeds 132 characters, wrap the call's arguments inside the marker block. Task 5 copies the blocks, so parity holds either way.

- [ ] **Step 4: Commit**

```bash
git add ComputedDashboard/DashboardView.swift
git commit -F - <<'EOF'
feat: add live feed and ten more computed-property sections to the Computed dashboard

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: The Structs app's 11 new sections, parent, and parity

**Files:**
- Create (generated): 11 files in `StructDashboard/Sections/`
- Modify: `StructDashboard/DashboardView.swift`, `Scripts/check-section-parity.sh`

- [ ] **Step 1: Extend the parity script and watch it fail**

In `Scripts/check-section-parity.sh`, replace the `sections=(…)` line with:

```bash
sections=(live summary timeRange budget chart categories transactions cashFlow topMerchants largestTransactions weekdayPattern spendingCalendar categoryTrends versusPrevious upcomingBills subscriptions savingsGoal)
```

Run: `Scripts/check-section-parity.sh` → FAIL. The six existing sections pass, and the 11 new ones report `marker block missing` (structs: 0 chars).

- [ ] **Step 2: Generate the 11 section structs from the Computed app's blocks**

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
body() { sed -n "/BEGIN SECTION BODY: $1\$/,/END SECTION BODY: $1\$/p" ComputedDashboard/DashboardView.swift; }
footer() { printf '    }\n}\n'; }
make_section() {  # $1 marker, $2 struct name, $3 imports (space-separated), $4 doc line, $5 stored properties
  {
    for module in $3; do echo "import $module"; done
    echo
    echo "/// $4"
    echo "struct $2: View {"
    printf '%b\n' "$5"
    echo
    echo "    var body: some View {"
    body "$1"
    footer
  } > "StructDashboard/Sections/$2.swift"
}
TT='    let transactions: [AccountTransaction]\n    let timeRange: TimeRange'
T='    let transactions: [AccountTransaction]'
make_section live LiveActivitySection "Charts DashboardKit SwiftUI" "The live feed: the only section that reads the dashboard's ten-per-second state." '    let liveArrivals: [LiveArrival]'
make_section cashFlow CashFlowSection "Charts DashboardKit SwiftUI" "Running net balance per day across the range." "$TT"
make_section topMerchants TopMerchantsSection "Charts DashboardKit SwiftUI" "The ten merchants with the most spending in the range." "$TT"
make_section largestTransactions LargestExpensesSection "DashboardKit SwiftUI" "The ten largest expenses in the range." "$TT"
make_section weekdayPattern WeekdayPatternSection "Charts DashboardKit SwiftUI" "Average daily spending per weekday in the range." "$TT"
make_section spendingCalendar SpendingCalendarSection "DashboardKit SwiftUI" "A heatmap of daily spending across the range." "$TT"
make_section categoryTrends CategoryTrendsSection "Charts DashboardKit SwiftUI" "One sparkline per spending category across the range." "$TT"
make_section versusPrevious VersusPreviousSection "DashboardKit SwiftUI" "Spending per category versus the equally long period before." "$TT"
make_section upcomingBills UpcomingBillsSection "DashboardKit SwiftUI" "Recurring charges due in the next 30 days (whole-year data; ignores the range)." "$T"
make_section subscriptions SubscriptionsSection "DashboardKit SwiftUI" "Recurring monthly charges and their total (whole-year data; ignores the range)." "$T"
make_section savingsGoal SavingsGoalSection "DashboardKit SwiftUI" "Year-to-date savings against a goal of 20% of income (ignores the range)." "$T"
ls StructDashboard/Sections | wc -l   # expect 17
```

- [ ] **Step 3: Update the Structs parent**

Replace `StructDashboard/DashboardView.swift` with:

```swift
import DashboardKit
import SwiftUI

/// The same dashboard as the Computed app, but each section is its own `View` struct with narrow inputs.
///
/// This body only forwards inputs. It never filters or aggregates, so a slider tick or a live-feed tick changes only
/// the one section that reads that value, and SwiftUI skips the other sixteen section bodies.
struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    @State private var budget = 2_000.0
    @State private var hideBalances = false
    @State private var showPendingOnly = false
    @State private var timeRange = TimeRange.month
    @State private var liveArrivals: [LiveArrival] = []
    @Environment(\.liveUpdatesEnabled) private var liveUpdatesEnabled

    var body: some View {
        ScrollView {
            VStack {
                LiveActivitySection(liveArrivals: liveArrivals)
                AccountSummarySection(transactions: transactions, timeRange: timeRange, hideBalances: $hideBalances)
                TimeRangeSection(timeRange: $timeRange)
                BudgetSection(transactions: transactions, timeRange: timeRange, budget: $budget)
                SpendingChartSection(transactions: transactions, timeRange: timeRange)
                CategoryBreakdownSection(transactions: transactions, timeRange: timeRange)
                RecentTransactionsSection(
                    transactions: transactions, timeRange: timeRange, rowLimit: rowLimit, showPendingOnly: $showPendingOnly
                )
                CashFlowSection(transactions: transactions, timeRange: timeRange)
                TopMerchantsSection(transactions: transactions, timeRange: timeRange)
                LargestExpensesSection(transactions: transactions, timeRange: timeRange)
                WeekdayPatternSection(transactions: transactions, timeRange: timeRange)
                SpendingCalendarSection(transactions: transactions, timeRange: timeRange)
                CategoryTrendsSection(transactions: transactions, timeRange: timeRange)
                VersusPreviousSection(transactions: transactions, timeRange: timeRange)
                UpcomingBillsSection(transactions: transactions)
                SubscriptionsSection(transactions: transactions)
                SavingsGoalSection(transactions: transactions)
            }
            .padding()
        }
        .task(id: liveUpdatesEnabled) {
            // Identical in both apps: ten arrivals a second from the dashboard's own state.
            guard liveUpdatesEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                liveArrivals = LiveFeed.next(after: liveArrivals)
            }
        }
    }
}
```

- [ ] **Step 4: Parity, build, lint, commit**

Run: `Scripts/check-section-parity.sh` → 17 `✓`.
Build both apps in Debug and Release (four `xcodebuild … -configuration <cfg> … build -quiet` runs) → all succeed.
SwiftLint → 0 violations.

```bash
git add Scripts StructDashboard
git commit -F - <<'EOF'
feat: add live feed and ten more section structs to the Structs dashboard

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Verification in the simulator

**Files:** none (results go to the ledger, not the Journal).

- [ ] **Step 1: Install Release builds** of both apps on `$SIM`.

- [ ] **Step 2: Idle badge check (Review Focus 5).** For each app, launch with `-intensity realistic -showEvaluationBadges`, open the dashboard, and use a device-interaction subagent to read all 17 badges by their accessibility labels, wait 5 s (`w 5`) without touching anything, and read them again.
Expected: in Computed, every badge rose by roughly the same number of ticks. In Structs, only `live` rose.

- [ ] **Step 3: Stop conditions (Review Focus 1 and 2).**
  - In the Computed app with badges on, tap **Back**, wait 3 s, and reopen. Check that the badges show no growth while the start screen was showing. The FPS on the start screen should be normal.
  - Turn **Live updates** off in the gear menu, wait 3 s, and read the badges twice, 2 s apart. They must not change, and the live card must be frozen.

- [ ] **Step 4: Scrolling feel and operability (Review Focus 3).**
  - For each app, launch with `-intensity realistic` (badges off, Live on), open the dashboard, reset the HUD, scroll down and up for about 10 s with `t X Y f X Y2 0.4` swipes, and read FPS, Hitches, and Worst.
  - Repeat at `-intensity heavy`. In the Computed app at Heavy, confirm Back and the gear menu still respond.
  - Record every reading in the ledger.

- [ ] **Step 5: Tap timings with Live off.** Launch each app with `-intensity heavy -liveUpdates off`, open the dashboard, and take eye ×3 readings (`t X Y w 1.5`). They should be in the same character as before: Computed slower than Structs.

---

### Task 7: Docs and final checks

**Files:** Modify `CLAUDE.md`, `Captures/README.md`, `Captures/CaptureNotes.md`, `Journal.md`.

- [ ] **Step 1: `CLAUDE.md`**
  - In **What this is**, replace "six sections" with "seventeen sections".
  - Under **Architecture**, add: "The dashboard has 17 sections (order in `DashboardSection`). The first, **Live activity**, reads `liveArrivals`, which a `.task` in each `DashboardView` updates ten times a second when **Live updates** is on (`-liveUpdates off` or the settings menu turns it off; the HUD shows Live on/off)."
  - Under **Launch arguments**, add `-liveUpdates off`.

- [ ] **Step 2: `Captures/README.md` and `CaptureNotes.md`**
  - In README "Before you start", add a step: "Decide **Live updates**: on to film the continuous stutter while scrolling (the default), off for tap timings and Instruments runs you want free of the feed. The HUD shows Live on/off."
  - In "Gesture script", add as step 0: "With Live on and no touch, scroll the dashboard top to bottom and back for ~10 s."
  - In CaptureNotes, add `- **Live updates:** on / off` under Intensity.

- [ ] **Step 3: `Journal.md` (no measured numbers)**
  - Append under **The Journey** `### 2026-09-27: Making the lag felt`.
  - Explain why numbers weren't enough.
  - Explain the two levers (seventeen sections; a live feed from the dashboard's own state).
  - Explain why the live feed is the fair, realistic way to show the anti-pattern hurting with no interaction at all.
  - Cover the monthly-charge and paycheck data changes.
  - Add one Engineer's Wisdom bullet: "Cost scales with what re-runs, not what changed."

- [ ] **Step 4: Final checks and commit**

`swift test --package-path DashboardKit` → all pass. SwiftLint → 0 violations. `Scripts/check-section-parity.sh` → 17 `✓`. Both apps build in Debug and Release.

```bash
git add CLAUDE.md Captures Journal.md
git commit -F - <<'EOF'
docs: document the extra sections and the live feed

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```
