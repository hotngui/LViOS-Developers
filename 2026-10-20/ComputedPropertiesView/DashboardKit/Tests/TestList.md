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

## LatencyMeter (LatencyMeterTests)
- A tap completes at the first frame after its rebuild, with total == frame − tap.
- An open also completes at its first frame (the slide-in isn't timed; user decision C).
- Frames dated at or before the tap are ignored even after a section rebuild. (Review Focus 4)
- Frames dated before the latest rebuild are ignored (order-proof against SwiftUI's update order).
- A frame before any section rebuild doesn't complete the timing.
- A first rebuild more than 1 s after the tap drops the timing.
- A slow update whose rebuild started promptly still completes (only the rebuild's start is bounded).
- A second begin before completion replaces the first.
- Frames with nothing pending leave last unchanged.
- Rebuilds with nothing pending don't count for a later tap.
- cancel discards the pending timing. (Review Focus 2)

## InteractionTimer and Binding.timed (InteractionTimerTests)
- begin, then a rebuild, then a later frame produces a last measurement for that interaction.
- cancel drops the pending timing.
- Setting through a timed binding changes the value and starts the timer for that interaction.

## EvaluationCounter → InteractionTimer (EvaluationCounterTests)
- Recording a section body run tells the interaction timer the content was rebuilt.

## FrameRecorder (FrameRecorderTests)
- Frames recorded while the scene isn't active are ignored, and the time away isn't a hitch or the worst frame.

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

## AppVariant (AppVariantTests)
- The Computed explanation states the current section count (final review Important 1).
