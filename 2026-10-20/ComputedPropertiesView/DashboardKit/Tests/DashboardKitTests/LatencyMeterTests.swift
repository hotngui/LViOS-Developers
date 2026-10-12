import Foundation
import Testing
@testable import DashboardKit

@Suite struct LatencyMeterTests {
    let tap = Date(timeIntervalSinceReferenceDate: 1_000)

    func after(_ seconds: TimeInterval) -> Date {
        tap.addingTimeInterval(seconds)
    }

    @Test func aTapCompletesAtTheFirstFrameAfterItsRebuild() {
        var meter = LatencyMeter()
        meter.begin(.pendingOnly, at: tap)
        meter.contentUpdated(at: after(0.0625))
        meter.frameRendered(at: after(0.25))
        meter.frameRendered(at: after(0.5))
        #expect(meter.last == LatencyMeasurement(interaction: .pendingOnly, total: .milliseconds(250)))
        #expect(!meter.isTiming)
    }

    @Test func anOpenAlsoCompletesAtItsFirstFrame() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.contentUpdated(at: after(0.0625))
        meter.frameRendered(at: after(0.125))
        #expect(meter.last == LatencyMeasurement(interaction: .openDashboard, total: .milliseconds(125)))
    }

    @Test func framesAtOrBeforeTheTapAreIgnoredEvenAfterARebuild() {
        var meter = LatencyMeter()
        meter.begin(.toggleBalances, at: tap)
        meter.contentUpdated(at: tap)
        meter.frameRendered(at: tap)
        meter.frameRendered(at: after(-0.1))
        #expect(meter.last == nil)
        #expect(meter.isTiming)
        meter.frameRendered(at: after(0.125))
        #expect(meter.last?.total == .milliseconds(125))
    }

    /// A frame stamped before the latest rebuild (e.g. the HUD drawn later in the same update pass) doesn't show it.
    @Test func framesDatedBeforeTheLatestRebuildAreIgnored() {
        var meter = LatencyMeter()
        meter.begin(.timeRange, at: tap)
        meter.contentUpdated(at: after(0.0625))
        meter.contentUpdated(at: after(0.25))
        meter.frameRendered(at: after(0.125))
        #expect(meter.last == nil)
        meter.frameRendered(at: after(0.5))
        #expect(meter.last == LatencyMeasurement(interaction: .timeRange, total: .milliseconds(500)))
    }

    /// Seen in a trace: the HUD can draw a frame dated just after the tap during the tap's own update pass, before any
    /// section has been rebuilt. That frame doesn't show the result, so it must not end the timing.
    @Test func aFrameBeforeAnySectionRebuildDoesNotCompleteTheTiming() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.frameRendered(at: after(0.001))
        #expect(meter.last == nil)
        #expect(meter.isTiming)
        meter.contentUpdated(at: after(0.0625))
        meter.frameRendered(at: after(0.25))
        #expect(meter.last == LatencyMeasurement(interaction: .openDashboard, total: .milliseconds(250)))
    }

    /// A first rebuild long after the tap belongs to something else (say, a later slider drag), not to this tap.
    @Test func aFirstRebuildLongAfterTheTapDropsTheTiming() {
        var meter = LatencyMeter()
        meter.begin(.toggleBalances, at: tap)
        meter.contentUpdated(at: after(1.5))
        #expect(!meter.isTiming)
        meter.frameRendered(at: after(1.75))
        #expect(meter.last == nil)
    }

    /// Only the start of the rebuild is bounded, so a genuinely slow update still gets measured.
    @Test func aSlowUpdateWithAPromptRebuildStillCompletes() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.contentUpdated(at: after(0.125))
        meter.frameRendered(at: after(2.5))
        #expect(meter.last == LatencyMeasurement(interaction: .openDashboard, total: .milliseconds(2_500)))
    }

    @Test func aSecondTapReplacesAnUnfinishedOne() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.begin(.timeRange, at: after(0.25))
        meter.contentUpdated(at: after(0.375))
        meter.frameRendered(at: after(0.5))
        #expect(meter.last == LatencyMeasurement(interaction: .timeRange, total: .milliseconds(250)))
    }

    @Test func framesWithNothingPendingDoNothing() {
        var meter = LatencyMeter()
        meter.frameRendered(at: tap)
        #expect(meter.last == nil)
        meter.begin(.pendingOnly, at: tap)
        meter.contentUpdated(at: after(0.0625))
        meter.frameRendered(at: after(0.25))
        let completed = meter.last
        meter.frameRendered(at: after(1))
        #expect(meter.last == completed)
    }

    @Test func rebuildsWithNothingPendingDoNotCountForALaterTap() {
        var meter = LatencyMeter()
        meter.contentUpdated(at: tap)
        meter.begin(.pendingOnly, at: after(0.125))
        meter.frameRendered(at: after(0.375))
        #expect(meter.last == nil)
    }

    @Test func cancelDiscardsThePendingTiming() {
        var meter = LatencyMeter()
        meter.begin(.openDashboard, at: tap)
        meter.cancel()
        meter.contentUpdated(at: after(0.0625))
        meter.frameRendered(at: after(0.125))
        #expect(meter.last == nil)
        #expect(!meter.isTiming)
    }
}
