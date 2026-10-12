/// Frame-pacing statistics for the HUD. Feed it one timestamp per rendered frame.
///
/// The expected frame interval is the median interval in a rolling window, so the same logic works at 60 Hz and 120 Hz.
/// The median (not the minimum) keeps a one-off short catch-up frame from halving the baseline, and capping it at one
/// 60 Hz frame keeps a dashboard that stays slow from turning its own slowness into the baseline.
/// A frame is a hitch when it takes more than `hitchThreshold` × the expected interval.
public struct FrameStats: Sendable, Equatable {
    public static let hitchThreshold = 1.5
    /// Backstop for a missed `pause()`: a gap this long means the app was away, not frozen.
    public static let pauseThreshold: Duration = .seconds(10)
    /// An animating app never aims for fewer than 60 frames per second, so the baseline never exceeds one 60 Hz frame.
    public static let maximumExpectedInterval: Duration = .nanoseconds(16_666_667)
    static let windowSize = 120
    /// How much recent time the FPS readout averages over.
    public static let fpsWindow: Duration = .seconds(1)

    public private(set) var hitchCount = 0
    public private(set) var worstFrame: Duration = .zero
    private var lastTimestamp: Duration?
    private var recentIntervals: [Duration] = []

    public init() {}

    public var expectedInterval: Duration? {
        guard !recentIntervals.isEmpty else { return nil }
        let sorted = recentIntervals.sorted()
        return min(sorted[(sorted.count - 1) / 2], Self.maximumExpectedInterval)
    }

    /// Frames per second over the most recent `fpsWindow` of intervals (at least one), so the readout tracks what is on
    /// screen now rather than averaging the whole baseline window.
    public var framesPerSecond: Double {
        var total = Duration.zero
        var count = 0
        for interval in recentIntervals.reversed() {
            if count > 0, total + interval > Self.fpsWindow { break }
            total += interval
            count += 1
        }
        guard total > .zero else { return 0 }
        return Double(count) / total.inSeconds
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

    /// Call when frames stop for a known reason (the scene left the foreground), so the next gap isn't read as a hitch.
    public mutating func pause() {
        lastTimestamp = nil
    }

    public mutating func reset() {
        self = FrameStats()
    }
}
