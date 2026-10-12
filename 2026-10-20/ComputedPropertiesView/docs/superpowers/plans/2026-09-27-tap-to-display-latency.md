# Tap-to-Display Latency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a start screen with an Open Dashboard button, and time how long it takes from a tap (the open, or an eye / Pending only / time-range tap inside the dashboard) until the result is on screen. Show the latest timing on the HUD and as Points of Interest intervals in Instruments.

**Architecture:**
- A pure `LatencyMeter` value type does all the timing logic.
- A shared, non-observable `@MainActor` `InteractionTimer` stamps times, feeds the meter, and emits signposts.
- The HUD's existing per-frame `TimelineView` clock ends each timing.
- `DemoShell` gains a `NavigationStack(path:)` with a shared `StartScreen` as its root, and the app's dashboard is pushed via `navigationDestination(for:)`.
- The three in-dashboard hooks are identical one-line edits inside the parity-checked section bodies of both apps.

**Tech Stack:** Swift 6.4 (Swift 6 mode), SwiftUI (iOS 27 SDK), `os` (`OSSignposter`), Swift Testing, Xcode 27.1, SwiftLint 0.65.1.

**Spec:** `docs/superpowers/specs/2026-09-27-tap-to-display-latency-design.md` (builds on `docs/superpowers/specs/2026-09-26-computed-vs-struct-views-design.md`).

## Global Constraints

- Every constraint in the first plan (`docs/superpowers/plans/2026-09-26-computed-vs-struct-views.md`, "Global Constraints") still applies. That means iOS 27.0, Swift 6 strict concurrency, `@MainActor` on `@Observable` classes, one type per file, no force unwraps, no hard-coded padding or font sizes, Swift Testing only, and SwiftLint at 0 violations (`swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml`) before every commit.
- Work on local branch **`feature/tap-latency`** cut from `main`. **Never push.** End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Section bodies stay textually identical in both apps: `Scripts/check-section-parity.sh` must pass after every task that touches them.
- The `App` structs and `DemoShell`'s public initializer don't change.
- `InteractionTimer` is **not** `@Observable`. Recording a tap or a frame must never cause a view update.
- `Journal.md` gets a feature entry only, with **no device observations** (explicit user instruction).
- `SessionLog.md` is maintained by the main session only.
- Repo root: `/Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView`. Simulator: iPhone 18 Pro, iOS 27.0, `SIM=B9BB0E3F-E390-472F-AD17-952DA5298A94`.
- HUD text formats: `"Open 512 ms (first frame 48 ms)"` for opens, `"Pending only 212 ms"` for taps, `"Tap something to time it"` before any timing.

## Review Focus

1. **The user backs out (Back or a swipe) before the open's slide-in finishes.** No "Open" measurement should be recorded for an open that didn't finish. → Task 1, `cancelDiscardsThePendingTiming`, plus the path check in `DemoShell.openDashboard` (Task 3).
2. **The app leaves the foreground while a timing is pending.** Don't record a multi-second "latency". → Task 1, `cancelDiscardsThePendingTiming`, plus the scene-phase wiring in `FrameMeterView` (Task 3).
3. **Double-tapping Open Dashboard.** Exactly one dashboard should be pushed (one Back returns to the start screen). → Task 3, Step 7 (simulator check).
4. **A HUD frame dated at or before the tap**, such as an off-cycle re-render of the current frame. It's ignored, so the timing doesn't read ~0 ms. → Task 1, `framesAtOrBeforeTheTapAreIgnored`.
5. **The `timed` binding helper must not change which sections re-run.** In the Structs app, an eye tap still re-runs only the summary. → Task 5, Step 5 (badge check).

---

### Task 1: Branch, the user's Xcode changes, and `LatencyMeter`

**Files:**
- Commit as-is (user's changes): `ComputedPropertiesView.xcodeproj/project.pbxproj` (adds `DEVELOPMENT_TEAM`), `ComputedPropertiesView.xcodeproj/xcshareddata/xcschemes/*.xcscheme`
- Modify: `DashboardKit/Tests/TestList.md`
- Create: `DashboardKit/Sources/DashboardKit/Latency/Interaction.swift`
- Create: `DashboardKit/Sources/DashboardKit/Latency/LatencyMeasurement.swift`
- Create: `DashboardKit/Sources/DashboardKit/Latency/LatencyMeter.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/LatencyMeterTests.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `enum Interaction: String, CaseIterable, Sendable { openDashboard, toggleBalances, pendingOnly, timeRange }` with `title: LocalizedStringResource` and `endsAtFirstFrame: Bool`
  - `struct LatencyMeasurement: Equatable, Sendable { interaction; total: Duration; firstFrame: Duration? }` (internal memberwise init)
  - `struct LatencyMeter: Equatable, Sendable { init(); var isTiming: Bool; private(set) var last: LatencyMeasurement?; mutating begin(_:at:); mutating frameRendered(at:); mutating finish(at:); mutating cancel() }`

- [ ] **Step 1: Create the branch and commit the user's Xcode changes**

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
git switch -c feature/tap-latency
git status --short   # expect: M project.pbxproj, ?? xcshareddata/, M SessionLog.md (the log is committed by the main session)
git add ComputedPropertiesView.xcodeproj/project.pbxproj ComputedPropertiesView.xcodeproj/xcshareddata
git commit -F - <<'EOF'
chore: add development team and shared schemes for device runs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 2: Add the new tests to the test list (before writing them)**

Append to `DashboardKit/Tests/TestList.md`:

```markdown

## LatencyMeter (LatencyMeterTests)
- A tap completes at the first frame after it, with total == firstFrame == frame − tap.
- Frames dated at or before the tap are ignored. (Review Focus 4)
- An open doesn't complete at its first frame; finish completes it with total and the recorded firstFrame.
- finish before any frame completes with firstFrame == nil.
- A second begin before completion replaces the first.
- frameRendered and finish with nothing pending leave last unchanged.
- cancel discards the pending timing. (Review Focus 1 and 2)

## InteractionTimer and Binding.timed (InteractionTimerTests)
- begin followed by a later frame produces a last measurement for that interaction.
- Setting through a timed binding changes the value and starts the timer for that interaction.
```

- [ ] **Step 3: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/LatencyMeterTests.swift`:

```swift
import Foundation
import Testing
@testable import DashboardKit

@Suite struct LatencyMeterTests {
    let tap = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func aTapCompletesAtTheFirstFrameAfterIt() {
        var meter = LatencyMeter()
        meter.begin(.pendingOnly, at: tap)
        meter.frameRendered(at: tap.addingTimeInterval(0.25))
        meter.frameRendered(at: tap.addingTimeInterval(0.5))
        let expected = LatencyMeasurement(interaction: .pendingOnly, total: .milliseconds(250), firstFrame: .milliseconds(250))
        #expect(meter.last == expected)
        #expect(!meter.isTiming)
    }

    @Test func framesAtOrBeforeTheTapAreIgnored() {
        var meter = LatencyMeter()
        meter.begin(.toggleBalances, at: tap)
        meter.frameRendered(at: tap)
        meter.frameRendered(at: tap.addingTimeInterval(-0.1))
        #expect(meter.last == nil)
        #expect(meter.isTiming)
        meter.frameRendered(at: tap.addingTimeInterval(0.125))
        #expect(meter.last?.total == .milliseconds(125))
    }

    @Test func anOpenWaitsForFinishAndKeepsItsFirstFrame() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.frameRendered(at: tap.addingTimeInterval(0.125))
        meter.frameRendered(at: tap.addingTimeInterval(0.25))
        #expect(meter.last == nil)
        meter.finish(at: tap.addingTimeInterval(0.5))
        let expected = LatencyMeasurement(interaction: .openDashboard, total: .milliseconds(500), firstFrame: .milliseconds(125))
        #expect(meter.last == expected)
    }

    @Test func finishBeforeAnyFrameHasNoFirstFrame() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.finish(at: tap.addingTimeInterval(0.5))
        #expect(meter.last == LatencyMeasurement(interaction: .openDashboard, total: .milliseconds(500), firstFrame: nil))
    }

    @Test func aSecondTapReplacesAnUnfinishedOne() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.begin(.timeRange, at: tap.addingTimeInterval(0.25))
        meter.frameRendered(at: tap.addingTimeInterval(0.5))
        let expected = LatencyMeasurement(interaction: .timeRange, total: .milliseconds(250), firstFrame: .milliseconds(250))
        #expect(meter.last == expected)
    }

    @Test func framesAndFinishWithNothingPendingDoNothing() {
        var meter = LatencyMeter()
        meter.frameRendered(at: tap)
        meter.finish(at: tap)
        #expect(meter.last == nil)
        meter.begin(.pendingOnly, at: tap)
        meter.frameRendered(at: tap.addingTimeInterval(0.25))
        let completed = meter.last
        meter.frameRendered(at: tap.addingTimeInterval(1))
        meter.finish(at: tap.addingTimeInterval(2))
        #expect(meter.last == completed)
    }

    @Test func cancelDiscardsThePendingTiming() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.frameRendered(at: tap.addingTimeInterval(0.125))
        meter.cancel()
        meter.finish(at: tap.addingTimeInterval(0.5))
        #expect(meter.last == nil)
        #expect(!meter.isTiming)
    }
}
```

- [ ] **Step 4: Run and confirm failure**

Run: `swift test --package-path DashboardKit --filter LatencyMeterTests`
Expected: build failure: `cannot find 'LatencyMeter' in scope` (and `LatencyMeasurement`).

- [ ] **Step 5: Implement**

`DashboardKit/Sources/DashboardKit/Latency/Interaction.swift`:

```swift
import Foundation

/// A user action whose tap-to-display time the HUD measures.
public enum Interaction: String, CaseIterable, Sendable {
    case openDashboard, toggleBalances, pendingOnly, timeRange

    public var title: LocalizedStringResource {
        switch self {
        case .openDashboard: "Open"
        case .toggleBalances: "Balances"
        case .pendingOnly: "Pending only"
        case .timeRange: "Time range"
        }
    }

    /// In-dashboard taps finish at the first frame that shows the new state; opening finishes when the slide-in ends.
    public var endsAtFirstFrame: Bool { self != .openDashboard }
}
```

`DashboardKit/Sources/DashboardKit/Latency/LatencyMeasurement.swift`:

```swift
/// One completed tap-to-display timing.
public struct LatencyMeasurement: Equatable, Sendable {
    public let interaction: Interaction
    /// From the tap until the interaction finished: the slide-in's end for an open, the first new frame otherwise.
    public let total: Duration
    /// From the tap until the first frame that showed the result; `nil` if no frame arrived before it finished.
    public let firstFrame: Duration?
}
```

`DashboardKit/Sources/DashboardKit/Latency/LatencyMeter.swift`:

```swift
import Foundation

/// Times one interaction at a time, from the tap to the frame (or animation end) that shows its result.
/// Pure value logic; `InteractionTimer` supplies the clock.
public struct LatencyMeter: Equatable, Sendable {
    private struct Pending: Equatable, Sendable {
        let interaction: Interaction
        let start: Date
        var firstFrame: Duration?
    }

    private var pending: Pending?
    public private(set) var last: LatencyMeasurement?

    public init() {}

    public var isTiming: Bool { pending != nil }

    /// Starts timing `interaction`. A timing that hasn't finished yet is replaced: the latest tap wins.
    public mutating func begin(_ interaction: Interaction, at start: Date) {
        pending = Pending(interaction: interaction, start: start)
    }

    /// Feed every rendered frame. The first frame after the tap is recorded; for in-dashboard taps it completes the timing.
    public mutating func frameRendered(at date: Date) {
        guard var current = pending, current.firstFrame == nil, date > current.start else { return }
        let elapsed = Duration.seconds(date.timeIntervalSince(current.start))
        current.firstFrame = elapsed
        if current.interaction.endsAtFirstFrame {
            complete(current, total: elapsed)
        } else {
            pending = current
        }
    }

    /// Completes a timing whose end isn't a frame: an open finishes when the slide-in animation completes.
    public mutating func finish(at date: Date) {
        guard let current = pending else { return }
        complete(current, total: .seconds(date.timeIntervalSince(current.start)))
    }

    /// Discards the pending timing, e.g. the user backed out or the app left the foreground.
    public mutating func cancel() {
        pending = nil
    }

    private mutating func complete(_ timing: Pending, total: Duration) {
        last = LatencyMeasurement(interaction: timing.interaction, total: total, firstFrame: timing.firstFrame)
        pending = nil
    }
}
```

- [ ] **Step 6: Run and confirm pass**

Run: `swift test --package-path DashboardKit --filter LatencyMeterTests`
Expected: PASS (7 tests). Then `swift test --package-path DashboardKit`: all pass.

- [ ] **Step 7: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add LatencyMeter for tap-to-display timing

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: `InteractionTimer` and the `timed` binding helper

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Latency/InteractionTimer.swift`
- Create: `DashboardKit/Sources/DashboardKit/Latency/Binding+Timed.swift`
- Test: `DashboardKit/Tests/DashboardKitTests/InteractionTimerTests.swift`

**Interfaces:**
- Consumes (Task 1): `LatencyMeter`, `LatencyMeasurement`, `Interaction`.
- Produces:
  - `@MainActor final class InteractionTimer { static let shared; init(); var last: LatencyMeasurement?; func begin(_:at: Date = .now); func frameRendered(at: Date); func finish(at: Date = .now); func cancel() }`
  - `extension Binding where Value: Sendable { @MainActor func timed(_ interaction: Interaction, timer: InteractionTimer = .shared) -> Binding<Value> }`

- [ ] **Step 1: Write the failing tests**

`DashboardKit/Tests/DashboardKitTests/InteractionTimerTests.swift`:

```swift
import Foundation
import SwiftUI
import Testing
@testable import DashboardKit

@Suite @MainActor struct InteractionTimerTests {
    /// Stands in for view state behind a `Binding`.
    @MainActor
    final class Box {
        var value = false
    }

    @Test func beginFollowedByALaterFrameProducesAMeasurement() {
        let timer = InteractionTimer()
        let tap = Date(timeIntervalSinceReferenceDate: 2_000)
        timer.begin(.toggleBalances, at: tap)
        timer.frameRendered(at: tap.addingTimeInterval(0.125))
        let expected = LatencyMeasurement(interaction: .toggleBalances, total: .milliseconds(125), firstFrame: .milliseconds(125))
        #expect(timer.last == expected)
    }

    @Test func settingThroughATimedBindingChangesTheValueAndStartsTheTimer() {
        let box = Box()
        let timer = InteractionTimer()
        let binding = Binding(get: { box.value }, set: { box.value = $0 })
        binding.timed(.pendingOnly, timer: timer).wrappedValue = true
        #expect(box.value)
        timer.frameRendered(at: .now.addingTimeInterval(1))
        #expect(timer.last?.interaction == .pendingOnly)
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `swift test --package-path DashboardKit --filter InteractionTimerTests`
Expected: build failure: `cannot find 'InteractionTimer' in scope`.

- [ ] **Step 3: Implement**

`DashboardKit/Sources/DashboardKit/Latency/InteractionTimer.swift`:

```swift
import Foundation
import os

/// The app-wide tap-to-display timer.
///
/// Deliberately not `@Observable`: the HUD reads `last` while it redraws every frame, and recording a tap or a frame
/// must never cause a view update. Each timing is also emitted as a Points of Interest interval for Instruments.
@MainActor
public final class InteractionTimer {
    public static let shared = InteractionTimer()

    private var meter = LatencyMeter()
    private var signpostState: OSSignpostIntervalState?
    private let signposter = OSSignposter(subsystem: "com.hotngui.DashboardKit", category: .pointsOfInterest)

    public init() {}

    /// The most recent completed timing.
    public var last: LatencyMeasurement? { meter.last }

    public func begin(_ interaction: Interaction, at date: Date = .now) {
        endSignpost()
        meter.begin(interaction, at: date)
        let id = signposter.makeSignpostID()
        signpostState = signposter.beginInterval("Interaction", id: id, "\(interaction.rawValue, privacy: .public)")
    }

    /// Called by the HUD for every frame it renders.
    public func frameRendered(at date: Date) {
        let wasTiming = meter.isTiming
        meter.frameRendered(at: date)
        if wasTiming && !meter.isTiming {
            endSignpost()
        }
    }

    public func finish(at date: Date = .now) {
        meter.finish(at: date)
        endSignpost()
    }

    public func cancel() {
        meter.cancel()
        endSignpost()
    }

    private func endSignpost() {
        guard let state = signpostState else { return }
        signposter.endInterval("Interaction", state)
        signpostState = nil
    }
}
```

`DashboardKit/Sources/DashboardKit/Latency/Binding+Timed.swift`:

```swift
import SwiftUI

extension Binding where Value: Sendable {
    /// A binding that starts timing `interaction` whenever a control sets a new value through it.
    @MainActor
    public func timed(_ interaction: Interaction, timer: InteractionTimer = .shared) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { newValue, transaction in
                timer.begin(interaction)
                self.transaction(transaction).wrappedValue = newValue
            }
        )
    }
}
```

- [ ] **Step 4: Run and confirm pass**

Run: `swift test --package-path DashboardKit --filter InteractionTimerTests`
Expected: PASS (2 tests). Then `swift test --package-path DashboardKit`: all pass.

- [ ] **Step 5: Lint and commit**

Run: `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → `Found 0 violations`.

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add InteractionTimer with signposts and a timed binding helper

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Start screen, navigation, and the HUD readout

Invoke the `swiftui-specialist` skill before writing these views (AGENTS.md requirement).

**Files:**
- Create: `DashboardKit/Sources/DashboardKit/Shell/DashboardRoute.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/StartScreen.swift`
- Create: `DashboardKit/Sources/DashboardKit/Shell/View+SettingsToolbar.swift`
- Create: `DashboardKit/Sources/DashboardKit/Latency/LatencyReadout.swift`
- Modify: `DashboardKit/Sources/DashboardKit/Shell/AppVariant.swift` (add `explanation`)
- Modify: `DashboardKit/Sources/DashboardKit/Shell/DemoShell.swift`
- Modify: `DashboardKit/Sources/DashboardKit/Diagnostics/FrameRecorder.swift`
- Modify: `DashboardKit/Sources/DashboardKit/Diagnostics/FrameMeterView.swift`

**Interfaces:**
- Consumes (Task 2): `InteractionTimer.shared.begin/finish/cancel/frameRendered/last`.
- Produces: `struct DashboardRoute: Hashable`; `StartScreen(variant:intensity:isReady:open:)`; `LatencyReadout(measurement:)`; `AppVariant.explanation: LocalizedStringResource`; `View.settingsToolbar(_:)` (internal).

- [ ] **Step 1: Add the small shell pieces**

`DashboardKit/Sources/DashboardKit/Shell/DashboardRoute.swift`:

```swift
/// The navigation value for the dashboard screen.
struct DashboardRoute: Hashable {}
```

`DashboardKit/Sources/DashboardKit/Shell/View+SettingsToolbar.swift`:

```swift
import SwiftUI

extension View {
    /// Adds the demo settings menu (intensity, badges, counts reset, stall) to this screen's toolbar.
    func settingsToolbar(_ settings: DemoSettings) -> some View {
        toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsMenu(settings: settings)
            }
        }
    }
}
```

In `DashboardKit/Sources/DashboardKit/Shell/AppVariant.swift`, add after `title`:

```swift
    /// One line on the start screen explaining what this variant demonstrates.
    public var explanation: LocalizedStringResource {
        switch self {
        case .computed: "Each dashboard section is a computed property, so every change re-runs all six."
        case .structs: "Each dashboard section is its own view, so a change re-runs only the sections that use it."
        }
    }
```

- [ ] **Step 2: Add the start screen**

`DashboardKit/Sources/DashboardKit/Shell/StartScreen.swift`:

```swift
import SwiftUI

/// The first screen: which app this is, the current intensity, and the button that opens (and times) the dashboard.
struct StartScreen: View {
    let variant: AppVariant
    let intensity: Intensity
    let isReady: Bool
    let open: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text(variant.title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Text(variant.explanation)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("\(Text(intensity.title)) · \(intensity.transactionCount) transactions")
                .font(.subheadline)
            if !isReady {
                ProgressView("Generating \(intensity.transactionCount) transactions…")
            }
            Button("Open Dashboard", systemImage: "chart.bar.doc.horizontal", action: open)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isReady)
            Spacer()
        }
        .padding()
        .navigationTitle("Start")
    }
}
```

- [ ] **Step 3: Add the HUD readout**

`DashboardKit/Sources/DashboardKit/Latency/LatencyReadout.swift`:

```swift
import SwiftUI

/// The HUD line with the latest tap-to-display timing, e.g. "Open 512 ms (first frame 48 ms)" or "Pending only 212 ms".
struct LatencyReadout: View {
    let measurement: LatencyMeasurement?

    private let milliseconds = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))

    var body: some View {
        if let measurement {
            let title = Text(measurement.interaction.title)
            let total = measurement.total.inMilliseconds
            if let firstFrame = measurement.firstFrame, !measurement.interaction.endsAtFirstFrame {
                let firstFrameText = Text("(first frame \(firstFrame.inMilliseconds, format: milliseconds) ms)")
                Text("\(title) \(total, format: milliseconds) ms \(firstFrameText)")
            } else {
                Text("\(title) \(total, format: milliseconds) ms")
            }
        } else {
            Text("Tap something to time it")
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 4: Feed frames to the timer and show the readout**

In `DashboardKit/Sources/DashboardKit/Diagnostics/FrameRecorder.swift`, replace `record(frameAt:)` with:

```swift
    /// Records the frame whose timeline date is `date` and returns the updated statistics. The same frame also ends any
    /// pending tap-to-display timing.
    func record(frameAt date: Date) -> FrameStats {
        stats.record(frameAt: .seconds(date.timeIntervalSinceReferenceDate))
        InteractionTimer.shared.frameRendered(at: date)
        return stats
    }
```

In `DashboardKit/Sources/DashboardKit/Diagnostics/FrameMeterView.swift`:
- Directly after the `HStack` that contains the FPS / Hitches / Worst texts and the reset button (the one ending with `.labelStyle(.iconOnly)` then `}`), insert:

```swift
                LatencyReadout(measurement: InteractionTimer.shared.last)
```

- In the `.onChange(of: scenePhase)` handler, cancel pending timings too:

```swift
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                recorder.pause()
                InteractionTimer.shared.cancel()
            }
        }
```

- [ ] **Step 5: Restructure `DemoShell` around a navigation path**

Replace `DashboardKit/Sources/DashboardKit/Shell/DemoShell.swift` with:

```swift
import SwiftUI

/// The shared root of both demo apps: the start screen, navigation to the dashboard, the settings menu, the
/// frame-meter HUD, and data loading. Each app passes in only its own `DashboardView`.
public struct DemoShell<Dashboard: View>: View {
    private let variant: AppVariant
    private let dashboard: ([AccountTransaction], Int) -> Dashboard

    @State private var settings = DemoSettings()
    @State private var store = TransactionStore()
    @State private var path: [DashboardRoute] = []

    /// - Parameter dashboard: Builds the dashboard from the transactions and the Recent-list row limit.
    public init(variant: AppVariant, @ViewBuilder dashboard: @escaping ([AccountTransaction], Int) -> Dashboard) {
        self.variant = variant
        self.dashboard = dashboard
    }

    public var body: some View {
        NavigationStack(path: $path) {
            StartScreen(variant: variant, intensity: settings.intensity, isReady: isDataReady, open: openDashboard)
                .settingsToolbar(settings)
                .navigationDestination(for: DashboardRoute.self) { _ in
                    Group {
                        if let intensity = store.loadedIntensity, !store.isLoading {
                            dashboard(store.transactions, intensity.recentRowLimit)
                        } else {
                            ProgressView("Generating transactions…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .navigationTitle("Dashboard")
                    .settingsToolbar(settings)
                }
        }
        .safeAreaInset(edge: .top) {
            FrameMeterView(variant: variant, intensity: settings.intensity)
        }
        .environment(\.showsEvaluationBadges, settings.showsEvaluationBadges)
        .environment(\.evaluationBadgeResetGeneration, settings.badgeResetGeneration)
        .environment(\.calendar, DemoClock.calendar)
        .environment(\.timeZone, DemoClock.calendar.timeZone)
        .task(id: settings.intensity) {
            await store.load(settings.intensity)
        }
    }

    private var isDataReady: Bool {
        store.loadedIntensity == settings.intensity && !store.isLoading
    }

    /// Opens the dashboard, timing it from this tap until the push's slide-in animation completes.
    private func openDashboard() {
        guard path.isEmpty else { return }
        InteractionTimer.shared.begin(.openDashboard)
        withAnimation {
            path.append(DashboardRoute())
        } completion: {
            // Backed out before the slide-in finished: don't record an open that never completed.
            if path.isEmpty {
                InteractionTimer.shared.cancel()
            } else {
                InteractionTimer.shared.finish()
            }
        }
    }
}
```

- [ ] **Step 6: Build, test, lint**

Run: `swift build --package-path DashboardKit` → `Build complete!` with no warnings from these files.
Run: `swift test --package-path DashboardKit` → all pass.
Run both app builds:

```bash
SIM=B9BB0E3F-E390-472F-AD17-952DA5298A94
for s in ComputedDashboard StructDashboard; do
  xcodebuild -project ComputedPropertiesView.xcodeproj -scheme $s -destination "id=$SIM" -derivedDataPath build/DerivedData build -quiet || exit 1
done; echo BOTH-BUILT
```

Expected: `BOTH-BUILT`. Then `swiftlint lint --config ~/.swiftlint.yml --config .swiftlint.yml` → 0 violations.

- [ ] **Step 7: Look at it in the simulator, including the double-tap check (Review Focus 3)**

Install and launch the Computed app (Debug) with `-intensity light` on `$SIM`. With a device-interaction subagent (non-workspace session), check and report:
- The start screen shows "Computed properties", the explanation line, "Light · 1,000 transactions", and an enabled **Open Dashboard** button. The HUD at the top reads "Tap something to time it".
- Tapping **Open Dashboard** slides the dashboard in, and the HUD then reads `Open N ms (first frame M ms)`.
- **Back** returns to the start screen.
- **Double-tap** Open Dashboard quickly (`d x y`). One Back must return to the start screen, proving only one dashboard was pushed.

- [ ] **Step 8: Commit**

```bash
git add DashboardKit
git commit -F - <<'EOF'
feat: add start screen, timed dashboard navigation, and HUD latency readout

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Spike — does the push completion mark the end of the slide-in?

**Files:** none (verification only; results go to the ledger).

**Interfaces:** Consumes the Task 3 build. Produces a go / no-go decision.

- [ ] **Step 1: Measure opens in both apps**

For each app (Debug, `-intensity light`), have a device-interaction subagent do this three times: tap **Open Dashboard**, wait 1 s (`w 1`), record the HUD's `Open N ms (first frame M ms)`, tap **Back**, wait 1 s.

- [ ] **Step 2: Decide**

- **Go** if in every run `N − M ≥ 300` ms: the completion fires at the end of the ~0.35–0.5 s push, not at its start. Record the six (N, M) pairs in the ledger and continue.
- **Stop** if `N − M < 300` ms in any run, or if N ≈ M. The completion doesn't track the push. **Stop and ask the user** whether to switch to the SwiftUI-driven slide-in (`.transition(.move(edge: .trailing))` with the same `withAnimation` completion), which isn't a `NavigationStack` push. Don't implement the fallback without their answer.

---

### Task 5: Timed taps inside the dashboard (both apps)

Invoke the `swiftui-specialist` skill before editing the views (AGENTS.md requirement).

**Files:**
- Modify: `ComputedDashboard/DashboardView.swift` (summary, timeRange, and transactions marker blocks)
- Modify: `StructDashboard/Sections/AccountSummarySection.swift`, `TimeRangeSection.swift`, `RecentTransactionsSection.swift`

**Interfaces:**
- Consumes (Task 2): `InteractionTimer.shared.begin(_:)`, `Binding.timed(_:)`.
- Produces: the same three edits in both apps' section bodies.

- [ ] **Step 1: Apply identical edits to both apps with one script**

```bash
cd /Users/joeyjarosz/Experiments/SwiftUIPerformance/ComputedPropertiesView
python3 - <<'EOF'
import glob
files = ['ComputedDashboard/DashboardView.swift'] + sorted(glob.glob('StructDashboard/Sections/*.swift'))
edits = [
    ("                    hideBalances.toggle()\n",
     "                    InteractionTimer.shared.begin(.toggleBalances)\n                    hideBalances.toggle()\n"),
    ('Picker("Time range", selection: $timeRange) {', 'Picker("Time range", selection: $timeRange.timed(.timeRange)) {'),
    ('Toggle("Pending only", isOn: $showPendingOnly)', 'Toggle("Pending only", isOn: $showPendingOnly.timed(.pendingOnly))'),
]
counts = {old: 0 for old, _ in edits}
for path in files:
    text = open(path).read()
    for old, new in edits:
        n = text.count(old)
        counts[old] += n
        text = text.replace(old, new)
    open(path, 'w').write(text)
for old, n in counts.items():
    assert n == 2, (old, n)   # exactly once per app
print("edited both apps:", {old[:30]: n for old, n in counts.items()})
EOF
```

Expected: `edited both apps:` with each count `2`.

- [ ] **Step 2: Parity**

Run: `Scripts/check-section-parity.sh`
Expected: six `✓`.

- [ ] **Step 3: Build and lint**

Run the two-app build loop from Task 3, Step 6 → `BOTH-BUILT`. Then SwiftLint → 0 violations.

- [ ] **Step 4: Commit**

```bash
git add ComputedDashboard StructDashboard
git commit -F - <<'EOF'
feat: time eye, pending-only, and time-range taps in both dashboards

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: Badge and readout check (Review Focus 5)**

Launch the Structs app (Debug) with `-intensity light -showEvaluationBadges`, open the dashboard, and with a device-interaction subagent read each badge by its accessibility label ("<section> section body evaluated N times"):
- Tap the eye button. Only **summary** should increase, and the HUD should read `Balances N ms`.
- Toggle **Pending only**. Only **transactions** should increase, and the HUD should read `Pending only N ms`.
- Tap **Week**. All six should increase (control case), and the HUD should read `Time range N ms`.

If any other section's count moves, stop and report the counts. That would mean the `timed` binding changed invalidation.

---

### Task 6: Measurements and Instruments intervals

**Files:** none (verification only; results go to the ledger; **not** to `Journal.md`).

- [ ] **Step 1: Release builds**

Build both apps with `-configuration Release` (same loop as Task 3, Step 6, adding `-configuration Release`) and install both `Release-iphonesimulator` apps on `$SIM`.

- [ ] **Step 2: Timings in both apps**

For each app, launch with `-intensity heavy`. With one device-interaction subagent, record the HUD readout after each of these:
- Open, Back, done three times (the control case).
- Open, then three eye taps, three Pending only toggles, and three time-range changes (Week / Month / Quarter).

Record every reading in the ledger as simulator-only numbers.

- [ ] **Step 3: Points of Interest intervals appear in a trace**

Start a recording in the background while an agent performs one open and one eye tap in the running Computed app:

```bash
xcrun xctrace record --device B9BB0E3F-E390-472F-AD17-952DA5298A94 --template 'Time Profiler' \
  --instrument 'Points of Interest' --attach com.hotngui.ComputedDashboard --time-limit 20s \
  --output "$TMPDIR/tap-latency.trace"
xcrun xctrace export --input "$TMPDIR/tap-latency.trace" --toc > "$TMPDIR/tap-latency-toc.xml"
grep -i -E "signpost|points" "$TMPDIR/tap-latency-toc.xml" | head
```

Export the table whose schema mentions signposts or points of interest (`xctrace export --input … --xpath '/trace-toc/run[@number="1"]/data/table[@schema="<schema>"]'`) and confirm intervals named `Interaction` with messages `openDashboard` and `toggleBalances`. If the template or instrument name isn't accepted, run `xcrun xctrace list templates` / `list instruments` and use the closest match. Record the result in the ledger. The trace file stays in `$TMPDIR` and is not committed.

---

### Task 7: Docs and final checks

**Files:**
- Modify: `CLAUDE.md`, `Captures/README.md`, `Journal.md` (feature only)

- [ ] **Step 1: `CLAUDE.md`**

Under **Architecture**, add a bullet:

```markdown
- Start screen and timing: `DemoShell` opens on `StartScreen`; **Open Dashboard** pushes the app's dashboard via
  `navigationDestination(for: DashboardRoute.self)`. `InteractionTimer` (non-observable singleton wrapping the pure
  `LatencyMeter`) times opens (until the slide-in's `withAnimation` completion) and eye / Pending only / time-range taps
  (until the next HUD frame); the HUD shows the latest result and each timing is a Points of Interest interval.
```

Under **Gotchas**, add:

```markdown
- The in-dashboard timing hooks live inside the parity-checked section bodies (`InteractionTimer.shared.begin` on the
  eye button, `.timed(...)` bindings on the Pending toggle and time-range picker). Edit them identically in both apps.
```

- [ ] **Step 2: `Captures/README.md`**

Add a section after "Instruments":

```markdown
## Tap-to-display timings

- The HUD's last line shows the latest timing: `Open 512 ms (first frame 48 ms)` for opening the dashboard (the total
  runs until the slide-in finishes; the first-frame time is the build cost), or e.g. `Pending only 212 ms` for a tap
  inside the dashboard (until the first frame that shows the change).
- Opening and time-range changes are control cases (both apps do the same work). Eye and Pending only taps are the
  comparison: the Computed app re-runs all six sections, the Structs app one.
- In Instruments, each timing is an `Interaction` interval in **Points of Interest** (message = which interaction),
  lined up with the SwiftUI and Hitches tracks.
- Add these to `CaptureNotes.md` under Observations: at least three readings per interaction per app.
```

And in `Captures/CaptureNotes.md`, add under "## HUD after the gesture script":

```markdown
- Open timings (3×):
- Eye / Pending only / Time range timings (3× each):
```

- [ ] **Step 3: `Journal.md` (feature entry only, no device observations)**

Append under **The Journey** a dated entry `### 2026-09-27: Timing the tap` covering:
- Why: slider hitches were hard to *see*, so we added single-number timings people can read.
- The honest prediction: opening costs the same in both apps (first render runs every section once either way), so it
  is a control case; eye and Pending only taps are the real comparison.
- How "displayed" is decided: the next HUD frame for taps, the `withAnimation` completion for the push, and the Task 4
  spike that checked the completion really marks the end of the slide-in.
- **No measured device numbers** (user instruction). Simulator verification may be described qualitatively.

- [ ] **Step 4: Final checks and commit**

Run: `swift test --package-path DashboardKit` → all pass. SwiftLint → 0 violations. `Scripts/check-section-parity.sh` → six `✓`. Both apps build in Debug and Release. `git status --short` shows only this task's docs.

```bash
git add CLAUDE.md Captures Journal.md
git commit -F - <<'EOF'
docs: document tap-to-display timing

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```
