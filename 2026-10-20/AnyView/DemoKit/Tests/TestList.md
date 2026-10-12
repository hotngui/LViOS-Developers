# DemoKit Test List

Written before the tests, per AGENTS.md. Each line becomes one Swift Testing test.

## CardKind (CardKindTests)
- There are five kinds, in the order stat, gauge, toggle, sparkline, pulse.

## SeededRandomGenerator (SeededRandomGeneratorTests)
- Seed 0 produces the published SplitMix64 reference values.
- The same seed produces the same sequence.
- Different seeds produce different sequences.

## CardGenerator (CardGeneratorTests)
- The card count matches the intensity's count, and 0 gives an empty array.
- Kinds cycle through all five in order.
- Ids run from 0 to count − 1.
- Base data is identical across two runs with the same seed, and differs for a different seed.
- A tick changes exactly the expected ten cards and leaves every other card equal.
- With fewer than ten cards, a tick changes every card once; with none, nothing.
- A changed sparkline gains one history point whose id is the tick, capped at 30 points.
- The tick sequence is deterministic for a seed.
- After 1,000 ticks every gauge is within 0…1, every other value is ≥ 0, and every tick changed its ten cards.

## DashboardStore (DashboardStoreTests)
- Load populates the cards, sets the loaded time, and bumps the data version.
- Tick bumps the data version and changes only the expected cards.
- Remove drops the id, bumps the version, and later ticks and reloads do not bring it back.
- Reload without new ticks yields an equal array, a newer loaded time, and a bumped version.
- Reset restores removed cards, restarts the tick sequence, and reloads.
- Changing intensity regenerates at the new count and clears removals and the tick count.
- Removing every card leaves an empty store that still ticks, reloads, and resets.

## Intensity, TickRate, ContainerStyle, LaunchArguments, DemoSettings (SettingsTests)
- `-intensity`, `-tickRate`, and `-container` parse regardless of case.
- Missing or unknown values fall back to the defaults (Realistic, Normal, Stack).
- A flag with no value falls back to the default.
- `-liveUpdates off` turns Live off; anything else leaves it on.
- Each level's card count is strictly larger than the previous level's.
- Each rate's interval is strictly shorter than the previous rate's.
- DemoSettings reads all four values from its arguments.

## FrameStats (FrameStatsTests)
- Steady 120 Hz frames produce no hitches.
- One 25 ms frame among 120 Hz frames produces one hitch, and worst frame reports 25 ms.
- The same logic holds at 60 Hz.
- FPS reflects the last second of frames, not the whole baseline window.
- Reset clears counts, FPS, and worst frame.
- The first frame after a pause is not a hitch.
- A gap beyond the pause threshold is not a hitch.
- Repeated or earlier timestamps are ignored.
- Duration converts to seconds and milliseconds.

## AppearanceCounter (AppearanceCounterTests)
- Record increments the count.
- Reset clears it.

## CardCount, `-cards`, the eager variant (SettingsTests)
- The card counts are 10, 100, 200, 300, 400, and 500, in that order, and the standard count is 10.
- `-cards 300` parses to 300.
- A missing flag, a flag with no value, a non-number, and a number outside the six (250) fall back to 10.
- Zero, a negative number, and a decimal fall back to 10.
- The eager variant's name and badge title are "Eager" and "Eager VStack".

## DashboardStore, loading by card count (DashboardStoreTests)
- Loading by card count yields exactly that many cards, sets the loaded time, and bumps the data version.
- Loading by card count clears removals and the tick count.
- Loading by intensity still yields the intensity's card count.
- Loading zero or a negative count leaves an empty store that still loads afterwards.

## SettleDetector (SettleDetectorTests)
- An unarmed detector never asks for a restart.
- An armed detector asks for a restart on the thirtieth calm frame, and only once.
- A hitch restarts the run of calm frames.
- If frames never settle, it asks for a restart at the first frame five seconds or more after the first frame seen.
- Arming again while armed restarts the wait.
- Arming again while armed restarts the five-second limit.
- Disarming stops the wait without asking for a restart.

## SettlingFrameRecorder (SettlingFrameRecorderTests)
- Unarmed, it keeps its hitches, like the recorder it wraps.
- Armed, it restarts the statistics once pacing has settled, and the hitch from before is gone.
- Repeated and earlier timestamps do not count toward settling.
- A second load while settling restarts the wait.
- If frames never settle, the statistics restart after five seconds.
- The reset button ends settling at once.
- Frames while paused do not count, and resuming restarts the wait.

## CompactFrameMeterView (CompactFrameMeterViewTests)
- The card count label reads "1 card" for exactly one card and "n cards" otherwise.
- Resuming when nothing is settling does not start a wait, and earlier hitches are kept.
- Time away from the app is not counted as a hitch.

## BodyCounter (BodyCounterTests)
- Record increments the count, and reset clears it.
- The counter is not observable, so recording from a body never schedules another update.

## CardChrome (CardChromeTests)
- The chrome records one body run each time its body runs.

## FrameMeterView (FrameMeterViewTests)
- Resetting the counters clears both Appearances and Bodies.

## The nested variant (SettingsTests)
- The nested variant's name and badge title are "Nested" and "Nested + stable id", and its explanation is one line.

## Massive and Absurd (SettingsTests)
- Massive has 2,000 cards and Absurd 5,000, they are titled "Massive" and "Absurd", and they come last, after Extreme.
- `-intensity massive` and `-intensity absurd` parse in any case, and an unknown level still falls back to Realistic.

## The wrapped variant (SettingsTests)
- The wrapped variant's name and badge title are "Wrapped" and "Wrapped + stable id", and its explanation is one line.
