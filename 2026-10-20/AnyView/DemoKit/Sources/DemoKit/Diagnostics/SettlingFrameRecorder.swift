import Foundation

/// The compact HUD's recorder: a `FrameRecorder` that restarts its statistics by itself once frame pacing has settled
/// after a load. A plain class (not `@Observable`), so recording a frame from inside the HUD's body never schedules
/// another update.
@MainActor
final class SettlingFrameRecorder {
    private let recorder = FrameRecorder()
    private var detector = SettleDetector()
    /// The hitch count after the previous frame, to tell whether the current frame was a hitch.
    private var lastHitchCount = 0
    /// The previous frame's timestamp. A repeated or earlier one is a re-render, not a frame.
    private var lastFrame: Duration?
    private var isPaused = false

    /// True from a load until the statistics restart.
    var isSettling: Bool { detector.isArmed }

    /// A load happened: wait for frame pacing to settle, then restart the statistics.
    func arm() {
        detector.arm()
    }

    /// Records the frame whose timeline date is `date` and returns the statistics to show.
    func record(frameAt date: Date) -> FrameStats {
        let stats = recorder.record(frameAt: date)
        let timestamp = Duration.seconds(date.timeIntervalSinceReferenceDate)
        if isPaused { return stats }
        if let lastFrame, timestamp <= lastFrame { return stats }
        lastFrame = timestamp
        let wasHitch = stats.hitchCount > lastHitchCount
        lastHitchCount = stats.hitchCount
        guard detector.frame(at: timestamp, wasHitch: wasHitch) else { return stats }
        return restart()
    }

    /// The reset button: restart the statistics now and stop waiting.
    func reset() {
        detector.disarm()
        restart()
    }

    /// The scene left the foreground: ignore frames until `resume()`.
    func pause() {
        isPaused = true
        recorder.pause()
    }

    /// The scene is active again. If a load was settling, the wait starts over, so time away never counts.
    func resume() {
        isPaused = false
        recorder.resume()
        if detector.isArmed {
            detector.arm()
        }
    }

    @discardableResult
    private func restart() -> FrameStats {
        recorder.reset()
        lastHitchCount = 0
        return FrameStats()
    }
}
