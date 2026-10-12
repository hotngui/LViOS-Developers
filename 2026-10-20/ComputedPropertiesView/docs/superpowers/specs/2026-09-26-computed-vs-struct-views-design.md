# Design: Computed-Property Views vs. View Structs — Hitch Demo

- **Date:** 2026-09-26
- **Status:** Approved in conversation; awaiting written-spec review
- **Source brief:** `DontUseComputedPropertiesToCreateViews.md`
- **Conversation record:** `SessionLog.md`

## 1. Purpose

Build two iOS apps that are identical except for one thing: how the main dashboard's sections are factored.

- **Computed** — sections are `private var …: some View` computed properties on the dashboard view.
- **Structs** — sections are separate `View` structs with narrow inputs.

The goal is to show — on video and in Instruments — that the computed-property version hitches when the dashboard's `@State` changes, while the struct version does not.

The project serves two purposes at once (user's choice, "Both"):

1. **Teaching demo** — a difference nobody can miss on video.
2. **Honest experiment** — the default workload is realistic. A visible, clearly labeled intensity setting can raise the load to exaggerate the effect, and the setting is recorded with every capture. If the realistic level shows little or no difference, that is a valid result and gets reported as such.

### What the user asked for

- A sample iOS app whose content view is complex enough that `some View` computed properties cause hitches when its `@State` changes.
- Controls that change the content view's `@State` to trigger re-evaluation.
- A second app that is the same except it uses new `View` structs; the hitches should be visibly gone.
- Follow-ups (not in this project's scope): videos of each app running, and Instruments runs showing hitches.

### Why the effect happens (and when it doesn't)

Per Apple's SwiftUI guidance, a computed property is inlined into the parent's `body`. It does not create its own invalidation boundary, so any state change on the parent re-runs every section — including sections that never read the changed state. A separate `View` struct is its own invalidation boundary: SwiftUI compares its inputs and skips its `body` when they are unchanged.

Two consequences shape this design:

- **The computed app only hitches if re-running all sections is expensive** — enough to miss the frame deadline (≈8.3 ms at 120 Hz, ≈16.7 ms at 60 Hz). The sections therefore do realistic derived work in their bodies.
- **The struct app is only smooth if inputs are narrow.** If every section received the rapidly changing value, the struct app would hitch too. Each section gets only what it reads, and the struct app's parent body does no work of its own.

**Honesty note:** structs limit *how often* body work runs; caching derived values in the model limits *how much* work there is. Both are valid fixes. This project isolates the first. A third "structs + cached model" app is out of scope.

## 2. Success criteria

1. On each capture device there is an intensity level at which dragging the budget slider makes the Computed app hitch (HUD hitch count rises, heartbeat bar stutters, Instruments reports hitches) while the Structs app, at the same level, shows none or far fewer.
2. Switching time ranges (the control case) costs about the same in both apps.
3. The section body code is textually identical between the two apps; a diff of the dashboard code shows only the factoring change.
4. All `DashboardKit` unit tests pass; both apps build in Release and launch in the simulator; SwiftLint (with `~/.swiftlint.yml`) reports no warnings or errors.
5. Each video frame documents itself (variant, intensity, device model on the HUD).

## 3. The screen and its state map

The dashboard is a `ScrollView` containing a vertical stack of six sections. Transactions are seeded sample data held in a shared `@Observable` store, so both apps show exactly the same data.

### Sections (top to bottom)

| # | Section | Contents | Derived work in body |
|---|---|---|---|
| 1 | Account summary | Net (income + expenses), income, and expenses for the range; eye button | Filter by range, sum `Decimal`s |
| 2 | Time-range picker | Segmented picker: Week / Month / Quarter / Year | — |
| 3 | Budget card | Continuous slider ($0–$20,000) + gauge of spending vs. budget, capped at 100% with an "over budget" label | Filter by range, sum expenses |
| 4 | Spending chart | Swift Charts stacked bars by day × category | Filter, bin by day and category |
| 5 | Category breakdown | Totals per category, sorted, with percentage bars | Filter, group, sum, sort |
| 6 | Recent transactions | First *N* rows in a non-lazy `VStack`; pending-only toggle | Filter, sort, format currency and dates |

The derived work calls shared pure functions in `TransactionMath` (see §4), so the cost is identical in both apps.

### `@State` owned by the dashboard view

| `@State` | Control | Sections that read it (Structs app) |
|---|---|---|
| `budget: Double` | Slider in the Budget card (`Slider` needs a floating-point value; converted to `Decimal` for the comparison) | Budget card only |
| `hideBalances: Bool` | Eye button in the Account summary | Account summary only |
| `showPendingOnly: Bool` | Toggle in Recent transactions | Recent transactions only |
| `timeRange: TimeRange` | Segmented picker | Summary, Budget, Chart, Categories, Transactions |

### Interactions and expected behavior

- **Budget slider (the headline demo).** Dragging changes `budget` many times per second. Computed app: every tick re-runs all six sections. Structs app: only the Budget card re-runs, so the slider thumb stays smooth.
- **Eye button / pending-only toggle.** One-shot changes. Computed app re-runs everything; Structs app re-runs one section.
- **Time-range picker (control case).** The state is legitimately needed by five sections, so both apps do similar work. Structs don't make necessary work free.

### Rule for the Structs app's parent

The parent `DashboardView` body stays trivially cheap. It forwards raw inputs — the transactions array, `timeRange`, `rowLimit`, and the specific binding a section needs — and never filters or aggregates. (If it built a filtered array, every tick would hand every section a new array, invalidating all of them and defeating the demo.)

### Out of scope

- Category selection linking the chart and breakdown (explicitly dropped).
- Row-level view structs. Transaction rows stay inline in both apps so the only variable is section factoring.

## 4. Architecture and components

One Xcode project, one local Swift package, two thin app targets.

```
ComputedPropertiesView/
├── ComputedPropertiesView.xcodeproj
├── DashboardKit/                          local Swift package, shared by both apps
│   ├── Package.swift
│   ├── Sources/DashboardKit/
│   │   ├── Model/        Transaction, TransactionCategory, TimeRange, DashboardSection
│   │   ├── Data/         SeededRandomGenerator, SampleDataGenerator,
│   │   │                 TransactionStore (@MainActor @Observable)
│   │   ├── Math/         TransactionMath
│   │   ├── Settings/     Intensity, DemoSettings (@MainActor @Observable), LaunchArguments
│   │   ├── Diagnostics/  FrameStats, FrameMeterView (HUD), EvaluationCounter, EvaluationBadge
│   │   └── Shell/        DemoShell, AppVariant
│   └── Tests/
│       ├── TestList.md
│       └── DashboardKitTests/
├── ComputedDashboard/                     app target "Computed"
│   ├── ComputedDashboardApp.swift
│   └── DashboardView.swift                six `private var …: some View` sections
├── StructDashboard/                       app target "Structs"
│   ├── StructDashboardApp.swift
│   ├── DashboardView.swift                thin parent: owns @State, composes sections
│   └── Sections/                          one file per section struct
├── Captures/
│   ├── README.md                          capture protocol
│   └── CaptureNotes.md                    per-capture template
├── docs/superpowers/specs/                this spec
├── CLAUDE.md
├── Journal.md
└── SessionLog.md
```

### Components

| Unit | Responsibility | Depends on |
|---|---|---|
| `Transaction`, `TransactionCategory` | Value types: id, date, merchant, category (8 cases), `Decimal` amount (income positive, expenses negative), `isPending`. `Sendable`, `Equatable`. | — |
| `TimeRange` | Week / Month / Quarter / Year; returns its date interval from a given anchor date and `Calendar`. | — |
| `DashboardSection` | Enum identifying the six sections (used by the evaluation counter). | — |
| `SeededRandomGenerator` | Deterministic `RandomNumberGenerator` (e.g. SplitMix64) so both apps generate identical data. | — |
| `SampleDataGenerator` | `@concurrent` function that generates a year of transactions for an intensity level, relative to a fixed anchor date, off the main thread. | Seeded generator, models |
| `TransactionStore` | `@MainActor @Observable`. Holds `[Transaction]` and a loading flag; regenerates when intensity changes. | Generator |
| `TransactionMath` | Pure `nonisolated` functions called from section bodies: filter by range, income/expense/net sums, spending total, category totals with percentages, daily bins by category, pending-only filter, recent-first sort. | Models |
| `Intensity` | Named levels with their parameters (see §5). | — |
| `LaunchArguments` | Parses `-intensity <level>` (case-insensitive); unknown values fall back to Realistic and log a message. | `Intensity` |
| `DemoSettings` | `@MainActor @Observable`. Current intensity and the "Show re-evaluations" toggle (off by default). | `Intensity`, `LaunchArguments` |
| `FrameStats` | Pure value type: consumes frame timestamps, estimates the expected interval from recent frames, counts hitches (interval > 1.5× expected), tracks FPS and worst frame; reset. | — |
| `FrameMeterView` | HUD overlay (see §5). Own view, own state — never invalidates the dashboard. | `FrameStats`, `DemoSettings` |
| `EvaluationCounter` | Non-observable `@MainActor` final class, one instance per app, shared via the environment. `record(_ section:) -> Int` increments and returns that section's count; `reset()`. | `DashboardSection` |
| `EvaluationBadge` | Small "body runs: N" label shown when "Show re-evaluations" is on. | — |
| `AppVariant` | `.computed` / `.structs`: display name and badge color (orange / green). | — |
| `DemoShell` | Shared root: `NavigationStack`, toolbar settings menu (intensity, re-evaluation toggle, reset counters), HUD overlay, `ProgressView` while loading. Injects the `EvaluationCounter` and a `showsEvaluationBadges` flag (`@Entry` environment values) so section code reads them the same way in both apps. Takes a content closure that receives the transactions and row limit. | Store, settings, diagnostics |
| App targets | `App` struct creating `DemoShell(variant:)` with its own `DashboardView`. Nothing else. | `DashboardKit` |

### Keeping the two apps comparable

- Each section's body code is copied exactly between the two targets. `$budget` is `@State` in one and `@Binding` in the other, but the text reads the same.
- Each section body calls `evaluationCounter.record(.<section>)` and passes the result to its `EvaluationBadge`. In the Computed app the count rises whenever the parent body runs; in the Structs app only when that section's body runs.
- `ComputedDashboard/DashboardView.swift` opens with a header comment: **INTENTIONAL ANTI-PATTERN — do not copy.** Any SwiftLint suppressions it needs are scoped to that file and commented.

### Targets and build settings

| | Computed | Structs |
|---|---|---|
| Bundle ID | `com.hotngui.ComputedDashboard` | `com.hotngui.StructDashboard` |
| Display name | Computed | Structs |

- iOS 27.0 deployment target, Swift 6 language mode on the current toolchain.
- Strict Concurrency Checking: Complete. Approachable Concurrency: Yes.
- `@MainActor` on every `@Observable` class.
- Captures use Release builds (Debug builds exaggerate SwiftUI costs).
- No third-party dependencies. Swift Charts is an Apple framework.

## 5. Measurement and capture tooling

### Intensity levels

Named steps rather than a continuous dial, so a capture can be reproduced exactly. These are starting values; they will be tuned on the user's devices during implementation, and the final table is recorded in `CLAUDE.md`.

| Level | Transactions (1 year) | Rows in Recent list |
|---|---|---|
| Light | 1,000 | 25 |
| Realistic (default) | 3,000 | 50 |
| Heavy | 10,000 | 150 |
| Severe | 30,000 | 300 |
| Extreme | 100,000 | 600 |

- Chart marks depend on the time range (days × 8 categories), up to about 2,900 for a year.
- Level is set from the toolbar settings menu or by launch argument (`-intensity heavy`) so Instruments runs start identically. Changing the level regenerates data with the same seed.

### Fixed demo clock

Data is generated relative to a fixed anchor date (2026-09-30) rather than today, so captures on different days show the same numbers. All date math takes an injected `Calendar`; tests pin its time zone.

### Frame-meter HUD

A small overlay pinned to the top of the screen showing:

- Variant badge: orange **Computed properties** or green **View structs**.
- Intensity level and device model identifier (for example `iPhone18,1`, read via `sysctlbyname("hw.machine")`).
- Live FPS, hitch count, worst frame time in ms, and a Reset button.
- A **heartbeat bar** that sweeps continuously, driven by `TimelineView(.animation)`. It stutters when the main thread misses frames, making hitches visible without reading numbers.

The HUD measures main-thread frame pacing. Instruments remains the source of truth. The HUD's own per-frame cost is the same in both apps.

### Re-evaluation badges

When "Show re-evaluations" is on, each section shows a small **"body runs: N"** badge. While dragging the slider, every badge climbs in the Computed app; only the Budget card's badge climbs in the Structs app. Badges replace an earlier color-flash idea, which would flash far more than three times per second and fail WCAG 2.3.1. Keep badges off for Instruments runs.

### Capture protocol

Documented in `Captures/README.md`, with a `CaptureNotes.md` template (date, device, iOS version, variant, intensity, build configuration, observations). Performing the captures is the user's follow-up.

1. Release build; same device and intensity for both apps; re-evaluation badges off for Instruments runs.
2. Gesture script:
   1. Drag the budget slider back and forth for about 10 seconds.
   2. Tap the eye button.
   3. Toggle pending-only.
   4. Cycle through the time ranges (control case).
3. Video: iOS Screen Recording. Traces: Instruments' SwiftUI template plus the Hitches instrument.
4. Store each capture in `Captures/<date>-<device>-<intensity>-<variant>/`.

## 6. Loading, errors, accessibility

- **Loading:** Generating up to 100,000 transactions takes noticeable time, so `SampleDataGenerator` is `@concurrent` and runs off the main thread. `DemoShell` shows a `ProgressView` until data arrives, including after an intensity change.
- **Errors:** Nothing else can fail at runtime. Unknown launch-argument values fall back to Realistic and log a message.
- **Accessibility:** Dynamic Type throughout (no fixed font sizes). VoiceOver labels on the chart, gauge, slider value, and HUD. Badges and the variant indicator use text, not color alone.

## 7. Testing

Swift Testing, test-driven. The test list below is copied into `DashboardKit/Tests/TestList.md` before any test is written, then each test is written before the code it covers. All tests target `DashboardKit`; the app targets contain only view code. No UI tests — the hitch behavior itself is verified on device via the capture protocol.

### Test list

**SeededRandomGenerator**
- Same seed produces the same sequence.
- Different seeds produce different sequences.

**SampleDataGenerator**
- Transaction count matches the intensity level.
- Output is identical across two runs with the same seed.
- Every date falls within the year before the anchor date.
- All 8 categories appear.
- Income amounts are positive and expense amounts are negative.
- At least one transaction is pending.

**TimeRange**
- Week, Month, Quarter, and Year each return the correct interval from the anchor date.

**TransactionMath**
- Range filtering includes transactions on both boundary dates and excludes those outside.
- Income, expense, and net sums are correct.
- Spending total for the budget gauge is correct.
- Category totals are sorted largest first, and their percentages add up to 100%.
- Daily bins produce the correct per-day, per-category totals.
- Pending-only filter returns only pending transactions.

**Intensity and LaunchArguments**
- `-intensity heavy` parses regardless of case.
- Missing or unknown values fall back to Realistic.
- Each level's transaction count and row limit are strictly larger than the previous level's.

**FrameStats**
- Steady 120 Hz frames produce no hitches.
- One 25 ms frame among 120 Hz frames produces one hitch, and worst frame reports 25 ms.
- The same logic holds at 60 Hz.
- Reset clears counts, FPS, and worst frame.

**EvaluationCounter**
- Counts for different sections are independent.
- `record` returns the incremented count.
- Reset clears all counts.

### Pre-commit checks

- `DashboardKit` tests pass.
- Both apps build in Release and launch in the simulator.
- `swiftlint lint --config ~/.swiftlint.yml` reports no warnings or errors.

## 8. Risks and open questions

- **The Realistic level may show no visible difference.** That is a valid finding for the "honest experiment" goal and gets reported, not tuned away.
- **Bindings as inputs.** The Structs app passes `$budget`, `$hideBalances`, `$showPendingOnly`, and `$timeRange` to the sections that edit them. If SwiftUI treats a re-created binding as a changed input, those sections would re-run on unrelated changes. The re-evaluation badges will reveal this during implementation; the fix is decided then, and the finding goes in `Journal.md`.
- **Swift Charts cost.** The chart may dominate the time-range control case and hitch in both apps. That is expected and part of the lesson.
- **Intensity numbers** are starting values and need tuning on each capture device.

## 9. Repository and documentation

- Local git repository only; nothing is pushed.
- `.gitignore` covers Xcode build output (`DerivedData/`, `xcuserdata/`, `.build/`), `*.mov`, `*.mp4`, and `*.trace`.
- `CLAUDE.md` (project memory) and `Journal.md` (learning journal, with the sections required by AGENTS.md) are created during implementation.
- `SessionLog.md` records every session's inputs and outputs and keeps growing.
