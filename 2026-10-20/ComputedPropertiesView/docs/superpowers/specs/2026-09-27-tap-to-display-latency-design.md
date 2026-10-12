# Design: Tap-to-Display Latency (Start Screen + Interaction Timing)

- **Date:** 2026-09-27
- **Status:** Approved in conversation; awaiting written-spec review
- **Builds on:** `docs/superpowers/specs/2026-09-26-computed-vs-struct-views-design.md` (all of its constraints still apply)
- **Conversation record:** `SessionLog.md`

## 1. Purpose

On an iPhone SE (2nd generation), the HUD's hitch count rose while dragging the budget slider in the Computed app, but
the stutter wasn't obvious to the eye. The user wants a delay that is both **visible** and **measurable as one
number**.

### What the user asked for

- A first screen that has just a button; tapping it opens the dashboard.
- A measurement of the delay from the tap until the dashboard is fully displayed, meaning **after the slide-in
  animation finishes**.
- (Chosen in conversation) Also time taps **inside** the dashboard, and show both the full open time and the time to
  the dashboard's first frame.

### What we expect, stated up front

A computed property costs extra on **updates**, not on first display: opening the dashboard runs all six section
bodies once in both apps. So:

| Interaction | Computed app | Structs app | Role |
|---|---|---|---|
| Open dashboard | ≈ same | ≈ same | Control case |
| Eye button (hide/show balances) | re-runs all six sections | re-runs one | The demo |
| Pending only toggle | re-runs all six sections | re-runs one | The demo |
| Time range picker | re-runs all six | re-runs all six | Control case |

These are expectations, not goals. Whatever the devices show gets reported as measured.

## 2. Success criteria

1. Both apps open on a start screen with an **Open Dashboard** button, disabled while data is generating.
2. Tapping the button pushes the app's own `DashboardView` onto a `NavigationStack` using `navigationDestination(for:)`.
   Back returns to the start screen, and each open builds a fresh dashboard.
3. The HUD shows the latest measurement:
   - Opening: **"Open 512 ms (first frame 48 ms)"**. The total ends when the slide-in finishes; the first-frame time
     ends at the first frame that shows the dashboard.
   - In-dashboard taps: **"Pending only 212 ms"**, ending at the first frame that shows the new state.
4. The eye button, Pending only toggle, and time-range picker are timed. The budget slider is not.
5. Every timed interaction appears as an interval in Instruments' **Points of Interest**.
6. The section bodies are still textually identical in both apps (`Scripts/check-section-parity.sh` passes), and all
   tests, SwiftLint, and Debug/Release builds of both apps pass.

## 3. Screens and flow

### Start screen (new, in `DashboardKit/Shell/`)

- Shows the app variant title ("Computed properties" or "View structs") and one line explaining what the app
  demonstrates.
- Shows the current intensity and transaction count.
- **Open Dashboard** button (`Button("Open Dashboard", systemImage: "chart.bar.doc.horizontal")`, `.buttonStyle(.borderedProminent)`):
  - While `TransactionStore` is loading, it's disabled and a `ProgressView` reads "Generating N transactions…".
  - Data generation stays where it is today (at launch and on intensity changes), so the open timing measures only
    building and showing the dashboard.

### Navigation

- `DemoShell` owns a `NavigationStack(path:)` whose root is the start screen, and a
  `navigationDestination(for: DashboardRoute.self)` that builds the dashboard through the app's existing closure.
  **The apps' `App` structs and `DemoShell`'s public initializer don't change.**
- On tap: `InteractionTimer.shared.begin(.openDashboard)`, then `withAnimation { path.append(DashboardRoute()) }
  completion: { InteractionTimer.shared.finish() }`.
- While the dashboard is showing and the intensity changes, the dashboard destination shows the existing
  "Generating transactions…" progress view until the data is ready, as it does today.

### HUD and settings menu

- The HUD moves up a level: it's pinned to the top of the whole `NavigationStack`, so it stays visible, and its frame
  clock keeps running, through the push and on both screens.
- The settings menu (intensity, badges, reset counts, stall) is available on both screens.
- The HUD gains one line showing the latest `LatencyMeasurement` (see §2.3). Before any interaction it reads
  "Tap something to time it".

## 4. Measurement

### Components (all in `DashboardKit`)

| Unit | Responsibility |
|---|---|
| `Interaction` | `enum Interaction: String, CaseIterable, Sendable { openDashboard, toggleBalances, pendingOnly, timeRange }` with a `title: LocalizedStringResource` ("Open", "Balances", "Pending only", "Time range") and `endsAtFirstFrame: Bool` (false only for `openDashboard`). |
| `LatencyMeasurement` | `struct` (Equatable, Sendable): `interaction`, `total: Duration`, `firstFrame: Duration?`. |
| `LatencyMeter` | Pure `struct` (Equatable, Sendable), fully unit-tested. `begin(_:at:)`, `frameRendered(at:)`, `finish(at:)`, and `private(set) var last: LatencyMeasurement?`. |
| `InteractionTimer` | `@MainActor final class`, `static let shared`, **not** `@Observable` (recording must never cause a re-render). Wraps a `LatencyMeter`, stamps times with `Date.now`, exposes `last`, and emits an `OSSignposter` interval (category Points of Interest) per interaction. Test-only instances can be created with `init()`. |
| `Binding.timed(_:timer:)` | `extension Binding`: returns a binding whose setter calls `timer.begin(interaction)` and then sets the value. `timer` defaults to `.shared`. |
| `DashboardRoute` | `struct DashboardRoute: Hashable` used as the navigation value. |
| `StartScreen` | The start screen view described in §3. |

### `LatencyMeter` rules

- `begin(interaction, at: start)` starts a timing. If a timing is already pending, the new one replaces it, so the
  latest tap wins.
- `frameRendered(at: date)`:
  - With nothing pending, or when `date <= start`, it does nothing.
  - For the first frame after `start`, it records `firstFrame = date - start`. If the interaction `endsAtFirstFrame`,
    the timing completes with `total = firstFrame`.
  - Later frames don't change the recorded first frame.
- `finish(at: date)`:
  - With nothing pending, it does nothing.
  - Otherwise it completes with `total = date - start` and whatever `firstFrame` was recorded (`nil` if none).
- Completing a timing sets `last`. `last` keeps the most recent result until the next one completes.

### Where timing starts

- **Start screen button:** `begin(.openDashboard)`, then the animated push. `finish()` runs in the `withAnimation`
  completion.
- **Section bodies** (identical edits in both apps, parity enforced):
  - Summary's eye button: `InteractionTimer.shared.begin(.toggleBalances)` before `hideBalances.toggle()`.
  - Recent transactions: `Toggle("Pending only", isOn: $showPendingOnly.timed(.pendingOnly))`.
  - Time-range picker: `Picker("Time range", selection: $timeRange.timed(.timeRange))`.
- **Where frames come from:** `FrameRecorder.record(frameAt:)`, which the HUD already calls every frame with the
  `TimelineView(.animation)` date, also calls `InteractionTimer.shared.frameRendered(at:)`.

## 5. Testing and verification

### Unit tests (Swift Testing; add to `DashboardKit/Tests/TestList.md` before writing them)

- **`LatencyMeter`:**
  - A tap completes at the first frame after it, with `total == firstFrame == frame - tap`.
  - Frames dated at or before the tap are ignored.
  - An open doesn't complete at its first frame. `finish` completes it with `total` and the recorded `firstFrame`.
  - `finish` before any frame completes with `firstFrame == nil`.
  - A second `begin` before completion replaces the first.
  - `frameRendered` and `finish` with nothing pending leave `last` unchanged.
- **`Binding.timed`:** setting through the binding changes the underlying value and leaves the given timer with that
  interaction pending, which a following frame completes.
- **`InteractionTimer`:** `begin` followed by `frameRendered` at a later date produces a `last` measurement for that
  interaction.

### Simulator verification

1. **Spike first:** confirm that the `withAnimation` completion fires at the **end** of the `NavigationStack` push,
   at least ~0.3 s after the dashboard's first frame. Measure it from the HUD's recorded first-frame and total times
   plus a screen recording. **If the completion fires at the start of the push instead, stop and ask the user** about
   the fallback (a SwiftUI-driven slide-in with `.transition(.move(edge: .trailing))`, which isn't a
   `NavigationStack` push).
2. Open and go back three times in each app. The open totals should be similar across the two apps.
3. At Heavy intensity, time eye-button and Pending-only taps in each app. Compare Computed with Structs. Time-range
   taps are the control case.
4. Badges still behave as before: in the Structs app, an eye tap re-runs only the summary. This proves the `timed`
   binding helper didn't change invalidation.
5. Record a short `xctrace` trace on the simulator and confirm the Points of Interest intervals appear.

The existing checks must keep passing: package tests, SwiftLint, section parity, and Debug and Release builds of both
apps.

## 6. Risks

- **The push completion may not track the UIKit-driven transition.** That's why the spike runs first; the fallback
  needs the user's approval.
- **Resolution is one frame:** 16.7 ms at 60 Hz. Fine for effects measured in tens to hundreds of milliseconds.
- **Closure-based bindings in section bodies:** `timed` builds a new `Binding` each time a section body runs. It only
  feeds that section's own control, and the parent's inputs don't change. Verification step 4 checks this.
- **Points of Interest signposts** are recorded only while Instruments (or `xctrace`) is recording. That's intended.
- **The HUD moves above the navigation bar.** The layout shifts slightly compared with before, identically in both
  apps.

## 7. Documentation and repository

- Work on a new local branch, `feature/tap-latency`, cut from `main`. Nothing is pushed. Merge when the user says so.
- Update `CLAUDE.md` (start screen, timing, signposts) and `Captures/README.md` (how to read the Open and tap
  numbers, and where to find the intervals in Instruments).
- `Journal.md` gets an entry describing the feature only, with **no device observations**, per the user's instruction.
- `SessionLog.md` keeps recording every turn.

## 8. Amendments (2026-09-27, after implementation)

These supersede the matching parts of §2–§5.

- **Decision C (user, after the §5.1 spike failed).** The `withAnimation` completion fired when SwiftUI's own part of the
  update ended, well before the `NavigationStack` slide-in finished. So opens are timed to the dashboard's **first frame**
  and the slide-in (identical in both apps) isn't included. `finish`, `LatencyMeasurement.firstFrame`, and
  `Interaction.endsAtFirstFrame` were removed. The HUD reads "Open N ms (first frame)".
- **HUD at the bottom (user).** A top `safeAreaInset` on the `NavigationStack` covered the navigation bar's Back and gear
  buttons. The single shared HUD is now a bottom `.overlay` that measures its height with `onGeometryChange`, and both
  screens reserve it with `.safeAreaPadding(.bottom, _)`.
- **Rebuild gate.** A timing ends only on a frame dated **after the latest dashboard-section rebuild** since the tap.
  `EvaluationCounter.record` signals each body run to `InteractionTimer.contentUpdated(at:)`. This excludes HUD frames
  drawn during the tap's own update pass, whichever order SwiftUI updates the HUD and the sections in.
- **Stale timings.** The first rebuild must start within **1 s** of the tap, or the timing is dropped rather than
  completed by an unrelated later rebuild. Only the rebuild's start is bounded, so slow updates are still measured.
- **Signpost outcomes.** Replaced, cancelled, and stale timings end their `Interaction` interval with that outcome as the
  message. Completed timings end plainly.
- **Capture guidance.** The first run of an interaction after launch can include one-time costs (seen on the first eye
  tap after a fresh install). Take at least three readings per interaction and discard the first.

