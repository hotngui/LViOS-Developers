# Computed-Property Views vs. View Structs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two iOS 27 apps that are identical except that one builds its dashboard sections as `some View` computed properties and the other as separate `View` structs, plus the shared tooling to show and measure the hitch difference.

**Architecture:** A local Swift package, `DashboardKit`, holds everything both apps share: models, seeded sample data, the derived-data math the section bodies call, settings, diagnostics (frame-meter HUD, "body runs" badges), and a shared root view (`DemoShell`). One Xcode project has two thin app targets that differ only in `DashboardView`. Section bodies are copied mechanically from the Computed app into the Structs app between marker comments, and a parity script checks that they stay identical.

**Tech Stack:** Swift 6.4 toolchain (Swift 6 language mode), SwiftUI (iOS 27 SDK), Swift Charts, Observation, Swift Testing, Xcode 27.1, SwiftLint 0.65.1.

**Spec:** `docs/superpowers/specs/2026-09-26-computed-vs-struct-views-design.md`

## Global Constraints

- iOS deployment target **27.0**. Swift 6 language mode. Strict Concurrency Checking **Complete**. Approachable Concurrency **Yes**.
- Bundle IDs: `com.hotngui.ComputedDashboard` (display name **Computed**) and `com.hotngui.StructDashboard` (display name **Structs**). iPhone only.
- No third-party dependencies. Swift Charts is allowed.
- `@MainActor` on every `@Observable` class. Never `ObservableObject`.
- Swift Testing only. No UI tests.
- One type per Swift file. No force unwraps or `try!`. No hard-coded padding or stack spacing. No fixed font sizes. Use `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Button("Title", systemImage:)`, `NavigationStack`.
- Function definitions stay on one line unless the whole definition exceeds 132 characters. SwiftLint's line limit is 132.
- Before every commit that touches Swift: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` reports 0 violations.
- Section bodies must be textually identical between the two apps (enforced by `Scripts/check-section-parity.sh` from Task 9 on).
- The Structs app's `DashboardView.body` only forwards inputs. It never filters or aggregates.
- Fixed demo clock: anchor date **2026-09-30 00:00 GMT** (`Date(timeIntervalSince1970: 1_790_726_400)`), Gregorian calendar pinned to GMT.
- Intensity levels (transactions per year / rows in the Recent list): Light 1,000/25 · Realistic (default) 3,000/50 · Heavy 10,000/150 · Severe 30,000/300 · Extreme 100,000/600.
- Captures use Release builds.
- English only. Package strings are plain literals (no `bundle:`).
- Git: local commits only, **never push**. End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `SessionLog.md` is maintained by the main session. Task implementers don't edit it.
- Repo root (all paths below are relative to it): `/Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView`
- Simulator for builds and checks: iPhone 18 Pro, iOS 27.0, id `B9BB0E3F-E390-472F-AD17-952DA5298A94` (referred to as `$SIM`).

### Deliberate refinements of the spec (already decided; don't revisit)

- The transaction type is **`AccountTransaction`**, not `Transaction`. `SwiftUI.Transaction` exists, so `Transaction` would be ambiguous in every view file.
- `TransactionCategory` has **8 spending categories plus `income`** (9 cases). The chart and breakdown use the 8 spending categories.
- `EvaluationCounter` is a `@MainActor` singleton (`EvaluationCounter.shared`) instead of an environment value, so reading it can never cause invalidation. Only the Bool badge-visibility flag goes through the environment.
- The budget slider's upper bound is `TransactionMath.budgetCeiling(forSpent:)` (2× the range's spending, minimum $100) instead of a fixed $20,000. Spending grows with intensity, so a fixed range would leave the gauge pinned at 100% above Realistic.
- `-showEvaluationBadges` launch argument added, so badge videos and automated checks don't need menu taps.
- The package also declares macOS 27, only so `swift test` runs on the Mac. The apps are iOS-only.
- The Settings menu gains **"Simulate a 100 ms stall"**, which proves the HUD detects a known hitch.

## Review Focus

Failure modes the spec implies that are most likely to bite a real user. Each one has a pinned test in the task that owns the code.

1. **Changing intensity again before the previous level finishes generating**, including switching back to the level already loaded. The last choice must win and the loading indicator must clear. → Task 4, `TransactionStoreTests` (two tests).
2. **A multi-second gap between HUD frames** (app backgrounded, HUD off screen) must count as a pause, not a hitch or the worst frame. → Task 5, `aPauseLongerThanOneSecondIsNotAHitch`.
3. **The HUD body re-evaluated off-cycle** with the same frame timestamp (or an earlier one) must be ignored so the expected-interval estimate doesn't collapse. → Task 5, `repeatedOrEarlierTimestampsAreIgnored`.
4. **A time range with no spending** (only income, or nothing) must produce empty category totals and zero expenses, never NaN shares. → Task 3, `categoryTotalsForARangeWithNoSpendingAreEmpty`.
5. **Budget slider at $0** must keep the gauge fraction within 0…1 without dividing by zero. → Task 3, `budgetUsageStaysBetweenZeroAndOne`.

---

### Task 1: Package skeleton, core models, and project docs

**Files:**
- Create: `DashboardKit/Package.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/DashboardSection.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/DemoClock.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/TransactionCategory.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/TransactionCategory+Color.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/AccountTransaction.swift`
- Create: `DashboardKit/Sources/DashboardKit/Model/TimeRange.swift`
- Create: `DashboardKit/Tests/TestList.md`
- Create: `DashboardKit/Tests/DashboardKitTests/Fixture.swift`
- Create: `DashboardKit/Tests/DashboardKitTests/TimeRangeTests.swift`
- Create: `.swiftlint.yml`, `CLAUDE.md`, `Journal.md`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum DashboardSection: String, CaseIterable, Sendable { summary, timeRange, budget, chart, categories, transactions }`
  - `enum DemoClock { static let calendar: Calendar; static let anchorDate: Date }`
  - `enum TransactionCategory: Int, CaseIterable, Identifiable, Comparable, Sendable` with cases `income, groceries, dining, transport, home, utilities, entertainment, shopping, health`, plus `static let spending: [TransactionCategory]`, `title: LocalizedStringResource`, `name: String`, `systemImage: String`, `color: Color`
  - `struct AccountTransaction: Identifiable, Hashable, Sendable { id: Int; date: Date; merchant: String; category: TransactionCategory; amount: Decimal; isPending: Bool; isIncome: Bool }`. Its memberwise init is internal.
  - `enum TimeRange: String, CaseIterable, Identifiable, Sendable { week, month, quarter, year }` with `title`, `dayCount`, `func dateRange(endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar) -> Range<Date>`
  - Test helpers: `Fixture.date(dayOffset:hour:minute:)`, `Fixture.transaction(_:_:on:isPending:)`, `Fixture.ymd(_:)`

- [ ] **Step 1: Create the package manifest and the first source file**

`DashboardKit/Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

// Approachable Concurrency, matching the app targets' "Approachable Concurrency = Yes" build setting.
let approachableConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
    name: "DashboardKit",
    // macOS is listed only so `swift test` can run the unit tests on the Mac without a simulator.
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "DashboardKit", targets: ["DashboardKit"])
    ],
    targets: [
        .target(name: "DashboardKit", swiftSettings: approachableConcurrency),
        .testTarget(name: "DashboardKitTests", dependencies: ["DashboardKit"], swiftSettings: approachableConcurrency)
    ]
)
```

`DashboardKit/Sources/DashboardKit/Model/DashboardSection.swift`:

```swift
/// The six dashboard sections, used to label each section's "body runs" count.
public enum DashboardSection: String, CaseIterable, Sendable {
    case summary, timeRange, budget, chart, categories, transactions
}
```

- [ ] **Step 2: Write the test list (TDD requirement from AGENTS.md)**

`DashboardKit/Tests/TestList.md`:

```markdown
# DashboardKit Test List

Written before the tests, per AGENTS.md. Each line becomes one Swift Testing test (or one argument set).

## TimeRange and DemoClock (TimeRangeTests)
- The anchor date is 2026-09-30 in the demo calendar.
- Week, Month, Quarter, and Year start 7, 30, 90, and 365 days before the end of the anchor day, and all end at 2026-10-01 00:00 GMT.
- There are 8 spending categories, and income is not one of them.

## SeededRandomGenerator (SeededRandomGeneratorTests)
- Seed 0 produces the published SplitMix64 reference values.
- The same seed produces the same sequence.
- Different seeds produce different sequences.

## SampleDataGenerator (SampleDataGeneratorTests)
- The transaction count matches the requested count (and 0 gives an empty array).
- The async API returns the intensity's count.
- Output is identical across two runs with the same seed; a different seed gives different output.
- Every date falls within the year before the anchor date.
- All 8 spending categories appear.
- Income amounts are positive and spending amounts are negative.
- At least one transaction is pending.
- Results are newest first with ids 0..<count.

## TransactionMath (TransactionMathTests)
- Range filtering includes transactions on both boundary days and excludes those outside.
- Income, expense, and net sums are correct.
- The spending total for the budget gauge counts only expenses inside the range.
- Category totals are sorted largest first (ties by category order), and shares add up to 1.
- A range with no spending gives empty category totals and zero expenses. (Review Focus 4)
- Daily totals bin by day and category, skipping income.
- The pending-only filter returns only pending transactions.
- Newest-first sorts descending and honors the limit.
- Budget usage stays within 0…1, including a $0 budget. (Review Focus 5)
- The budget ceiling is 2× spending, with a $100 floor.

## Intensity and LaunchArguments (IntensityTests)
- `-intensity heavy` parses regardless of case.
- Missing, dangling, or unknown values fall back to Realistic.
- Each level's transaction count and row limit are strictly larger than the previous level's.
- `-showEvaluationBadges` turns badges on; its absence leaves them off.

## DemoSettings and TransactionStore (DemoSettingsTests, TransactionStoreTests)
- Settings read the intensity and badge flag from launch arguments; badges default to off.
- Loading generates the intensity's transaction count and clears the loading flag.
- The latest request wins when an earlier one finishes later. (Review Focus 1)
- Switching back to the loaded level discards the in-flight load. (Review Focus 1)

## FrameStats (FrameStatsTests)
- Steady 120 Hz frames produce no hitches, and FPS is about 120.
- One 25 ms frame among 120 Hz frames produces one hitch, and the worst frame is 25 ms.
- At 60 Hz a 25 ms frame is not a hitch but a 40 ms frame is.
- A pause longer than one second is not a hitch or the worst frame. (Review Focus 2)
- Repeated or earlier timestamps are ignored. (Review Focus 3)
- Reset clears everything.
- `Duration.inMilliseconds` converts correctly.

## EvaluationCounter and diagnostics defaults (EvaluationCounterTests, DiagnosticsDefaultsTests)
- `record` returns the incremented count.
- Counts for different sections are independent.
- Reset clears all counts.
- The badge environment flag defaults to off.
- The device model identifier is not empty.
```

- [ ] **Step 3: Write the test fixture and the failing TimeRange tests**

`DashboardKit/Tests/DashboardKitTests/Fixture.swift`:

```swift
import Foundation
@testable import DashboardKit

/// Builders for hand-made test data, anchored to the demo clock so dates are easy to reason about.
enum Fixture {
    static let secondsPerDay: TimeInterval = 86_400

    /// A date `dayOffset` days from the anchor day (2026-09-30, GMT) at the given time of day.
    static func date(dayOffset: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let seconds = TimeInterval(dayOffset) * secondsPerDay + TimeInterval(hour * 3_600 + minute * 60)
        return DemoClock.anchorDate.addingTimeInterval(seconds)
    }

    static func transaction(
        _ amount: Decimal, _ category: TransactionCategory, on date: Date, isPending: Bool = false
    ) -> AccountTransaction {
        AccountTransaction(id: 0, date: date, merchant: "Test Merchant", category: category, amount: amount, isPending: isPending)
    }

    /// The year, month, and day of `date` in the demo calendar.
    static func ymd(_ date: Date) -> [Int?] {
        let parts = DemoClock.calendar.dateComponents([.year, .month, .day], from: date)
        return [parts.year, parts.month, parts.day]
    }
}
```

`DashboardKit/Tests/DashboardKitTests/TimeRangeTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct TimeRangeTests {
    static let expectedStarts: [(TimeRange, [Int?])] = [
        (.week, [2026, 9, 24]),
        (.month, [2026, 9, 1]),
        (.quarter, [2026, 7, 3]),
        (.year, [2025, 10, 1])
    ]

    @Test func anchorIsSeptember30th2026() {
        #expect(Fixture.ymd(DemoClock.anchorDate) == [2026, 9, 30])
    }

    @Test(arguments: TimeRangeTests.expectedStarts)
    func rangeStartsTheRightNumberOfDaysBeforeTheEndOfTheAnchorDay(range: TimeRange, expectedStart: [Int?]) {
        let dates = range.dateRange()
        #expect(Fixture.ymd(dates.lowerBound) == expectedStart)
        #expect(dates.upperBound == DemoClock.anchorDate.addingTimeInterval(Fixture.secondsPerDay))
        #expect(dates.upperBound.timeIntervalSince(dates.lowerBound) == TimeInterval(range.dayCount) * Fixture.secondsPerDay)
    }

    @Test func thereAreEightSpendingCategoriesAndIncomeIsNotOne() {
        #expect(TransactionCategory.spending.count == 8)
        #expect(!TransactionCategory.spending.contains(.income))
    }
}
```

- [ ] **Step 4: Run the tests and confirm they fail**

Run: `swift test --package-path DashboardKit --filter TimeRangeTests`
Expected: build failure: `cannot find 'DemoClock' in scope` (and similar for `TimeRange`, `AccountTransaction`, `TransactionCategory`).

- [ ] **Step 5: Implement the models**

`DashboardKit/Sources/DashboardKit/Model/DemoClock.swift`:

```swift
import Foundation

/// The demo's fixed "today". Data is generated relative to it, so captures made on different days show the same numbers.
public enum DemoClock {
    /// Gregorian calendar pinned to GMT, so day buckets and date labels agree on every device.
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// 2026-09-30 00:00:00 GMT.
    public static let anchorDate = Date(timeIntervalSince1970: 1_790_726_400)
}
```

`DashboardKit/Sources/DashboardKit/Model/TransactionCategory.swift`:

```swift
import Foundation

/// What a transaction was for. `income` is the only category with positive amounts; the other eight are spending.
public enum TransactionCategory: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case income, groceries, dining, transport, home, utilities, entertainment, shopping, health

    /// The eight spending categories, in display order.
    public static let spending: [TransactionCategory] = allCases.filter { $0 != .income }

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .income: "Income"
        case .groceries: "Groceries"
        case .dining: "Dining"
        case .transport: "Transport"
        case .home: "Home"
        case .utilities: "Utilities"
        case .entertainment: "Entertainment"
        case .shopping: "Shopping"
        case .health: "Health"
        }
    }

    /// `title` as a plain string, for Swift Charts series names.
    public var name: String { String(localized: title) }

    public var systemImage: String {
        switch self {
        case .income: "banknote"
        case .groceries: "cart"
        case .dining: "fork.knife"
        case .transport: "car"
        case .home: "house"
        case .utilities: "bolt"
        case .entertainment: "film"
        case .shopping: "bag"
        case .health: "cross.case"
        }
    }

    public static func < (lhs: TransactionCategory, rhs: TransactionCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

`DashboardKit/Sources/DashboardKit/Model/TransactionCategory+Color.swift`:

```swift
import SwiftUI

extension TransactionCategory {
    /// The category's color in the chart and breakdown. Text never relies on it alone.
    public var color: Color {
        switch self {
        case .income: .green
        case .groceries: .mint
        case .dining: .orange
        case .transport: .blue
        case .home: .brown
        case .utilities: .yellow
        case .entertainment: .purple
        case .shopping: .pink
        case .health: .red
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Model/AccountTransaction.swift`:

```swift
import Foundation

/// One account transaction. Income is positive, spending is negative.
///
/// Named `AccountTransaction` rather than `Transaction` because `SwiftUI.Transaction` already exists.
public struct AccountTransaction: Identifiable, Hashable, Sendable {
    public let id: Int
    public let date: Date
    public let merchant: String
    public let category: TransactionCategory
    public let amount: Decimal
    public let isPending: Bool

    public var isIncome: Bool { amount > 0 }
}
```

`DashboardKit/Sources/DashboardKit/Model/TimeRange.swift`:

```swift
import Foundation

/// The dashboard's time-range picker values. Each covers the last `dayCount` whole days up to and including the anchor day.
public enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case week, month, quarter, year

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .quarter: "Quarter"
        case .year: "Year"
        }
    }

    public var dayCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        }
    }

    /// Half-open range from the start of the first day to the start of the day after `anchor`.
    public func dateRange(endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar) -> Range<Date> {
        let startOfAnchorDay = calendar.startOfDay(for: anchor)
        let end = calendar.date(byAdding: .day, value: 1, to: startOfAnchorDay) ?? startOfAnchorDay
        let start = calendar.date(byAdding: .day, value: -dayCount, to: end) ?? end
        return start..<end
    }
}
```

- [ ] **Step 6: Run the tests and confirm they pass**

Run: `swift test --package-path DashboardKit --filter TimeRangeTests`
Expected: PASS. Six test cases: the anchor test, 4 range arguments, and the categories test.

- [ ] **Step 7: Add the project SwiftLint config and lint**

`.swiftlint.yml`:

```yaml
# Project additions layered on top of ~/.swiftlint.yml. Always lint with both:
#   swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml
excluded:
  - build
  - DashboardKit/.build
```

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml`
Expected: `Found 0 violations`.

- [ ] **Step 8: Write `CLAUDE.md`**

```markdown
# CLAUDE.md — ComputedPropertiesView

## Status

Implementation follows `docs/superpowers/plans/2026-09-26-computed-vs-struct-views.md`; its checkboxes show progress.
Design: `docs/superpowers/specs/2026-09-26-computed-vs-struct-views-design.md`.

## What this is

Two iOS 27 demo apps that are identical except for how the dashboard's six sections are factored:

- **Computed** (`ComputedDashboard/`): sections are `private var …: some View` computed properties. **Intentional anti-pattern.**
- **Structs** (`StructDashboard/`): each section is its own `View` struct with narrow inputs.

The goal is to show, on video and in Instruments, that the Computed app hitches when the dashboard's `@State` changes
(especially while dragging the budget slider) and the Structs app doesn't. It's both a teaching demo and an honest
experiment: if the Realistic intensity shows no difference, that's a result to report, not to tune away.

## Architecture

- `DashboardKit/`: local Swift package shared by both apps.
  - Models, seeded sample data, and `TransactionMath` (the derived work that section bodies do).
  - `DemoSettings` and `TransactionStore`.
  - Diagnostics: the frame-meter HUD and "body runs" badges.
  - `DemoShell`, the shared root view.
- `ComputedPropertiesView.xcodeproj`: targets `ComputedDashboard` and `StructDashboard`. Each contains only its `App`
  struct and dashboard view code.

## Conventions (don't break these)

- **Section parity:** each section body sits between `// BEGIN SECTION BODY: <name>` and `// END SECTION BODY: <name>`
  and must be textually identical in both apps. Run `Scripts/check-section-parity.sh` after touching either copy.
- The Structs app's `DashboardView.body` only forwards inputs. Never filter or aggregate there.
- Transaction rows stay inline in both apps; the only variable is how the sections are factored.
- The model is `AccountTransaction`, not `Transaction`, because `SwiftUI.Transaction` would make the name ambiguous.
- `EvaluationCounter` is deliberately **not** `@Observable` and is a singleton. Recording a body run must never
  trigger another one.
- One type per file. Swift Testing only. `@MainActor` on every `@Observable` class. English only.
- iOS 27's `@State` is a macro: give `@State` properties an initial value and never also assign them in `init`.

## Build, test, run

- Package tests (fast, on the Mac): `swift test --package-path DashboardKit`
- Build an app for the simulator:
  `xcodebuild -project ComputedPropertiesView.xcodeproj -scheme ComputedDashboard -destination "id=B9BB0E3F-E390-472F-AD17-952DA5298A94" -derivedDataPath build/DerivedData build`
  Swap the scheme for `StructDashboard`. Add `-configuration Release` for anything you'll measure.
- Simulator used here: iPhone 18 Pro, iOS 27.0, id `B9BB0E3F-E390-472F-AD17-952DA5298A94`.
- Lint: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml`
- Section parity: `Scripts/check-section-parity.sh`

## Launch arguments

- `-intensity light|realistic|heavy|severe|extreme` (value is case-insensitive; default realistic)
- `-showEvaluationBadges` turns on the "body runs" badges.

## Intensity levels

| Level | Transactions (1 year) | Rows in Recent list |
|---|---|---|
| Light | 1,000 | 25 |
| Realistic (default) | 3,000 | 50 |
| Heavy | 10,000 | 150 |
| Severe | 30,000 | 300 |
| Extreme | 100,000 | 600 |

## Gotchas

- Measure with Release builds. Debug builds exaggerate SwiftUI costs.
- The package declares macOS 27 only so `swift test` runs on the Mac. The apps are iOS-only.
- `DashboardKit` is linked to the app targets by hand in Xcode, because no available tool adds a local package. If
  the link breaks: File ▸ Add Package Dependencies… ▸ Add Local… ▸ `DashboardKit`, then add the library to both targets.
- The HUD measures main-thread frame pacing from `TimelineView(.animation)` dates. Instruments is the source of truth.
- `SessionLog.md` records every working session's inputs and outputs. Keep appending to it.
```

- [ ] **Step 9: Write the first version of `Journal.md`**

````markdown
# Journal — The Tale of Two Dashboards

## 1. The Big Picture

There's a piece of SwiftUI folk wisdom: *"Don't build your views out of computed properties."* Everybody repeats it;
fewer people have watched it bite. This project builds the bite on purpose.

We ship two nearly identical iPhone apps showing a personal-finance dashboard: an account summary, a budget slider,
a spending chart, a category breakdown, and a list of recent transactions. The **Computed** app builds each section
as a `private var something: some View`. The **Structs** app builds each section as its own little `View` struct. Same
data, same code inside each section, same everything, except that one refactor. Then we drag the budget slider and
watch which one stutters.

It's a teaching demo *and* an honest experiment. A clearly labeled "intensity" setting lets us crank the data up
until the difference is undeniable, but we always start at a realistic level and report what we actually see.

## 2. Architecture Deep Dive

Picture a restaurant with one kitchen and two dining rooms.

- **The kitchen is `DashboardKit`.** It makes the ingredients (seeded sample transactions), follows the recipes
  (`TransactionMath`: filtering, summing, grouping, binning), and runs the front-of-house systems both rooms share: the
  settings menu, the frame-rate HUD, and the "body runs" badges.
- **Each dining room is an app target**, and the only thing that differs is how the waiters work.
  - In the **Computed** room, a single waiter serves every table. When anyone asks for anything (say, the budget
    slider moves), that waiter re-reads the entire menu at every table, including tables that didn't ask. That's
    what a computed property does: it's inlined into the parent's `body`, so it shares the parent's *invalidation
    boundary*.
  - In the **Structs** room, every table has its own waiter. When the budget changes, only the Budget table's waiter
    moves. SwiftUI compares each section's inputs, sees that five of them didn't change, and skips their bodies
    entirely.

One subtle rule keeps the Structs room honest: the head waiter (the parent `DashboardView`) must not do any cooking.
If the parent filtered the transactions itself, it would hand every section a brand-new array on every slider tick,
and every waiter would get up at once. So the parent only forwards raw ingredients.

## 3. The Codebase Map

```
DashboardKit/            the shared kitchen (Swift package + Swift Testing tests)
  Model/                 AccountTransaction, TransactionCategory, TimeRange, DemoClock, DashboardSection
  Data/                  SeededRandomGenerator, SampleDataGenerator, TransactionStore
  Math/                  TransactionMath, CategoryTotal, DailyCategoryTotal
  Settings/              Intensity, LaunchArguments, DemoSettings
  Diagnostics/           FrameStats, FrameMeterView (HUD), EvaluationCounter, EvaluationBadge, …
  Shell/                 DemoShell, AppVariant, SettingsMenu
ComputedDashboard/       dining room #1: DashboardView with six computed-property sections
StructDashboard/         dining room #2: DashboardView + Sections/ (one struct per section)
Scripts/                 check-section-parity.sh: proves the section bodies are identical
Captures/                how to record videos and Instruments traces (the media itself is git-ignored)
docs/superpowers/        the design spec and this implementation plan
```

## 4. Tech Stack & Why

- **SwiftUI on iOS 27** is the subject of the experiment. We can't study SwiftUI's invalidation without SwiftUI.
- **A local Swift package** guarantees both apps share the *exact* same data and math. If each app had its own copy,
  a skeptic could say "your workloads weren't identical," and they'd have a point.
- **Swift Charts** is a realistic, genuinely expensive thing to rebuild, and it's Apple's own, so there's no
  third-party dependency.
- **Observation (`@Observable`)** for the store and settings: per-property tracking means only views that read a
  property are invalidated when it changes.
- **Swift Testing** for all the logic. Views stay thin, and the math, data generation, and frame-stat logic are pure
  and testable.
- **A seeded random generator (SplitMix64)**, because `Int.random()` would give each app different data on every launch.

## 5. The Journey

### 2026-09-26: Design day

- **The name collision we dodged.** The obvious model name, `Transaction`, is already taken by `SwiftUI.Transaction`
  (the animation kind). Every view file would have hit "ambiguous type" errors, especially with iOS 27's new unified
  `@ContentBuilder`, which leans less on the `View` constraint to disambiguate. It became `AccountTransaction`.
- **The flash that failed accessibility.** The first idea for showing re-evaluation was to flash each section a random
  color whenever its body ran. Drag a slider and that's dozens of flashes per second over big areas, which fails
  WCAG 2.3.1 (no more than three flashes per second). We switched to a quiet "body runs: 1,234" counter badge. It's
  accessible, and it gives us exact numbers for the videos.
- **A slider can't hold money.** `Slider` needs a floating-point value, so the budget is a `Double` in the view and
  becomes a `Decimal` only when it's compared with spending.
- **`@State` is a macro now.** In the iOS 27 SDK, `@State` synthesizes real backing storage. Give it an initial value
  and never also assign it in `init`, or you'll get "used before being initialized" errors or, worse, silently
  ignored assignments.

## 6. Engineer's Wisdom

- **Isolate one variable.** The two apps differ in exactly one way, and a script proves it. Without that, any
  difference you measure is an anecdote.
- **Structs limit *how often* work runs; caching limits *how much*.** Both are real fixes. This project isolates the
  first on purpose, and the time-range picker (state that really is needed everywhere) is the control case showing
  that structs don't make necessary work free.
- **Measure on real hardware in Release builds.** The simulator and Debug builds both lie about performance, in
  different directions.
- **Put the "why" next to the anti-pattern.** The Computed app's dashboard opens with a loud comment, so nobody copies
  it into a real app.

## 7. If I Were Starting Over…

It's early, but one lesson already stands out: decide how you'll *prove* a performance claim (the badges, the HUD,
the parity script, the capture protocol) before writing the thing you want to measure. Instrumentation added
afterward tends to measure whatever is easy to measure.
````

- [ ] **Step 10: Commit**

```bash
git add DashboardKit .swiftlint.yml CLAUDE.md Journal.md
git commit -F - <<'EOF'
feat: add DashboardKit package with core models and project docs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: Seeded random generator and sample data

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Data/SeededRandomGenerator.swift`
- Create: `DashboardKit/Sources/DashboardKit/Data/SampleDataGenerator.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/SeededRandomGeneratorTests.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/SampleDataGeneratorTests.swift`

**Interfaces:**
- Consumes (Task 1): `AccountTransaction` memberwise init, `TransactionCategory.spending`, `TimeRange.year.dateRange(endingOn:calendar:)`, `DemoClock`.
- Produces:
  - `struct SeededRandomGenerator: RandomNumberGenerator, Sendable { init(seed: UInt64); mutating func next() -> UInt64 }`
  - `enum SampleDataGenerator { static let defaultSeed: UInt64; @concurrent static func transactions(count: Int, seed: UInt64 = defaultSeed) async -> [AccountTransaction]; static func makeTransactions(count:seed:anchor:calendar:) -> [AccountTransaction] }` (`makeTransactions` is internal). Results are newest first, with ids `0..<count`.

- [ ] **Step 1: Write the failing generator tests**

`DashboardKit/Tests/DashboardKitTests/SeededRandomGeneratorTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite struct SeededRandomGeneratorTests {
    @Test func seedZeroMatchesTheSplitMix64ReferenceValues() {
        var generator = SeededRandomGenerator(seed: 0)
        #expect(generator.next() == 0xE220_A839_7B1D_CDAF)
        #expect(generator.next() == 0x6E78_9E6A_A1B9_65F4)
    }

    @Test func sameSeedGivesTheSameSequence() {
        var first = SeededRandomGenerator(seed: 42)
        var second = SeededRandomGenerator(seed: 42)
        let firstValues = (0..<5).map { _ in first.next() }
        let secondValues = (0..<5).map { _ in second.next() }
        #expect(firstValues == secondValues)
    }

    @Test func differentSeedsGiveDifferentSequences() {
        var first = SeededRandomGenerator(seed: 1)
        var second = SeededRandomGenerator(seed: 2)
        let firstValues = (0..<5).map { _ in first.next() }
        let secondValues = (0..<5).map { _ in second.next() }
        #expect(firstValues != secondValues)
    }
}
```

`DashboardKit/Tests/DashboardKitTests/SampleDataGeneratorTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct SampleDataGeneratorTests {
    static let sample = make(count: 500)

    static func make(count: Int, seed: UInt64 = SampleDataGenerator.defaultSeed) -> [AccountTransaction] {
        SampleDataGenerator.makeTransactions(count: count, seed: seed, anchor: DemoClock.anchorDate, calendar: DemoClock.calendar)
    }

    @Test func countMatchesTheRequest() {
        #expect(Self.sample.count == 500)
        #expect(Self.make(count: 0).isEmpty)
    }

    @Test func asyncAPIReturnsTheIntensitysCount() async {
        let transactions = await SampleDataGenerator.transactions(count: 1_000)
        #expect(transactions.count == 1_000)
    }

    @Test func outputIsDeterministicPerSeed() {
        #expect(Self.make(count: 500) == Self.sample)
        #expect(Self.make(count: 500, seed: 7) != Self.sample)
    }

    @Test func everyDateFallsWithinTheYearBeforeTheAnchor() {
        let year = TimeRange.year.dateRange()
        #expect(Self.sample.allSatisfy { year.contains($0.date) })
    }

    @Test func allEightSpendingCategoriesAppear() {
        let categories = Set(Self.sample.map(\.category))
        #expect(Set(TransactionCategory.spending).isSubset(of: categories))
    }

    @Test func incomeIsPositiveAndSpendingIsNegative() {
        #expect(Self.sample.contains { $0.category == .income })
        #expect(Self.sample.allSatisfy { $0.category == .income ? $0.amount > 0 : $0.amount < 0 })
    }

    @Test func atLeastOneTransactionIsPending() {
        #expect(Self.sample.contains(where: \.isPending))
    }

    @Test func resultsAreNewestFirstWithSequentialIDs() {
        #expect(zip(Self.sample, Self.sample.dropFirst()).allSatisfy { $0.date >= $1.date })
        #expect(Self.sample.map(\.id) == Array(0..<500))
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `swift test --package-path DashboardKit --filter "SeededRandomGeneratorTests|SampleDataGeneratorTests"`
Expected: build failure: `cannot find 'SeededRandomGenerator' in scope`, `cannot find 'SampleDataGenerator' in scope`.

- [ ] **Step 3: Implement the generators**

`DashboardKit/Sources/DashboardKit/Data/SeededRandomGenerator.swift`:

```swift
/// SplitMix64: a tiny, fast, deterministic generator. Both apps seed it identically, so they generate identical data.
public struct SeededRandomGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
```

`DashboardKit/Sources/DashboardKit/Data/SampleDataGenerator.swift`:

```swift
import Foundation

/// Builds a deterministic year of account activity, so both demo apps show exactly the same transactions.
public enum SampleDataGenerator {
    public static let defaultSeed: UInt64 = 2_026

    /// At most this many paychecks, one every 14 days.
    static let paydayCount = 26
    static let paycheck: Decimal = 3_250
    static let secondsPerDay: TimeInterval = 86_400

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
        let span = year.upperBound.timeIntervalSince(year.lowerBound)
        let spending = TransactionCategory.spending
        let incomeCount = min(paydayCount, count / 10)

        var entries: [AccountTransaction] = []
        entries.reserveCapacity(count)
        for index in 0..<incomeCount {
            let payday = year.lowerBound.addingTimeInterval(TimeInterval(index * 14) * secondsPerDay + 9 * 3_600)
            entries.append(
                AccountTransaction(
                    id: 0, date: payday, merchant: "Employer Payroll", category: .income, amount: paycheck, isPending: false
                )
            )
        }
        for _ in incomeCount..<count {
            let category = spending[Int.random(in: 0..<spending.count, using: &generator)]
            let names = merchants(for: category)
            let merchant = names[Int.random(in: 0..<names.count, using: &generator)]
            let cents = Int.random(in: centsRange(for: category), using: &generator)
            let date = year.lowerBound.addingTimeInterval(Double.random(in: 0..<span, using: &generator))
            let isPending = Int.random(in: 0..<20, using: &generator) == 0
            entries.append(
                AccountTransaction(
                    id: 0, date: date, merchant: merchant, category: category, amount: -Decimal(cents) / 100, isPending: isPending
                )
            )
        }
        entries.sort { $0.date > $1.date }
        return entries.enumerated().map { $0.element.withID($0.offset) }
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

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `swift test --package-path DashboardKit --filter "SeededRandomGeneratorTests|SampleDataGeneratorTests"`
Expected: PASS (11 tests).

- [ ] **Step 5: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add seeded sample transaction generator

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: TransactionMath — the derived work section bodies do

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Math/CategoryTotal.swift`
- Create: `DashboardKit/Sources/DashboardKit/Math/DailyCategoryTotal.swift`
- Create: `DashboardKit/Sources/DashboardKit/Math/TransactionMath.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/TransactionMathTests.swift`

**Interfaces:**
- Consumes (Task 1): `AccountTransaction`, `TransactionCategory` (Comparable), `TimeRange.dateRange()`, `Fixture`.
- Produces (all `public static` on `enum TransactionMath`):
  - `transactions(_ transactions: [AccountTransaction], in range: Range<Date>) -> [AccountTransaction]`
  - `income(of:) -> Decimal`, `expenses(of:) -> Decimal` (positive magnitude), `net(of:) -> Decimal`
  - `budgetUsage(spent: Decimal, budget: Double) -> Double` (clamped to 0…1)
  - `budgetCeiling(forSpent spent: Decimal) -> Double` (2× spent, rounded up, minimum 100)
  - `categoryTotals(of:) -> [CategoryTotal]` (spending only, largest first, ties by category)
  - `dailyTotals(of:calendar:) -> [DailyCategoryTotal]` (spending only, sorted by day then category)
  - `pendingOnly(_:) -> [AccountTransaction]`, `newestFirst(_:limit:) -> [AccountTransaction]`
  - `struct CategoryTotal: Identifiable, Hashable, Sendable { category; total: Decimal; share: Double; id }`
  - `struct DailyCategoryTotal: Identifiable, Hashable, Sendable { key: Key; total: Decimal; id: Key; day: Date; category; amount: Double }` with nested `Key { day; category }`

- [ ] **Step 1: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/TransactionMathTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct TransactionMathTests {
    let week = TimeRange.week.dateRange()

    @Test func rangeFilterIncludesBothBoundaryDaysAndExcludesOutside() {
        let firstDay = Fixture.transaction(-1, .dining, on: Fixture.date(dayOffset: -6, hour: 0))
        let lastMinute = Fixture.transaction(-2, .dining, on: Fixture.date(dayOffset: 0, hour: 23, minute: 59))
        let tooEarly = Fixture.transaction(-3, .dining, on: Fixture.date(dayOffset: -7, hour: 23, minute: 59))
        let tooLate = Fixture.transaction(-4, .dining, on: Fixture.date(dayOffset: 1, hour: 0))
        let result = TransactionMath.transactions([firstDay, lastMinute, tooEarly, tooLate], in: week)
        #expect(result == [firstDay, lastMinute])
    }

    @Test func sumsIncomeExpensesAndNet() {
        let sample = [
            Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-120.5, .groceries, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-79.5, .dining, on: Fixture.date(dayOffset: -2))
        ]
        #expect(TransactionMath.income(of: sample) == 3_250)
        #expect(TransactionMath.expenses(of: sample) == 200)
        #expect(TransactionMath.net(of: sample) == 3_050)
    }

    @Test func spendingTotalForTheBudgetGaugeCountsOnlyExpensesInRange() {
        let sample = [
            Fixture.transaction(-40, .transport, on: Fixture.date(dayOffset: -3)),
            Fixture.transaction(-60, .shopping, on: Fixture.date(dayOffset: -30)),
            Fixture.transaction(500, .income, on: Fixture.date(dayOffset: -3))
        ]
        #expect(TransactionMath.expenses(of: TransactionMath.transactions(sample, in: week)) == 40)
    }

    @Test func categoryTotalsAreSortedLargestFirstAndSharesAddUpToOne() {
        let sample = [
            Fixture.transaction(-10, .dining, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-60, .groceries, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-30, .dining, on: Fixture.date(dayOffset: -2)),
            Fixture.transaction(1_000, .income, on: Fixture.date(dayOffset: -2))
        ]
        let totals = TransactionMath.categoryTotals(of: sample)
        #expect(totals.map(\.category) == [.groceries, .dining])
        #expect(totals.map(\.total) == [60, 40])
        #expect(abs(totals[0].share - 0.6) < 1e-9)
        #expect(abs(totals.map(\.share).reduce(0, +) - 1) < 1e-9)
    }

    @Test func categoryTotalTiesFollowCategoryOrder() {
        let sample = [
            Fixture.transaction(-20, .shopping, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-20, .dining, on: Fixture.date(dayOffset: -1))
        ]
        #expect(TransactionMath.categoryTotals(of: sample).map(\.category) == [.dining, .shopping])
    }

    @Test func categoryTotalsForARangeWithNoSpendingAreEmpty() {
        #expect(TransactionMath.categoryTotals(of: []).isEmpty)
        let incomeOnly = [Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1))]
        #expect(TransactionMath.categoryTotals(of: incomeOnly).isEmpty)
        #expect(TransactionMath.expenses(of: incomeOnly) == 0)
    }

    @Test func dailyTotalsBinByDayAndCategorySkippingIncome() {
        let sample = [
            Fixture.transaction(-10, .groceries, on: Fixture.date(dayOffset: -1, hour: 9)),
            Fixture.transaction(-5, .groceries, on: Fixture.date(dayOffset: -1, hour: 18)),
            Fixture.transaction(-7, .dining, on: Fixture.date(dayOffset: -1, hour: 20)),
            Fixture.transaction(-3, .groceries, on: Fixture.date(dayOffset: 0, hour: 8)),
            Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1, hour: 9))
        ]
        let dayBefore = Fixture.date(dayOffset: -1, hour: 0)
        let anchorDay = Fixture.date(dayOffset: 0, hour: 0)
        let bins = TransactionMath.dailyTotals(of: sample, calendar: DemoClock.calendar)
        #expect(bins.map(\.day) == [dayBefore, dayBefore, anchorDay])
        #expect(bins.map(\.category) == [.groceries, .dining, .groceries])
        #expect(bins.map(\.total) == [15, 7, 3])
        #expect(bins.map(\.amount) == [15, 7, 3])
    }

    @Test func pendingOnlyKeepsOnlyPendingTransactions() {
        let pending = Fixture.transaction(-5, .health, on: Fixture.date(dayOffset: -1), isPending: true)
        let settled = Fixture.transaction(-6, .health, on: Fixture.date(dayOffset: -1))
        #expect(TransactionMath.pendingOnly([pending, settled]) == [pending])
    }

    @Test func newestFirstSortsDescendingAndHonorsTheLimit() {
        let old = Fixture.transaction(-1, .home, on: Fixture.date(dayOffset: -3))
        let middle = Fixture.transaction(-2, .home, on: Fixture.date(dayOffset: -2))
        let newest = Fixture.transaction(-3, .home, on: Fixture.date(dayOffset: -1))
        #expect(TransactionMath.newestFirst([old, newest, middle], limit: 2) == [newest, middle])
    }

    @Test(arguments: [
        (Decimal(50), 200.0, 0.25),
        (Decimal(500), 200.0, 1.0),
        (Decimal(0), 0.0, 0.0),
        (Decimal(10), 0.0, 1.0)
    ])
    func budgetUsageStaysBetweenZeroAndOne(spent: Decimal, budget: Double, expected: Double) {
        #expect(TransactionMath.budgetUsage(spent: spent, budget: budget) == expected)
    }

    @Test func budgetCeilingIsTwiceTheSpendingWithAFloor() {
        #expect(TransactionMath.budgetCeiling(forSpent: 1_234.5) == 2_469)
        #expect(TransactionMath.budgetCeiling(forSpent: 0) == 100)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `swift test --package-path DashboardKit --filter TransactionMathTests`
Expected: build failure: `cannot find 'TransactionMath' in scope`.

- [ ] **Step 3: Implement**

`DashboardKit/Sources/DashboardKit/Math/CategoryTotal.swift`:

```swift
import Foundation

/// Spending for one category within a range.
public struct CategoryTotal: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    /// Positive amount spent.
    public let total: Decimal
    /// Fraction of all spending in the range, 0…1.
    public let share: Double

    public var id: TransactionCategory { category }
}
```

`DashboardKit/Sources/DashboardKit/Math/DailyCategoryTotal.swift`:

```swift
import Foundation

/// Spending for one category on one day: a single stacked bar segment in the spending chart.
public struct DailyCategoryTotal: Identifiable, Hashable, Sendable {
    public struct Key: Hashable, Sendable {
        public let day: Date
        public let category: TransactionCategory
    }

    public let key: Key
    /// Positive amount spent.
    public let total: Decimal

    public var id: Key { key }
    public var day: Date { key.day }
    public var category: TransactionCategory { key.category }

    /// `total` as a `Double`, the value type Swift Charts plots.
    public var amount: Double { NSDecimalNumber(decimal: total).doubleValue }
}
```

`DashboardKit/Sources/DashboardKit/Math/TransactionMath.swift`:

```swift
import Foundation

/// The derived work each dashboard section does in its body. Pure functions, callable from any isolation.
///
/// Both apps call exactly these functions from their section bodies, so the per-section cost is identical;
/// the only difference between the apps is *how often* each section's body runs.
public enum TransactionMath {
    public static func transactions(_ transactions: [AccountTransaction], in range: Range<Date>) -> [AccountTransaction] {
        transactions.filter { range.contains($0.date) }
    }

    public static func income(of transactions: [AccountTransaction]) -> Decimal {
        transactions.reduce(into: Decimal.zero) { total, transaction in
            if transaction.amount > 0 { total += transaction.amount }
        }
    }

    /// Total spending as a positive amount.
    public static func expenses(of transactions: [AccountTransaction]) -> Decimal {
        transactions.reduce(into: Decimal.zero) { total, transaction in
            if transaction.amount < 0 { total -= transaction.amount }
        }
    }

    public static func net(of transactions: [AccountTransaction]) -> Decimal {
        income(of: transactions) - expenses(of: transactions)
    }

    /// Fraction of the budget used, clamped to 0…1. A $0 budget reads as full if anything was spent.
    public static func budgetUsage(spent: Decimal, budget: Double) -> Double {
        let spentValue = NSDecimalNumber(decimal: spent).doubleValue
        guard budget > 0 else { return spentValue > 0 ? 1 : 0 }
        return min(max(spentValue / budget, 0), 1)
    }

    /// The budget slider's upper bound: twice what was spent in the range, never below $100.
    public static func budgetCeiling(forSpent spent: Decimal) -> Double {
        max((NSDecimalNumber(decimal: spent).doubleValue * 2).rounded(.up), 100)
    }

    /// Spending per category, largest first. Empty when nothing was spent.
    public static func categoryTotals(of transactions: [AccountTransaction]) -> [CategoryTotal] {
        var totals: [TransactionCategory: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 {
            totals[transaction.category, default: 0] -= transaction.amount
        }
        let grandTotal = totals.values.reduce(Decimal.zero, +)
        guard grandTotal > 0 else { return [] }
        return totals
            .map { category, total in
                CategoryTotal(category: category, total: total, share: NSDecimalNumber(decimal: total / grandTotal).doubleValue)
            }
            .sorted { $0.total != $1.total ? $0.total > $1.total : $0.category < $1.category }
    }

    /// Spending per day and category, sorted by day and then category.
    public static func dailyTotals(of transactions: [AccountTransaction], calendar: Calendar) -> [DailyCategoryTotal] {
        var totals: [DailyCategoryTotal.Key: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 {
            let key = DailyCategoryTotal.Key(day: calendar.startOfDay(for: transaction.date), category: transaction.category)
            totals[key, default: 0] -= transaction.amount
        }
        return totals
            .map { DailyCategoryTotal(key: $0.key, total: $0.value) }
            .sorted { ($0.day, $0.category) < ($1.day, $1.category) }
    }

    public static func pendingOnly(_ transactions: [AccountTransaction]) -> [AccountTransaction] {
        transactions.filter(\.isPending)
    }

    public static func newestFirst(_ transactions: [AccountTransaction], limit: Int) -> [AccountTransaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(limit))
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `swift test --package-path DashboardKit --filter TransactionMathTests`
Expected: PASS (14 test cases, since the budget-usage test has 4 arguments).

- [ ] **Step 5: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add TransactionMath for section-body aggregation

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Intensity, launch arguments, settings, and the transaction store

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Settings/Intensity.swift`
- Create: `DashboardKit/Sources/DashboardKit/Settings/LaunchArguments.swift`
- Create: `DashboardKit/Sources/DashboardKit/Settings/DemoSettings.swift`
- Create: `DashboardKit/Sources/DashboardKit/Data/TransactionStore.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/IntensityTests.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/DemoSettingsTests.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/TransactionStoreTests.swift`

**Interfaces:**
- Consumes (Task 2): `SampleDataGenerator.transactions(count:seed:)`, `SampleDataGenerator.defaultSeed`.
- Produces:
  - `enum Intensity: String, CaseIterable, Identifiable, Sendable { light, realistic, heavy, severe, extreme }` with `title: LocalizedStringResource`, `transactionCount: Int`, `recentRowLimit: Int`, `static let standard: Intensity` (`.realistic`)
  - `enum LaunchArguments { static func intensity(from: [String]) -> Intensity; static func showsEvaluationBadges(from: [String]) -> Bool }`
  - `@MainActor @Observable final class DemoSettings { var intensity: Intensity; var showsEvaluationBadges: Bool; init(arguments: [String] = ProcessInfo.processInfo.arguments) }`
  - `@MainActor @Observable final class TransactionStore { private(set) var transactions: [AccountTransaction]; private(set) var loadedIntensity: Intensity?; private(set) var isLoading: Bool; init(seed: UInt64 = SampleDataGenerator.defaultSeed); func load(_ intensity: Intensity) async }`

- [ ] **Step 1: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/IntensityTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite struct IntensityTests {
    @Test func intensityValueParsesRegardlessOfCase() {
        #expect(LaunchArguments.intensity(from: ["App", "-intensity", "HEAVY"]) == .heavy)
        #expect(LaunchArguments.intensity(from: ["App", "-intensity", "extreme"]) == .extreme)
    }

    @Test(arguments: [["App"], ["App", "-intensity"], ["App", "-intensity", "bogus"]])
    func missingDanglingOrUnknownValuesFallBackToRealistic(arguments: [String]) {
        #expect(LaunchArguments.intensity(from: arguments) == .realistic)
    }

    @Test func eachLevelIsStrictlyLargerThanThePrevious() {
        let levels = Intensity.allCases
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0.transactionCount < $1.transactionCount })
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0.recentRowLimit < $1.recentRowLimit })
        #expect(Intensity.standard == .realistic)
        #expect(Intensity.realistic.transactionCount == 3_000)
    }

    @Test func badgeFlagIsReadFromLaunchArguments() {
        #expect(LaunchArguments.showsEvaluationBadges(from: ["App", "-showEvaluationBadges"]))
        #expect(!LaunchArguments.showsEvaluationBadges(from: ["App"]))
    }
}
```

`DashboardKit/Tests/DashboardKitTests/DemoSettingsTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite @MainActor struct DemoSettingsTests {
    @Test func settingsReadLaunchArguments() {
        let settings = DemoSettings(arguments: ["App", "-intensity", "severe", "-showEvaluationBadges"])
        #expect(settings.intensity == .severe)
        #expect(settings.showsEvaluationBadges)
    }

    @Test func badgesDefaultToOff() {
        let settings = DemoSettings(arguments: ["App"])
        #expect(settings.intensity == .realistic)
        #expect(!settings.showsEvaluationBadges)
    }
}
```

`DashboardKit/Tests/DashboardKitTests/TransactionStoreTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite @MainActor struct TransactionStoreTests {
    @Test func loadGeneratesTheIntensitysTransactionCount() async {
        let store = TransactionStore()
        await store.load(.light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(store.loadedIntensity == .light)
        #expect(!store.isLoading)
    }

    @Test func theLatestRequestWinsWhenAnEarlierOneFinishesLater() async {
        let store = TransactionStore()
        let heavy = Task { await store.load(.heavy) }
        await Task.yield()
        let light = Task { await store.load(.light) }
        heavy.cancel()
        await heavy.value
        await light.value
        #expect(store.loadedIntensity == .light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(!store.isLoading)
    }

    @Test func switchingBackToTheLoadedLevelDiscardsTheInFlightLoad() async {
        let store = TransactionStore()
        await store.load(.light)
        let heavy = Task { await store.load(.heavy) }
        await Task.yield()
        let backToLight = Task { await store.load(.light) }
        await heavy.value
        await backToLight.value
        #expect(store.loadedIntensity == .light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(!store.isLoading)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `swift test --package-path DashboardKit --filter "IntensityTests|DemoSettingsTests|TransactionStoreTests"`
Expected: build failure: `cannot find 'LaunchArguments' in scope`, `cannot find 'DemoSettings' in scope`, `cannot find 'TransactionStore' in scope`.

- [ ] **Step 3: Implement**

`DashboardKit/Sources/DashboardKit/Settings/Intensity.swift`:

```swift
import Foundation

/// How much data the dashboard works with. Named steps, so a capture can be reproduced exactly.
public enum Intensity: String, CaseIterable, Identifiable, Sendable {
    case light, realistic, heavy, severe, extreme

    public static let standard: Intensity = .realistic

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .light: "Light"
        case .realistic: "Realistic"
        case .heavy: "Heavy"
        case .severe: "Severe"
        case .extreme: "Extreme"
        }
    }

    /// Transactions generated for the year.
    public var transactionCount: Int {
        switch self {
        case .light: 1_000
        case .realistic: 3_000
        case .heavy: 10_000
        case .severe: 30_000
        case .extreme: 100_000
        }
    }

    /// Rows shown in the non-lazy Recent Transactions list.
    public var recentRowLimit: Int {
        switch self {
        case .light: 25
        case .realistic: 50
        case .heavy: 150
        case .severe: 300
        case .extreme: 600
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Settings/LaunchArguments.swift`:

```swift
import os

/// Reads launch arguments, so Instruments runs and recordings start in the same configuration every time.
public enum LaunchArguments {
    static let logger = Logger(subsystem: "com.hotngui.DashboardKit", category: "LaunchArguments")

    /// `-intensity <level>`, case-insensitive. Missing or unknown values fall back to `Intensity.standard`.
    public static func intensity(from arguments: [String]) -> Intensity {
        guard let flagIndex = arguments.firstIndex(of: "-intensity") else { return .standard }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else {
            logger.warning("-intensity has no value; using the default level.")
            return .standard
        }
        let value = arguments[valueIndex].lowercased()
        guard let level = Intensity(rawValue: value) else {
            logger.warning("Unknown -intensity value '\(value, privacy: .public)'; using the default level.")
            return .standard
        }
        return level
    }

    /// `-showEvaluationBadges` turns on the "body runs" badges.
    public static func showsEvaluationBadges(from arguments: [String]) -> Bool {
        arguments.contains("-showEvaluationBadges")
    }
}
```

`DashboardKit/Sources/DashboardKit/Settings/DemoSettings.swift`:

```swift
import Foundation
import Observation

/// The demo's user-adjustable settings, shared by the Settings menu, the HUD, and the data loader.
@MainActor
@Observable
public final class DemoSettings {
    public var intensity: Intensity
    public var showsEvaluationBadges: Bool

    public init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        intensity = LaunchArguments.intensity(from: arguments)
        showsEvaluationBadges = LaunchArguments.showsEvaluationBadges(from: arguments)
    }
}
```

`DashboardKit/Sources/DashboardKit/Data/TransactionStore.swift`:

```swift
import Observation

/// Owns the generated transactions. Generation runs off the main actor; only the latest request is applied.
@MainActor
@Observable
public final class TransactionStore {
    public private(set) var transactions: [AccountTransaction] = []
    public private(set) var loadedIntensity: Intensity?
    public private(set) var isLoading = false

    @ObservationIgnored private var latestRequest = 0
    private let seed: UInt64

    public init(seed: UInt64 = SampleDataGenerator.defaultSeed) {
        self.seed = seed
    }

    /// Generates data for `intensity`. A newer call, including one for the level already loaded, supersedes older ones.
    public func load(_ intensity: Intensity) async {
        latestRequest += 1
        let request = latestRequest
        guard loadedIntensity != intensity else {
            isLoading = false
            return
        }
        isLoading = true
        let generated = await SampleDataGenerator.transactions(count: intensity.transactionCount, seed: seed)
        guard request == latestRequest, !Task.isCancelled else { return }
        transactions = generated
        loadedIntensity = intensity
        isLoading = false
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `swift test --package-path DashboardKit --filter "IntensityTests|DemoSettingsTests|TransactionStoreTests"`
Expected: PASS (11 test cases).

- [ ] **Step 5: Run the whole suite, lint, and commit**

Run: `swift test --package-path DashboardKit` → all tests pass.
Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add intensity levels, launch arguments, settings, and transaction store

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Frame statistics and the evaluation counter

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/Duration+Conversions.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/FrameStats.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/EvaluationCounter.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/FrameStatsTests.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/EvaluationCounterTests.swift`

**Interfaces:**
- Consumes (Task 1): `DashboardSection`.
- Produces:
  - `extension Duration { var inSeconds: Double; var inMilliseconds: Double }`
  - `struct FrameStats: Sendable, Equatable { static let hitchThreshold: Double; static let pauseThreshold: Duration; private(set) var hitchCount: Int; private(set) var worstFrame: Duration; var expectedInterval: Duration?; var framesPerSecond: Double; mutating func record(frameAt timestamp: Duration); mutating func reset() }`
  - `@MainActor final class EvaluationCounter { static let shared; init(); @discardableResult func record(_ section: DashboardSection) -> Int; func count(for: DashboardSection) -> Int; func reset() }`

- [ ] **Step 1: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/FrameStatsTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite struct FrameStatsTests {
    let frame120: Duration = .nanoseconds(8_333_333)
    let frame60: Duration = .nanoseconds(16_666_667)

    /// Feeds one frame at t = 0 and then one frame after each interval.
    func feed(_ intervals: [Duration]) -> FrameStats {
        var stats = FrameStats()
        var now = Duration.zero
        stats.record(frameAt: now)
        for interval in intervals {
            now += interval
            stats.record(frameAt: now)
        }
        return stats
    }

    @Test func steady120HzHasNoHitches() {
        let stats = feed(Array(repeating: frame120, count: 240))
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == frame120)
        #expect(abs(stats.framesPerSecond - 120) < 0.1)
    }

    @Test func one25msFrameAt120HzIsOneHitch() {
        let steady = Array(repeating: frame120, count: 60)
        let stats = feed(steady + [.milliseconds(25)] + steady)
        #expect(stats.hitchCount == 1)
        #expect(stats.worstFrame == .milliseconds(25))
    }

    @Test func the60HzBaselineAdaptsSoOnlyLongerFramesAreHitches() {
        let steady = Array(repeating: frame60, count: 120)
        #expect(feed(steady).hitchCount == 0)
        #expect(abs(feed(steady).framesPerSecond - 60) < 0.1)
        #expect(feed(steady + [.milliseconds(25)]).hitchCount == 0)
        #expect(feed(steady + [.milliseconds(40)]).hitchCount == 1)
    }

    @Test func aPauseLongerThanOneSecondIsNotAHitch() {
        let steady = Array(repeating: frame120, count: 60)
        let stats = feed(steady + [.seconds(3)] + steady)
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == frame120)
    }

    @Test func repeatedOrEarlierTimestampsAreIgnored() {
        var stats = FrameStats()
        stats.record(frameAt: .zero)
        stats.record(frameAt: frame120)
        stats.record(frameAt: frame120)
        stats.record(frameAt: .nanoseconds(1))
        stats.record(frameAt: frame120 * 2)
        #expect(stats.expectedInterval == frame120)
        #expect(stats.hitchCount == 0)
    }

    @Test func resetClearsEverything() {
        var stats = feed(Array(repeating: frame120, count: 10) + [.milliseconds(50)])
        stats.reset()
        #expect(stats == FrameStats())
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == .zero)
        #expect(stats.framesPerSecond == 0)
    }

    @Test func durationConvertsToMilliseconds() {
        #expect(Duration.milliseconds(25).inMilliseconds == 25)
        #expect(Duration.seconds(1.5).inSeconds == 1.5)
    }
}
```

`DashboardKit/Tests/DashboardKitTests/EvaluationCounterTests.swift`:

```swift
import Testing
@testable import DashboardKit

@Suite @MainActor struct EvaluationCounterTests {
    @Test func recordReturnsTheIncrementedCount() {
        let counter = EvaluationCounter()
        #expect(counter.record(.budget) == 1)
        #expect(counter.record(.budget) == 2)
        #expect(counter.count(for: .budget) == 2)
    }

    @Test func sectionsAreCountedIndependently() {
        let counter = EvaluationCounter()
        counter.record(.budget)
        counter.record(.budget)
        counter.record(.chart)
        #expect(counter.count(for: .budget) == 2)
        #expect(counter.count(for: .chart) == 1)
        #expect(counter.count(for: .summary) == 0)
    }

    @Test func resetClearsAllCounts() {
        let counter = EvaluationCounter()
        counter.record(.categories)
        counter.reset()
        #expect(counter.count(for: .categories) == 0)
        #expect(counter.record(.categories) == 1)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `swift test --package-path DashboardKit --filter "FrameStatsTests|EvaluationCounterTests"`
Expected: build failure: `cannot find 'FrameStats' in scope`, `cannot find 'EvaluationCounter' in scope`.

- [ ] **Step 3: Implement**

`DashboardKit/Sources/DashboardKit/Diagnostics/Duration+Conversions.swift`:

```swift
extension Duration {
    public var inSeconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    public var inMilliseconds: Double {
        inSeconds * 1_000
    }
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/FrameStats.swift`:

```swift
/// Frame-pacing statistics for the HUD. Feed it one timestamp per rendered frame.
///
/// The expected frame interval is the shortest interval in a rolling window, so the same logic works at 60 Hz and 120 Hz.
/// A frame is a hitch when it takes more than `hitchThreshold` × the expected interval.
public struct FrameStats: Sendable, Equatable {
    public static let hitchThreshold = 1.5
    /// Gaps longer than this (app in the background, HUD off screen) are pauses, not hitches.
    public static let pauseThreshold: Duration = .seconds(1)
    static let windowSize = 120

    public private(set) var hitchCount = 0
    public private(set) var worstFrame: Duration = .zero
    private var lastTimestamp: Duration?
    private var recentIntervals: [Duration] = []

    public init() {}

    public var expectedInterval: Duration? { recentIntervals.min() }

    public var framesPerSecond: Double {
        let total = recentIntervals.reduce(Duration.zero, +)
        guard total > .zero else { return 0 }
        return Double(recentIntervals.count) / total.inSeconds
    }

    public mutating func record(frameAt timestamp: Duration) {
        guard let last = lastTimestamp else {
            lastTimestamp = timestamp
            return
        }
        let interval = timestamp - last
        // Same or earlier timestamp: an off-cycle re-render of the same frame. Ignore it.
        guard interval > .zero else { return }
        lastTimestamp = timestamp
        guard interval <= Self.pauseThreshold else { return }
        if let expected = expectedInterval, interval > expected * Self.hitchThreshold {
            hitchCount += 1
        }
        worstFrame = max(worstFrame, interval)
        recentIntervals.append(interval)
        if recentIntervals.count > Self.windowSize {
            recentIntervals.removeFirst()
        }
    }

    public mutating func reset() {
        self = FrameStats()
    }
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/EvaluationCounter.swift`:

```swift
/// Counts how many times each dashboard section's body has run.
///
/// Deliberately *not* `@Observable`, and reached through `shared` rather than the environment: section bodies write to
/// it while they're being evaluated, and that write must never trigger another evaluation.
@MainActor
public final class EvaluationCounter {
    public static let shared = EvaluationCounter()

    private var counts: [DashboardSection: Int] = [:]

    public init() {}

    /// Records one body evaluation and returns the section's new count.
    @discardableResult
    public func record(_ section: DashboardSection) -> Int {
        counts[section, default: 0] += 1
        return counts[section, default: 0]
    }

    public func count(for section: DashboardSection) -> Int {
        counts[section, default: 0]
    }

    public func reset() {
        counts.removeAll()
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `swift test --package-path DashboardKit --filter "FrameStatsTests|EvaluationCounterTests"`
Expected: PASS (10 tests).

- [ ] **Step 5: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add frame statistics and section evaluation counter

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Shared UI — badge, HUD, settings menu, and DemoShell

Invoke the `swiftui-specialist` skill before writing this task's views (AGENTS.md requirement).

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/EnvironmentValues+EvaluationBadges.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/EvaluationBadge.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/DeviceModel.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/MainThreadStall.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/FrameRecorder.swift`
- Create: `DashboardKit/Sources/DashboardKit/Diagnostics/FrameMeterView.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/AppVariant.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/View+DashboardCard.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/SettingsMenu.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/DemoShell.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/DiagnosticsDefaultsTests.swift`

**Interfaces:**
- Consumes: `DemoSettings`, `TransactionStore`, `Intensity` (Task 4); `FrameStats`, `EvaluationCounter`, `Duration.inMilliseconds` (Task 5); `DemoClock`, `AccountTransaction` (Task 1).
- Produces (used by the app targets in Tasks 7–9):
  - `EnvironmentValues.showsEvaluationBadges: Bool` (`@Entry`, default `false`)
  - `struct EvaluationBadge: View { init(count: Int) }`
  - `extension View { func dashboardCard() -> some View }`
  - `enum AppVariant: Sendable { computed, structs; title; tint }`
  - `struct DemoShell<Dashboard: View>: View { init(variant: AppVariant, @ViewBuilder dashboard: @escaping ([AccountTransaction], Int) -> Dashboard) }`. The closure receives the transactions and the Recent-list row limit.
  - `enum DeviceModel { static let identifier: String }`

- [ ] **Step 1: Write the failing defaults test**

`DashboardKit/Tests/DashboardKitTests/DiagnosticsDefaultsTests.swift`:

```swift
import SwiftUI
import Testing
@testable import DashboardKit

@Suite @MainActor struct DiagnosticsDefaultsTests {
    @Test func badgesAreOffByDefault() {
        #expect(EnvironmentValues().showsEvaluationBadges == false)
    }

    @Test func deviceModelIdentifierIsNotEmpty() {
        #expect(!DeviceModel.identifier.isEmpty)
    }
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `swift test --package-path DashboardKit --filter DiagnosticsDefaultsTests`
Expected: build failure: `value of type 'EnvironmentValues' has no member 'showsEvaluationBadges'`, `cannot find 'DeviceModel' in scope`.

- [ ] **Step 3: Implement the environment flag, badge, and device model**

`DashboardKit/Sources/DashboardKit/Diagnostics/EnvironmentValues+EvaluationBadges.swift`:

```swift
import SwiftUI

extension EnvironmentValues {
    /// Whether sections show their "body runs" badge. Off by default; keep it off for Instruments runs.
    @Entry public var showsEvaluationBadges = false
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/EvaluationBadge.swift`:

```swift
import SwiftUI

/// Shows how many times the enclosing section's body has run. The section records the count itself (see
/// `EvaluationCounter`) and hands it in, so the number only changes when that section's body actually runs.
public struct EvaluationBadge: View {
    private let count: Int
    @Environment(\.showsEvaluationBadges) private var isVisible

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        if isVisible {
            Text("body runs: \(count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.black)
                .padding(.horizontal)
                .background(.yellow, in: .capsule)
                .accessibilityLabel("Section body evaluated \(count) times")
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/DeviceModel.swift`:

```swift
import Foundation

/// The hardware model identifier (for example `iPhone18,1`), shown on the HUD so every capture documents its device.
public enum DeviceModel {
    public static let identifier: String = {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var buffer = [UInt8](repeating: 0, count: size)
        sysctlbyname("hw.machine", &buffer, &size, nil, 0)
        return String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
    }()
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `swift test --package-path DashboardKit --filter DiagnosticsDefaultsTests`
Expected: PASS (2 tests).

- [ ] **Step 5: Implement the HUD pieces**

`DashboardKit/Sources/DashboardKit/Diagnostics/MainThreadStall.swift`:

```swift
/// Deliberately blocks the main thread. Used by "Simulate a 100 ms stall" to prove the HUD detects a known hitch.
enum MainThreadStall {
    @MainActor
    static func run(for duration: Duration) {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: duration)
        while clock.now < deadline {
            // Busy-wait on purpose: this simulates expensive main-thread work.
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/FrameRecorder.swift`:

```swift
import Foundation

/// Holds the HUD's `FrameStats`. A plain class (not `@Observable`), so recording a frame from inside the HUD's
/// body never schedules another update.
@MainActor
final class FrameRecorder {
    private var stats = FrameStats()

    /// Records the frame whose timeline date is `date` and returns the updated statistics.
    func record(frameAt date: Date) -> FrameStats {
        stats.record(frameAt: .seconds(date.timeIntervalSinceReferenceDate))
        return stats
    }

    func reset() {
        stats.reset()
    }
}
```

`DashboardKit/Sources/DashboardKit/Diagnostics/FrameMeterView.swift`:

```swift
import SwiftUI

/// The heads-up display pinned above the dashboard: which app this is, the intensity, the device, and live frame pacing.
/// It's its own view with its own state, so updating it every frame never invalidates the dashboard.
struct FrameMeterView: View {
    let variant: AppVariant
    let intensity: Intensity

    @State private var recorder = FrameRecorder()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let stats = recorder.record(frameAt: context.date)
            VStack(alignment: .leading) {
                HStack {
                    Text(variant.title)
                        .bold()
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                        .background(variant.tint, in: .capsule)
                    Spacer()
                    Text(intensity.title)
                    Text(DeviceModel.identifier)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("FPS \(stats.framesPerSecond, format: .number.precision(.fractionLength(0)))")
                    Text("Hitches \(stats.hitchCount)")
                    Text("Worst \(stats.worstFrame.inMilliseconds, format: .number.precision(.fractionLength(1))) ms")
                    Spacer()
                    Button("Reset frame stats", systemImage: "arrow.counterclockwise") {
                        recorder.reset()
                    }
                    .labelStyle(.iconOnly)
                }
                if !reduceMotion {
                    // The heartbeat: sweeps every 2 seconds and visibly stutters whenever the main thread misses frames.
                    ProgressView(value: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2), total: 2)
                        .accessibilityHidden(true)
                }
            }
            .font(.caption.monospacedDigit())
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}
```

- [ ] **Step 6: Implement the shell**

`DashboardKit/Sources/DashboardKit/Shell/AppVariant.swift`:

```swift
import SwiftUI

/// Which of the two demo apps is running. Shown on the HUD so every video frame identifies itself.
public enum AppVariant: Sendable {
    case computed, structs

    public var title: LocalizedStringResource {
        switch self {
        case .computed: "Computed properties"
        case .structs: "View structs"
        }
    }

    /// Badge fill. The badge's text is black, which contrasts well with both colors.
    public var tint: Color {
        switch self {
        case .computed: .orange
        case .structs: .green
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Shell/View+DashboardCard.swift`:

```swift
import SwiftUI

extension View {
    /// The card chrome every dashboard section uses. A plain function, not a view type, so it adds no invalidation boundary.
    public func dashboardCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}
```

`DashboardKit/Sources/DashboardKit/Shell/SettingsMenu.swift`:

```swift
import SwiftUI

/// The toolbar menu: intensity, re-evaluation badges, counter reset, and the known-stall check for the HUD.
struct SettingsMenu: View {
    @Bindable var settings: DemoSettings

    var body: some View {
        Menu("Demo settings", systemImage: "gearshape") {
            Picker("Intensity", selection: $settings.intensity) {
                ForEach(Intensity.allCases) { level in
                    Text(level.title)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            Toggle("Show re-evaluations", isOn: $settings.showsEvaluationBadges)
            Button("Reset body-run counts", systemImage: "arrow.counterclockwise") {
                EvaluationCounter.shared.reset()
            }
            Button("Simulate a 100 ms stall", systemImage: "tortoise") {
                MainThreadStall.run(for: .milliseconds(100))
            }
        }
    }
}
```

`DashboardKit/Sources/DashboardKit/Shell/DemoShell.swift`:

```swift
import SwiftUI

/// The shared root of both demo apps: navigation, the settings menu, the frame-meter HUD, and data loading.
/// Each app passes in only its own `DashboardView`.
public struct DemoShell<Dashboard: View>: View {
    private let variant: AppVariant
    private let dashboard: ([AccountTransaction], Int) -> Dashboard

    @State private var settings = DemoSettings()
    @State private var store = TransactionStore()

    /// - Parameter dashboard: Builds the dashboard from the transactions and the Recent-list row limit.
    public init(variant: AppVariant, @ViewBuilder dashboard: @escaping ([AccountTransaction], Int) -> Dashboard) {
        self.variant = variant
        self.dashboard = dashboard
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let intensity = store.loadedIntensity, !store.isLoading {
                    dashboard(store.transactions, intensity.recentRowLimit)
                } else {
                    ProgressView("Generating transactions…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .safeAreaInset(edge: .top) {
                FrameMeterView(variant: variant, intensity: settings.intensity)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SettingsMenu(settings: settings)
                }
            }
        }
        .environment(\.showsEvaluationBadges, settings.showsEvaluationBadges)
        .environment(\.calendar, DemoClock.calendar)
        .environment(\.timeZone, DemoClock.calendar.timeZone)
        .task(id: settings.intensity) {
            await store.load(settings.intensity)
        }
    }
}
```

- [ ] **Step 7: Build, test, lint**

Run: `swift build --package-path DashboardKit`
Expected: `Build complete!` with no warnings from DashboardKit sources.
Run: `swift test --package-path DashboardKit` → all tests pass.
Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

If `swift build` fails only because a SwiftUI API is unavailable on macOS, wrap that single modifier in `#if os(iOS)` … `#endif` with a comment saying macOS is only there for `swift test`. Don't change the iOS behavior.

- [ ] **Step 8: Commit**

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add shared demo shell, frame-meter HUD, and evaluation badges

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 7: Xcode project with two app targets linked to DashboardKit

This task uses the Xcode MCP tools (load them with ToolSearch: `select:mcp__xcode__XcodeNewProject,mcp__xcode__XcodeOpenWorkspace,mcp__xcode__XcodeNewTarget,mcp__xcode__UpdateTargetBuildSetting,mcp__xcode__GetTargetBuildSettings,mcp__xcode__XcodeListTargets`). **Step 6 is a manual step for the user.** Stop and ask them to do it, then wait.

**Files:**
- Create: `ComputedPropertiesView.xcodeproj` (generated by Xcode)
- Create: `ComputedDashboard/ComputedDashboardApp.swift`, `ComputedDashboard/DashboardView.swift` (placeholder, replaced in Task 8), `ComputedDashboard/Assets.xcassets` (template)
- Create: `StructDashboard/StructDashboardApp.swift`, `StructDashboard/DashboardView.swift` (placeholder, replaced in Task 9), `StructDashboard/Assets.xcassets` (template)
- Delete: the template's `ContentView.swift` in both app folders

**Interfaces:**
- Consumes (Task 6): `DemoShell(variant:dashboard:)`, `AppVariant`, `AccountTransaction`.
- Produces: schemes `ComputedDashboard` and `StructDashboard`. Each app has `struct DashboardView: View { let transactions: [AccountTransaction]; let rowLimit: Int }`.

- [ ] **Step 1: Create the project from the App template in a temporary folder**

Call `mcp__xcode__XcodeNewProject` with:
- `templateIdentifier`: `com.apple.dt.unit.multiPlatform.app`
- `productName`: `ComputedDashboard`
- `destinationPath`: an empty temporary folder, e.g. `$TMPDIR/xcode-scaffold` (create it with `mkdir -p` first and pass the absolute path)
- `organizationIdentifier`: `com.hotngui`
- `options`: `{"storageType": "None", "testingSystem": "None", "hostInCloudKit": "false"}`

Expected: `<tmp>/xcode-scaffold/ComputedDashboard/ComputedDashboard.xcodeproj` and a `ComputedDashboard/` source folder next to it.

- [ ] **Step 2: Move it into the repo and name the project file after the repo**

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
SCAFFOLD="$TMPDIR/xcode-scaffold/ComputedDashboard"
mv "$SCAFFOLD/ComputedDashboard.xcodeproj" ./ComputedPropertiesView.xcodeproj
mv "$SCAFFOLD/ComputedDashboard" ./ComputedDashboard
grep -rl "ComputedDashboard.xcodeproj" ComputedPropertiesView.xcodeproj || echo "no container references to fix"
```

If the `grep` lists any files (shared schemes), replace `container:ComputedDashboard.xcodeproj` with `container:ComputedPropertiesView.xcodeproj` in each one.

- [ ] **Step 3: Open the project and add the second app target**

Call `mcp__xcode__XcodeOpenWorkspace` with the absolute path of `ComputedPropertiesView.xcodeproj`.
Call `mcp__xcode__XcodeNewTarget` with `templateIdentifier` `com.apple.dt.unit.multiPlatform.app`, `productName` `StructDashboard`, `organizationIdentifier` `com.hotngui`, and `options` `{"storageType": "None", "testingSystem": "None", "hostInCloudKit": "false"}`.
Expected: a `StructDashboard/` folder at the repo root and a `StructDashboard` target (confirm with `mcp__xcode__XcodeListTargets`).

- [ ] **Step 4: Apply the build settings to both targets**

For each target (`ComputedDashboard`, `StructDashboard`), call `mcp__xcode__UpdateTargetBuildSetting` once per row:

| Setting | ComputedDashboard | StructDashboard |
|---|---|---|
| `SDKROOT` | `iphoneos` | `iphoneos` |
| `SUPPORTED_PLATFORMS` | `iphoneos iphonesimulator` | `iphoneos iphonesimulator` |
| `SUPPORTS_MACCATALYST` | `NO` | `NO` |
| `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` | `NO` | `NO` |
| `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` | `NO` | `NO` |
| `TARGETED_DEVICE_FAMILY` | `1` | `1` |
| `IPHONEOS_DEPLOYMENT_TARGET` | `27.0` | `27.0` |
| `SWIFT_VERSION` | `6.0` | `6.0` |
| `SWIFT_STRICT_CONCURRENCY` | `complete` | `complete` |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | `YES` |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | `MainActor` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.hotngui.ComputedDashboard` | `com.hotngui.StructDashboard` |
| `INFOPLIST_KEY_CFBundleDisplayName` | `Computed` | `Structs` |

Verify with `mcp__xcode__GetTargetBuildSettings` for each target that `IPHONEOS_DEPLOYMENT_TARGET`, `SUPPORTED_PLATFORMS`, and `PRODUCT_BUNDLE_IDENTIFIER` have the values above.

- [ ] **Step 5: Replace the template sources**

```bash
rm ComputedDashboard/ContentView.swift StructDashboard/ContentView.swift
```

Overwrite `ComputedDashboard/ComputedDashboardApp.swift`:

```swift
import DashboardKit
import SwiftUI

@main
struct ComputedDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .computed) { transactions, rowLimit in
                DashboardView(transactions: transactions, rowLimit: rowLimit)
            }
        }
    }
}
```

Overwrite `StructDashboard/StructDashboardApp.swift`:

```swift
import DashboardKit
import SwiftUI

@main
struct StructDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .structs) { transactions, rowLimit in
                DashboardView(transactions: transactions, rowLimit: rowLimit)
            }
        }
    }
}
```

Create `ComputedDashboard/DashboardView.swift` and `StructDashboard/DashboardView.swift` with the same temporary placeholder (Tasks 8 and 9 replace them):

```swift
import DashboardKit
import SwiftUI

struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    var body: some View {
        Text("\(transactions.count) transactions")
    }
}
```

- [ ] **Step 6: MANUAL (user): link the local package to both targets**

No available tool adds a local package reference, so ask the user to do this in Xcode, then wait for them to confirm:

1. With `ComputedPropertiesView.xcodeproj` open, choose **File ▸ Add Package Dependencies…**
2. Click **Add Local…**, select the `DashboardKit` folder in the repo, and click **Add Package**.
3. In the "Add to Target" column for the `DashboardKit` library, choose **ComputedDashboard**, then click **Add Package**.
4. Select the project in the navigator ▸ **StructDashboard** target ▸ **General** ▸ **Frameworks, Libraries, and Embedded Content** ▸ **+** ▸ choose **DashboardKit** ▸ **Add**.

- [ ] **Step 7: Build both apps**

```bash
SIM=B9BB0E3F-E390-472F-AD17-952DA5298A94
for scheme in ComputedDashboard StructDashboard; do
  xcodebuild -project ComputedPropertiesView.xcodeproj -scheme "$scheme" -destination "id=$SIM" \
    -derivedDataPath build/DerivedData build -quiet || exit 1
done
echo BOTH-BUILT
```

Expected: `BOTH-BUILT` with no errors. If a scheme isn't found, run `xcodebuild -list -project ComputedPropertiesView.xcodeproj` and use the listed names.

- [ ] **Step 8: Launch each app and look at it**

Use the `device-interaction` skill (or `xcrun simctl install "$SIM" build/DerivedData/Build/Products/Debug-iphonesimulator/<App>.app` plus `xcrun simctl launch "$SIM" com.hotngui.<App> -intensity light`) to launch each app on `$SIM` and take a screenshot.
Expected in both: the HUD at the top (orange **Computed properties** or green **View structs**, "Light", the simulator's model identifier, and FPS near the display rate), the gear menu in the toolbar, and the text `1,000 transactions`.

- [ ] **Step 9: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add ComputedPropertiesView.xcodeproj ComputedDashboard StructDashboard
git status --short   # xcuserdata must not appear (ignored by .gitignore)
git commit -F - <<'EOF'
feat: add Xcode project with Computed and Structs app targets

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 8: The Computed app's dashboard (computed-property sections)

Invoke the `swiftui-specialist` skill before writing this view (AGENTS.md requirement). The computed-property sections are the intended anti-pattern; don't "fix" them.

**Files:**
- Modify (replace entirely): `ComputedDashboard/DashboardView.swift`

**Interfaces:**
- Consumes: `AccountTransaction`, `TimeRange`, `TransactionCategory` (+ `color`, `name`, `systemImage`, `title`), `DemoClock`, `TransactionMath` (all functions), `EvaluationCounter.shared.record(_:)`, `EvaluationBadge(count:)`, `dashboardCard()`.
- Produces: six section bodies between `// BEGIN SECTION BODY: <name>` and `// END SECTION BODY: <name>` markers, using the names `summary`, `timeRange`, `budget`, `chart`, `categories`, `transactions`. Task 9 copies these blocks mechanically. The bodies reference only `transactions`, `rowLimit`, `timeRange`/`$timeRange`, `budget`/`$budget`, `hideBalances`, and `showPendingOnly`/`$showPendingOnly`.

- [ ] **Step 1: Write the dashboard**

`ComputedDashboard/DashboardView.swift`:

```swift
//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//
//  This dashboard builds its six sections as `some View` computed properties. A computed property is inlined into
//  `body`, so it shares the dashboard's invalidation boundary: any change to the four `@State` values below re-runs all
//  six sections, including expensive ones that never read the changed value. The sibling app (StructDashboard) is
//  identical except each section is its own `View` struct.
//
//  Section bodies sit between `BEGIN/END SECTION BODY` markers and must stay textually identical to the struct app's.
//  Run `Scripts/check-section-parity.sh` after editing either copy.

import Charts
import DashboardKit
import SwiftUI

struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    @State private var budget = 2_000.0
    @State private var hideBalances = false
    @State private var showPendingOnly = false
    @State private var timeRange = TimeRange.month

    var body: some View {
        ScrollView {
            VStack {
                accountSummary
                timeRangePicker
                budgetCard
                spendingChart
                categoryBreakdown
                recentTransactions
            }
            .padding()
        }
    }

    // MARK: - Sections (computed properties: the anti-pattern under test)

    @ViewBuilder
    private var accountSummary: some View {
        // BEGIN SECTION BODY: summary
        let evaluationCount = EvaluationCounter.shared.record(.summary)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        VStack(alignment: .leading) {
            HStack {
                Text("Account summary")
                    .font(.headline)
                Spacer()
                Button("Toggle balance visibility", systemImage: hideBalances ? "eye.slash" : "eye") {
                    hideBalances.toggle()
                }
                .labelStyle(.iconOnly)
            }
            Text(TransactionMath.net(of: inRange), format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .redacted(reason: hideBalances ? .placeholder : [])
            LabeledContent("Income") {
                Text(TransactionMath.income(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            LabeledContent("Spent") {
                Text(TransactionMath.expenses(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: summary
    }

    @ViewBuilder
    private var timeRangePicker: some View {
        // BEGIN SECTION BODY: timeRange
        let evaluationCount = EvaluationCounter.shared.record(.timeRange)
        VStack(alignment: .leading) {
            Picker("Time range", selection: $timeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: timeRange
    }

    @ViewBuilder
    private var budgetCard: some View {
        // BEGIN SECTION BODY: budget
        let evaluationCount = EvaluationCounter.shared.record(.budget)
        let spent = TransactionMath.expenses(of: TransactionMath.transactions(transactions, in: timeRange.dateRange()))
        let ceiling = TransactionMath.budgetCeiling(forSpent: spent)
        VStack(alignment: .leading) {
            Text("Budget")
                .font(.headline)
            Gauge(value: TransactionMath.budgetUsage(spent: spent, budget: budget)) {
                Text("Spent of budget")
            } currentValueLabel: {
                Text(spent, format: .currency(code: "USD"))
            }
            if spent > Decimal(budget) {
                Label("Over budget", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .bold()
            }
            Slider(value: $budget, in: 0...ceiling) {
                Text("Budget")
            }
            .accessibilityValue(Text(budget, format: .currency(code: "USD")))
            Text("Budget: \(budget, format: .currency(code: "USD").precision(.fractionLength(0)))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: budget
    }

    @ViewBuilder
    private var spendingChart: some View {
        // BEGIN SECTION BODY: chart
        let evaluationCount = EvaluationCounter.shared.record(.chart)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let dailyTotals = TransactionMath.dailyTotals(of: inRange, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Spending by day")
                .font(.headline)
            Chart(dailyTotals) { dailyTotal in
                BarMark(x: .value("Day", dailyTotal.day, unit: .day), y: .value("Spent", dailyTotal.amount))
                    .foregroundStyle(by: .value("Category", dailyTotal.category.name))
            }
            .chartForegroundStyleScale(
                domain: TransactionCategory.spending.map(\.name), range: TransactionCategory.spending.map(\.color)
            )
            .frame(minHeight: 220)
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: chart
    }

    @ViewBuilder
    private var categoryBreakdown: some View {
        // BEGIN SECTION BODY: categories
        let evaluationCount = EvaluationCounter.shared.record(.categories)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let categoryTotals = TransactionMath.categoryTotals(of: inRange)
        VStack(alignment: .leading) {
            Text("Where it went")
                .font(.headline)
            if categoryTotals.isEmpty {
                Text("No spending in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(categoryTotals) { categoryTotal in
                VStack(alignment: .leading) {
                    LabeledContent {
                        Text(categoryTotal.total, format: .currency(code: "USD"))
                    } label: {
                        Label {
                            Text(categoryTotal.category.title)
                        } icon: {
                            Image(systemName: categoryTotal.category.systemImage)
                        }
                    }
                    ProgressView(value: categoryTotal.share)
                        .tint(categoryTotal.category.color)
                        .accessibilityValue(Text(categoryTotal.share, format: .percent.precision(.fractionLength(1))))
                }
            }
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categories
    }

    @ViewBuilder
    private var recentTransactions: some View {
        // BEGIN SECTION BODY: transactions
        let evaluationCount = EvaluationCounter.shared.record(.transactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let filtered = showPendingOnly ? TransactionMath.pendingOnly(inRange) : inRange
        let rows = TransactionMath.newestFirst(filtered, limit: rowLimit)
        VStack(alignment: .leading) {
            Text("Recent transactions")
                .font(.headline)
            Toggle("Pending only", isOn: $showPendingOnly)
            if rows.isEmpty {
                Text("No transactions in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(rows) { transaction in
                HStack {
                    Image(systemName: transaction.category.systemImage)
                        .foregroundStyle(transaction.category.color)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(transaction.merchant)
                        Text(transaction.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(transaction.amount, format: .currency(code: "USD").sign(strategy: .always()))
                        if transaction.isPending {
                            Label("Pending", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
            EvaluationBadge(count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: transactions
    }
}
```

- [ ] **Step 2: Check the markers**

Run: `grep -c "SECTION BODY:" ComputedDashboard/DashboardView.swift`
Expected: `12` (six BEGIN, six END).

- [ ] **Step 3: Build**

Run: `xcodebuild -project ComputedPropertiesView.xcodeproj -scheme ComputedDashboard -destination "id=B9BB0E3F-E390-472F-AD17-952DA5298A94" -derivedDataPath build/DerivedData build -quiet`
Expected: success with no warnings in `DashboardView.swift`.

If the compiler rejects `.sign(strategy: .always())`, use `.sign(strategy: .always(includingZero: false))`. If it can't infer the `Gauge` or `Slider` label closures, add explicit `Text` labels as written. Don't restructure the sections.

- [ ] **Step 4: Lint**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml`
Expected: `Found 0 violations`. If, and only if, `type_body_length` fires on `DashboardView`, add these two lines directly above `struct DashboardView: View {` and re-run lint:

```swift
// The six computed-property sections are the anti-pattern under test, so this type is long on purpose.
// swiftlint:disable:next type_body_length
```

- [ ] **Step 5: Run it and look**

Launch on `$SIM` with arguments `-intensity light -showEvaluationBadges` (via the `device-interaction` skill) and take a screenshot.
Expected: all six cards render (summary with net/income/spent, segmented picker, budget gauge + slider, stacked bar chart with a category legend, category bars, recent rows), each with a yellow "body runs: N" badge. Drag the budget slider once and take another screenshot: **every** badge's count has gone up.

- [ ] **Step 6: Commit**

```bash
git add ComputedDashboard/DashboardView.swift
git commit -F - <<'EOF'
feat: build Computed app dashboard from computed-property sections

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 9: The Structs app's dashboard and the section-parity check

Invoke the `swiftui-specialist` skill before writing these views (AGENTS.md requirement).

**Files:**
- Create: `Scripts/check-section-parity.sh`
- Create: `StructDashboard/Sections/AccountSummarySection.swift`, `TimeRangeSection.swift`, `BudgetSection.swift`, `SpendingChartSection.swift`, `CategoryBreakdownSection.swift`, `RecentTransactionsSection.swift`
- Modify (replace entirely): `StructDashboard/DashboardView.swift`

**Interfaces:**
- Consumes (Task 8): the six marker blocks in `ComputedDashboard/DashboardView.swift`.
- Produces: `AccountSummarySection(transactions:timeRange:hideBalances:)`, `TimeRangeSection(timeRange:)`, `BudgetSection(transactions:timeRange:budget:)`, `SpendingChartSection(transactions:timeRange:)`, `CategoryBreakdownSection(transactions:timeRange:)`, `RecentTransactionsSection(transactions:timeRange:rowLimit:showPendingOnly:)`. Parameters named `hideBalances`, `timeRange`, `budget`, and `showPendingOnly` are `@Binding`s where they appear.

- [ ] **Step 1: Write the parity script**

`Scripts/check-section-parity.sh`:

```bash
#!/bin/bash
# Verifies that every dashboard section body is textually identical in both apps.
# Bodies sit between "// BEGIN SECTION BODY: <name>" and "// END SECTION BODY: <name>" marker lines.
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "$0")/.." && pwd)"
computed="$root/ComputedDashboard/DashboardView.swift"
structs=("$root"/StructDashboard/Sections/*.swift)
sections=(summary timeRange budget chart categories transactions)

[[ -f "$computed" ]] || { echo "✗ missing $computed"; exit 1; }
(( ${#structs[@]} > 0 )) || { echo "✗ no section files in StructDashboard/Sections"; exit 1; }

extract() {
    local section="$1"
    shift
    sed -n "/BEGIN SECTION BODY: ${section}\$/,/END SECTION BODY: ${section}\$/p" "$@"
}

status=0
for section in "${sections[@]}"; do
    left="$(extract "$section" "$computed")"
    right="$(extract "$section" "${structs[@]}")"
    if [[ -z "$left" || -z "$right" ]]; then
        echo "✗ $section: marker block missing (computed: ${#left} chars, structs: ${#right} chars)"
        status=1
    elif [[ "$left" != "$right" ]]; then
        echo "✗ $section: bodies differ"
        diff <(echo "$left") <(echo "$right") || true
        status=1
    else
        echo "✓ $section"
    fi
done
exit "$status"
```

Run: `chmod +x Scripts/check-section-parity.sh && Scripts/check-section-parity.sh`
Expected: FAIL with `✗ no section files in StructDashboard/Sections` (exit 1).

- [ ] **Step 2: Generate the six section structs by copying the marker blocks verbatim**

Run this whole block in one shell. It copies each body from the Computed app, so the text is identical by construction.

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
mkdir -p StructDashboard/Sections
body() { sed -n "/BEGIN SECTION BODY: $1\$/,/END SECTION BODY: $1\$/p" ComputedDashboard/DashboardView.swift; }
footer() { printf '    }\n}\n'; }

{ cat <<'EOF'
import DashboardKit
import SwiftUI

/// Net, income, and spending for the selected range, plus the button that hides the amounts.
struct AccountSummarySection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    @Binding var hideBalances: Bool

    var body: some View {
EOF
body summary; footer; } > StructDashboard/Sections/AccountSummarySection.swift

{ cat <<'EOF'
import DashboardKit
import SwiftUI

/// The Week / Month / Quarter / Year picker.
struct TimeRangeSection: View {
    @Binding var timeRange: TimeRange

    var body: some View {
EOF
body timeRange; footer; } > StructDashboard/Sections/TimeRangeSection.swift

{ cat <<'EOF'
import DashboardKit
import SwiftUI

/// Spending against the budget, with the slider that drives the headline demo.
struct BudgetSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    @Binding var budget: Double

    var body: some View {
EOF
body budget; footer; } > StructDashboard/Sections/BudgetSection.swift

{ cat <<'EOF'
import Charts
import DashboardKit
import SwiftUI

/// Stacked daily spending bars by category.
struct SpendingChartSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
EOF
body chart; footer; } > StructDashboard/Sections/SpendingChartSection.swift

{ cat <<'EOF'
import DashboardKit
import SwiftUI

/// Spending per category, largest first.
struct CategoryBreakdownSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
EOF
body categories; footer; } > StructDashboard/Sections/CategoryBreakdownSection.swift

{ cat <<'EOF'
import DashboardKit
import SwiftUI

/// The newest transactions in the range, optionally only pending ones.
struct RecentTransactionsSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    let rowLimit: Int
    @Binding var showPendingOnly: Bool

    var body: some View {
EOF
body transactions; footer; } > StructDashboard/Sections/RecentTransactionsSection.swift

ls StructDashboard/Sections
```

Expected: the six files listed. Open one (e.g. `BudgetSection.swift`) and confirm it ends with the `// END SECTION BODY: budget` line, then `    }` and `}`.

- [ ] **Step 3: Replace the placeholder parent**

`StructDashboard/DashboardView.swift`:

```swift
import DashboardKit
import SwiftUI

/// The same dashboard as the Computed app, but each section is its own `View` struct with narrow inputs.
///
/// This body only forwards inputs. It never filters or aggregates, so a slider tick changes only `BudgetSection`'s
/// input and SwiftUI skips the other five section bodies.
struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    @State private var budget = 2_000.0
    @State private var hideBalances = false
    @State private var showPendingOnly = false
    @State private var timeRange = TimeRange.month

    var body: some View {
        ScrollView {
            VStack {
                AccountSummarySection(transactions: transactions, timeRange: timeRange, hideBalances: $hideBalances)
                TimeRangeSection(timeRange: $timeRange)
                BudgetSection(transactions: transactions, timeRange: timeRange, budget: $budget)
                SpendingChartSection(transactions: transactions, timeRange: timeRange)
                CategoryBreakdownSection(transactions: transactions, timeRange: timeRange)
                RecentTransactionsSection(
                    transactions: transactions, timeRange: timeRange, rowLimit: rowLimit, showPendingOnly: $showPendingOnly
                )
            }
            .padding()
        }
    }
}
```

- [ ] **Step 4: Run the parity check and confirm it passes**

Run: `Scripts/check-section-parity.sh`
Expected: six `✓` lines, exit 0.

- [ ] **Step 5: Prove the parity check catches drift, then revert**

```bash
sed -i '' 's/Text("Budget")$/Text("Budget!")/' StructDashboard/Sections/BudgetSection.swift
Scripts/check-section-parity.sh; echo "exit: $?"
sed -i '' 's/Text("Budget!")$/Text("Budget")/' StructDashboard/Sections/BudgetSection.swift
Scripts/check-section-parity.sh
```

Expected: the first run prints `✗ budget: bodies differ` with a diff and `exit: 1`. The second run, after the revert, prints six `✓`.

- [ ] **Step 6: Build and lint**

Run: `xcodebuild -project ComputedPropertiesView.xcodeproj -scheme StructDashboard -destination "id=B9BB0E3F-E390-472F-AD17-952DA5298A94" -derivedDataPath build/DerivedData build -quiet` → success.
Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

- [ ] **Step 7: Run it and look**

Launch the Structs app on `$SIM` with `-intensity light -showEvaluationBadges` and take a screenshot. Drag the budget slider once and take another.
Expected: the layout matches the Computed app. After the drag, **only the Budget card's** badge count has increased. Write down all six counts before and after; Task 10 needs them.

- [ ] **Step 8: Commit**

```bash
git add Scripts StructDashboard
git commit -F - <<'EOF'
feat: build Structs app dashboard from section view structs with parity check

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 10: Verification pass — invalidation, HUD, Release builds

**Files:**
- Modify: `Journal.md` (The Journey, Engineer's Wisdom)

**Interfaces:**
- Consumes: both apps, the badges, the HUD, and the "Simulate a 100 ms stall" menu item.
- Produces: recorded evidence (badge counts, stall result) in `Journal.md`.

- [ ] **Step 1: Badge check for every control in both apps**

For each app, launch fresh on `$SIM` with `-intensity light -showEvaluationBadges`. Record all six badge counts after launch and again after each of these actions: drag the slider, tap the eye button, toggle Pending only, pick Week.

Expected:

| Action | Computed app | Structs app |
|---|---|---|
| Drag slider | all six increase | only **budget** increases |
| Eye button | all six increase | only **summary** increases |
| Pending only | all six increase | only **transactions** increases |
| Pick Week | all six increase | summary, timeRange, budget, chart, categories, transactions increase (control case) |

**Stop and report to the user** if any unexpected Structs-app badge increases, for example if every section with a `@Binding` input also re-runs on a slider drag. That's spec risk §8 ("Bindings as inputs"). The fix changes the design, so it's the user's call. Include the measured counts in the report.

- [ ] **Step 2: HUD known-stall check**

In each app: tap the HUD's reset button, wait about 2 seconds, then choose **Demo settings ▸ Simulate a 100 ms stall**.
Expected: **Hitches** goes up by at least 1 and **Worst** reads at least 100 ms. If it doesn't, the `TimelineView(.animation)` dates aren't reflecting the stall. Stop and report to the user; don't swap timing sources without agreement.

- [ ] **Step 3: Release builds**

```bash
SIM=B9BB0E3F-E390-472F-AD17-952DA5298A94
for scheme in ComputedDashboard StructDashboard; do
  xcodebuild -project ComputedPropertiesView.xcodeproj -scheme "$scheme" -configuration Release \
    -destination "id=$SIM" -derivedDataPath build/DerivedData build -quiet || exit 1
done
echo RELEASE-BUILT
```

Expected: `RELEASE-BUILT`.

- [ ] **Step 4: Simulator smoke test at a high intensity**

Launch each Release build with `-intensity heavy`, drag the slider back and forth for about 5 seconds, and screenshot the HUD.
Record the hitch counts for both apps. The simulator's numbers aren't the real measurement (that's the capture protocol on devices), but the Computed app should show more hitches. If it doesn't, note that in the Journal as-is. Don't tune intensities in this task.

- [ ] **Step 5: Full test, lint, and parity pass**

Run: `swift test --package-path DashboardKit` → all pass.
Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.
Run: `Scripts/check-section-parity.sh` → six `✓`.

- [ ] **Step 6: Record the evidence in `Journal.md`**

Append under **The Journey** a dated entry (`### <date>: First light`) that covers:
- the badge table from Step 1 with the measured numbers (the key "aha": identical code, different invalidation boundaries);
- whether the binding-input risk showed up;
- the stall-check result;
- the simulator Heavy hitch counts from Step 4, labeled as simulator-only;
- any build or API surprises from Tasks 6–9 and how they were fixed.

Add one bullet to **Engineer's Wisdom**: "Prove your instrument before trusting it." The stall button checked the HUD against a known 100 ms hitch before we used it to measure anything.

- [ ] **Step 7: Commit**

```bash
git add Journal.md
git commit -F - <<'EOF'
docs: record verification results in the journal

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 11: Capture protocol and final documentation

**Files:**
- Create: `Captures/README.md`
- Create: `Captures/CaptureNotes.md`
- Modify: `CLAUDE.md` (Status section)
- Modify: `Journal.md` (If I Were Starting Over…)

**Interfaces:**
- Consumes: launch arguments (`-intensity`, `-showEvaluationBadges`), the HUD, and the Settings menu.
- Produces: the capture protocol the user follows for the videos and Instruments traces.

- [ ] **Step 1: Write the capture protocol**

`Captures/README.md`:

```markdown
# Capture Protocol

How to record the videos and Instruments traces that compare the two apps. Videos (`*.mov`, `*.mp4`) and traces
(`*.trace`) are git-ignored; commit only each capture's `CaptureNotes.md`.

## Before you start

1. Build **Release** for the device: in Xcode, edit each scheme ▸ Run ▸ Build Configuration ▸ Release (or Product ▸
   Profile, which uses Release). Debug builds exaggerate SwiftUI costs.
2. Use the same device, iOS version, and intensity for both apps. Charge the device and let it cool; thermal
   throttling skews results.
3. Set the intensity with the scheme's launch arguments (Edit Scheme ▸ Run/Profile ▸ Arguments), for example
   `-intensity heavy`. Add `-showEvaluationBadges` for videos only. **Leave badges off for Instruments runs.**
4. Tap the HUD's reset button before each take.

## Gesture script (same for every take)

1. Drag the budget slider slowly from end to end and back, for about 10 seconds.
2. Tap the eye button (hide and then show balances).
3. Toggle **Pending only** on and off.
4. Tap Week, Month, Quarter, Year (the control case: both apps do similar work here).

## Video

Use iOS Screen Recording from Control Center. The HUD in each frame shows the app variant, intensity, and device.

## Instruments

Product ▸ Profile ▸ **SwiftUI** template. Add the **Hitches** instrument if it isn't already there. Record the
gesture script, then save the trace.

## Where captures go

`Captures/<date>-<device>-<intensity>-<variant>/`, for example `Captures/2026-10-02-iPhone18,1-heavy-computed/`,
containing the video and/or trace plus a filled-in copy of `CaptureNotes.md`.

## Finding the threshold

Start at **Realistic**. If neither app hitches, step up one level at a time and record each level you tried. The
lowest level where the Computed app hitches and the Structs app doesn't is the headline result for that device. If
Realistic already shows a difference, say so. If no level does, say that too.
```

`Captures/CaptureNotes.md`:

```markdown
# Capture Notes

- **Date:**
- **Device (model identifier from the HUD):**
- **iOS version:**
- **App variant:** Computed properties / View structs
- **Intensity:**
- **Build configuration:** Release
- **Badges on?** yes / no (must be "no" for Instruments)
- **Recorded:** video / Instruments trace / both

## HUD after the gesture script

- Hitches:
- Worst frame (ms):
- FPS while dragging:

## Instruments summary

- Hitch count and longest hitch:
- Heaviest SwiftUI body updates:

## Observations
```

- [ ] **Step 2: Mark the project complete in `CLAUDE.md`**

Replace the `## Status` section's body with:

```markdown
Implemented per `docs/superpowers/plans/2026-09-26-computed-vs-struct-views.md`. Next step is the user's follow-up:
record videos and Instruments traces on devices using `Captures/README.md`.
Design: `docs/superpowers/specs/2026-09-26-computed-vs-struct-views-design.md`.
```

If Task 10 recorded anything a future session must know (for example a binding-input finding), add it under **Gotchas**.

- [ ] **Step 3: Update the Journal's retrospective**

Rewrite **7. If I Were Starting Over…** using what actually happened. Keep the existing point about deciding on
instrumentation first, and add at least one lesson from Tasks 6–10 (for example, the manual package-link step and
what to do about it next time, or what the badge numbers taught us). Update **3. The Codebase Map** if any file
moved or was added during implementation.

- [ ] **Step 4: Final checks and commit**

Run: `swift test --package-path DashboardKit` → all pass.
Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.
Run: `Scripts/check-section-parity.sh` → six `✓`.
Run: `git status --short` → only the files from this task (no videos, traces, `build/`, or `xcuserdata`).

```bash
git add Captures CLAUDE.md Journal.md
git commit -F - <<'EOF'
docs: add capture protocol and finalize project docs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```
