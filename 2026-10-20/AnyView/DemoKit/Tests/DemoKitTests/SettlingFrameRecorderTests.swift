import Foundation
import Testing
@testable import DemoKit

/// Swift Testing makes a new suite value for every test, so each test gets its own recorder.
@MainActor
@Suite struct SettlingFrameRecorderTests {
    let recorder = SettlingFrameRecorder()
    let frame60: TimeInterval = 1.0 / 60.0

    func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    /// Feeds `count` frames at 60 Hz, the first one a frame after `start`.
    /// Returns the time of the last frame and the statistics it returned.
    @discardableResult
    func feed(count: Int, after start: TimeInterval) -> (end: TimeInterval, stats: FrameStats) {
        var stats = FrameStats()
        var now = start
        for _ in 0..<count {
            now += frame60
            stats = recorder.record(frameAt: date(now))
        }
        return (now, stats)
    }

    @Test func unarmedItKeepsItsHitches() {
        let steady = feed(count: 60, after: 1_000)
        let hitch = recorder.record(frameAt: date(steady.end + 0.5))
        #expect(hitch.hitchCount == 1)
        let after = feed(count: 60, after: steady.end + 0.5)
        #expect(after.stats.hitchCount == 1)
        #expect(after.stats.worstFrame > .milliseconds(499))
        #expect(!recorder.isSettling)
    }

    @Test func armedItRestartsTheStatisticsOncePacingHasSettled() {
        let steady = feed(count: 60, after: 1_000)
        recorder.arm()
        #expect(recorder.isSettling)
        // The build: one two-second frame, which is a hitch.
        let build = recorder.record(frameAt: date(steady.end + 2))
        #expect(build.hitchCount == 1)
        let settling = feed(count: 29, after: steady.end + 2)
        #expect(recorder.isSettling)
        #expect(settling.stats.hitchCount == 1)
        let settled = feed(count: 1, after: settling.end)
        #expect(!recorder.isSettling)
        #expect(settled.stats == FrameStats())
        let later = feed(count: 60, after: settled.end)
        #expect(later.stats.hitchCount == 0)
        #expect(later.stats.worstFrame < .milliseconds(20))
    }

    /// Review Focus 3: a `TimelineView` re-render of the same date is not a frame.
    @Test func repeatedAndEarlierTimestampsDoNotCountTowardSettling() {
        let steady = feed(count: 60, after: 1_000)
        recorder.arm()
        let settling = feed(count: 29, after: steady.end)
        for _ in 0..<10 {
            _ = recorder.record(frameAt: date(settling.end))
            _ = recorder.record(frameAt: date(settling.end - 1))
        }
        #expect(recorder.isSettling)
        feed(count: 1, after: settling.end)
        #expect(!recorder.isSettling)
    }

    /// Review Focus 4.
    @Test func aSecondLoadWhileSettlingRestartsTheWait() {
        let steady = feed(count: 60, after: 1_000)
        recorder.arm()
        let first = feed(count: 20, after: steady.end)
        recorder.arm()
        let second = feed(count: 29, after: first.end)
        #expect(recorder.isSettling)
        feed(count: 1, after: second.end)
        #expect(!recorder.isSettling)
    }

    @Test func ifFramesNeverSettleTheStatisticsRestartAfterFiveSeconds() {
        let steady = feed(count: 60, after: 1_000)
        recorder.arm()
        // 40 ms frames are all hitches against a 60 Hz baseline.
        var now = steady.end
        for _ in 0..<120 {
            now += 0.04
            _ = recorder.record(frameAt: date(now))
        }
        // 4.8 seconds after the load.
        #expect(recorder.isSettling)
        for _ in 0..<10 {
            now += 0.04
            _ = recorder.record(frameAt: date(now))
        }
        // 5.2 seconds after the load.
        #expect(!recorder.isSettling)
    }

    @Test func theResetButtonEndsSettlingAtOnce() {
        let steady = feed(count: 60, after: 1_000)
        _ = recorder.record(frameAt: date(steady.end + 0.5))
        recorder.arm()
        recorder.reset()
        #expect(!recorder.isSettling)
        let after = feed(count: 60, after: steady.end + 0.5)
        #expect(after.stats.hitchCount == 0)
        #expect(after.stats.worstFrame < .milliseconds(20))
    }

    /// Review Focus 5: time away from the app must not use up the wait.
    @Test func framesWhilePausedDoNotCountAndResumingRestartsTheWait() {
        let steady = feed(count: 60, after: 1_000)
        recorder.arm()
        let before = feed(count: 20, after: steady.end)
        recorder.pause()
        let away = feed(count: 100, after: before.end)
        #expect(recorder.isSettling)
        recorder.resume()
        // A minute later: well past the five-second limit if time away counted.
        let back = feed(count: 29, after: away.end + 60)
        #expect(recorder.isSettling)
        feed(count: 1, after: back.end)
        #expect(!recorder.isSettling)
    }

    /// Final review: coming back to the app must not wipe hitches that were recorded before leaving.
    @Test func resumingWhenNotSettlingDoesNotArm() {
        let steady = feed(count: 60, after: 1_000)
        let hitch = recorder.record(frameAt: date(steady.end + 0.5))
        #expect(hitch.hitchCount == 1)
        recorder.pause()
        recorder.resume()
        #expect(!recorder.isSettling)
        #expect(feed(count: 60, after: steady.end + 0.5).stats.hitchCount == 1)
    }

    /// Final review: pause and resume must reach the wrapped recorder.
    @Test func timeAwayIsNotAHitch() {
        let steady = feed(count: 60, after: 1_000)
        recorder.pause()
        feed(count: 30, after: steady.end)
        recorder.resume()
        let back = feed(count: 60, after: steady.end + 3)
        #expect(back.stats.hitchCount == 0)
        #expect(back.stats.worstFrame < .milliseconds(20))
    }
}
