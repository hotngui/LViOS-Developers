import Foundation
import SwiftUI
import Testing
@testable import DashboardKit

@Suite @MainActor struct InteractionTimerTests {
    /// Stands in for view state behind a `Binding`.
    @MainActor
    final class Box {
        var value = false
    }

    @Test func beginFollowedByALaterFrameProducesAMeasurement() {
        let timer = InteractionTimer()
        let tap = Date(timeIntervalSinceReferenceDate: 2_000)
        timer.begin(.toggleBalances, at: tap)
        timer.contentUpdated(at: tap.addingTimeInterval(0.0625))
        timer.frameRendered(at: tap.addingTimeInterval(0.125))
        #expect(timer.last == LatencyMeasurement(interaction: .toggleBalances, total: .milliseconds(125)))
    }

    @Test func cancelDropsThePendingTiming() {
        let timer = InteractionTimer()
        let tap = Date(timeIntervalSinceReferenceDate: 2_000)
        timer.begin(.pendingOnly, at: tap)
        timer.cancel()
        timer.contentUpdated(at: tap.addingTimeInterval(0.0625))
        timer.frameRendered(at: tap.addingTimeInterval(0.125))
        #expect(timer.last == nil)
    }

    @Test func settingThroughATimedBindingChangesTheValueAndStartsTheTimer() {
        let box = Box()
        let timer = InteractionTimer()
        let binding = Binding(get: { box.value }, set: { box.value = $0 })
        binding.timed(.pendingOnly, timer: timer).wrappedValue = true
        #expect(box.value)
        timer.contentUpdated()
        timer.frameRendered(at: .now.addingTimeInterval(1))
        #expect(timer.last?.interaction == .pendingOnly)
    }
}
