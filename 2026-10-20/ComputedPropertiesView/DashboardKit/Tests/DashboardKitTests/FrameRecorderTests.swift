import Foundation
import Testing
@testable import DashboardKit

@Suite @MainActor struct FrameRecorderTests {
    let start = Date(timeIntervalSinceReferenceDate: 5_000)

    /// Seen on the simulator: after the app came back from the background the HUD reported the time away as one
    /// 8,450 ms frame. A frame drawn during the transition out re-armed the baseline right before the gap.
    @Test func framesWhileNotActiveAreIgnoredAndTheTimeAwayIsNotAHitch() {
        let recorder = FrameRecorder()
        for index in 0...60 {
            _ = recorder.record(frameAt: start.addingTimeInterval(Double(index) / 60))
        }
        recorder.pause()
        _ = recorder.record(frameAt: start.addingTimeInterval(1.05))
        recorder.resume()
        let back = start.addingTimeInterval(9.5)
        _ = recorder.record(frameAt: back)
        let stats = recorder.record(frameAt: back.addingTimeInterval(1.0 / 60))
        #expect(stats.hitchCount == 0)
        #expect(stats.worstFrame < .milliseconds(20))
    }
}
