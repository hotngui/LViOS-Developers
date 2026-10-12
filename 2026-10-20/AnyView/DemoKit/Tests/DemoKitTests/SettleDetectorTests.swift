import Testing
@testable import DemoKit

@Suite struct SettleDetectorTests {
    let frame60: Duration = .nanoseconds(16_666_667)

    /// Feeds `count` calm frames at 60 Hz, the first one a frame after `start`.
    /// Returns how many of them asked for a restart, and the timestamp of the last one.
    func feedCalm(_ detector: inout SettleDetector, count: Int, after start: Duration) -> (restarts: Int, end: Duration) {
        var restarts = 0
        var now = start
        for _ in 0..<count {
            now += frame60
            if detector.frame(at: now, wasHitch: false) {
                restarts += 1
            }
        }
        return (restarts, now)
    }

    /// Feeds one hitch frame and returns whether it asked for a restart. `#expect` cannot call a mutating method
    /// on a value it captures, so the call goes through this function, as it does for `feedCalm`.
    func feedHitch(_ detector: inout SettleDetector, at timestamp: Duration) -> Bool {
        detector.frame(at: timestamp, wasHitch: true)
    }

    @Test func anUnarmedDetectorNeverAsksForARestart() {
        var detector = SettleDetector()
        #expect(feedCalm(&detector, count: 100, after: .zero).restarts == 0)
        #expect(!detector.isArmed)
    }

    @Test func itAsksOnTheThirtiethCalmFrameAndOnlyOnce() {
        var detector = SettleDetector()
        detector.arm()
        let early = feedCalm(&detector, count: 29, after: .zero)
        #expect(early.restarts == 0)
        #expect(detector.isArmed)
        let thirtieth = feedCalm(&detector, count: 1, after: early.end)
        #expect(thirtieth.restarts == 1)
        #expect(!detector.isArmed)
        #expect(feedCalm(&detector, count: 100, after: thirtieth.end).restarts == 0)
    }

    @Test func aHitchRestartsTheRunOfCalmFrames() {
        var detector = SettleDetector()
        detector.arm()
        let early = feedCalm(&detector, count: 29, after: .zero)
        let hitch = early.end + .milliseconds(100)
        #expect(!feedHitch(&detector, at: hitch))
        let again = feedCalm(&detector, count: 29, after: hitch)
        #expect(again.restarts == 0)
        #expect(feedCalm(&detector, count: 1, after: again.end).restarts == 1)
    }

    @Test func itStopsWaitingFiveSecondsAfterTheFirstFrame() {
        var detector = SettleDetector()
        detector.arm()
        let start = Duration.seconds(100)
        // Every frame is a hitch, 40 ms apart. Frame 125 is the first one five seconds after frame 0.
        for index in 0..<125 {
            #expect(!feedHitch(&detector, at: start + .milliseconds(40 * index)))
        }
        #expect(feedHitch(&detector, at: start + .milliseconds(40 * 125)))
        #expect(!detector.isArmed)
    }

    @Test func armingAgainRestartsTheWait() {
        var detector = SettleDetector()
        detector.arm()
        let early = feedCalm(&detector, count: 20, after: .zero)
        detector.arm()
        let again = feedCalm(&detector, count: 29, after: early.end)
        #expect(again.restarts == 0)
        #expect(feedCalm(&detector, count: 1, after: again.end).restarts == 1)
    }

    /// Review Focus 4: a second load while settling restarts the five-second limit too.
    @Test func armingAgainRestartsTheFiveSecondLimit() {
        var detector = SettleDetector()
        detector.arm()
        // Four seconds of hitches, 40 ms apart.
        for index in 0...100 {
            #expect(!feedHitch(&detector, at: .milliseconds(40 * index)))
        }
        detector.arm()
        // The first frame after arming again is frame 101, so the limit is reached at frame 226, not frame 125.
        for index in 101..<226 {
            #expect(!feedHitch(&detector, at: .milliseconds(40 * index)))
        }
        #expect(feedHitch(&detector, at: .milliseconds(40 * 226)))
    }

    @Test func disarmingStopsTheWaitWithoutAskingForARestart() {
        var detector = SettleDetector()
        detector.arm()
        _ = feedCalm(&detector, count: 10, after: .zero)
        detector.disarm()
        #expect(detector == SettleDetector())
        #expect(feedCalm(&detector, count: 100, after: .seconds(1)).restarts == 0)
    }
}
