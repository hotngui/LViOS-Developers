import Testing
@testable import DemoKit

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

    @Test func the60HzBaselineOnlyFlagsLongerFrames() {
        let steady = Array(repeating: frame60, count: 120)
        #expect(feed(steady).hitchCount == 0)
        #expect(abs(feed(steady).framesPerSecond - 60) < 0.1)
        #expect(feed(steady + [.milliseconds(25)]).hitchCount == 0)
        #expect(feed(steady + [.milliseconds(40)]).hitchCount == 1)
    }

    @Test func resetClearsEverything() {
        var stats = feed(Array(repeating: frame120, count: 10) + [.milliseconds(50)])
        stats.reset()
        #expect(stats == FrameStats())
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == .zero)
        #expect(stats.framesPerSecond == 0)
    }

    @Test func theFirstFrameAfterAPauseIsNotAHitch() {
        var stats = feed(Array(repeating: frame120, count: 60))
        stats.pause()
        stats.record(frameAt: .seconds(30))
        stats.record(frameAt: .seconds(30) + frame120)
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == frame120)
    }

    @Test func aGapBeyondThePauseThresholdIsNotAHitch() {
        let steady = Array(repeating: frame120, count: 60)
        let stats = feed(steady + [.seconds(30)] + steady)
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame == frame120)
    }

    /// Review Focus 5: a `TimelineView` re-render of the same date must not count as a frame or corrupt the baseline.
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

    /// Live FPS must reflect the last second, not the whole 120-frame window; at 4 FPS that window would be 30 seconds.
    @Test func framesPerSecondReflectsTheLastSecond() {
        let stats = feed(Array(repeating: frame60, count: 60) + Array(repeating: .milliseconds(250), count: 10))
        #expect(abs(stats.framesPerSecond - 4) < 0.5)
    }

    @Test func durationConvertsToSecondsAndMilliseconds() {
        #expect(Duration.milliseconds(25).inMilliseconds == 25)
        #expect(Duration.seconds(1.5).inSeconds == 1.5)
    }
}
