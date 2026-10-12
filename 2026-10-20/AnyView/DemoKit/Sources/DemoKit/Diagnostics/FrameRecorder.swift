import Foundation

/// Holds the HUD's `FrameStats`. A plain class (not `@Observable`), so recording a frame from inside the HUD's
/// body never schedules another update.
@MainActor
final class FrameRecorder {
    private var stats = FrameStats()
    /// True from the moment the scene leaves `.active` until it's `.active` again.
    private var isPaused = false

    /// Records the frame whose timeline date is `date` and returns the updated statistics.
    func record(frameAt date: Date) -> FrameStats {
        if !isPaused {
            stats.record(frameAt: .seconds(date.timeIntervalSinceReferenceDate))
        }
        return stats
    }

    /// The scene left the foreground: ignore frames until `resume()`, so the time away is not one giant hitch.
    func pause() {
        isPaused = true
        stats.pause()
    }

    /// The scene is active again. The next frame starts a fresh baseline.
    func resume() {
        isPaused = false
        stats.pause()
    }

    func reset() {
        stats.reset()
    }
}
