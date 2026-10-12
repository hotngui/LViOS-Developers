import Testing
@testable import DemoKit

@MainActor
@Suite struct FrameMeterViewTests {
    /// Review Focus 1: the reset button starts a take, so both counts have to go back to zero together.
    @Test func resettingTheCountersClearsAppearancesAndBodies() {
        AppearanceCounter.shared.record()
        BodyCounter.shared.record()
        BodyCounter.shared.record()
        FrameMeterView.resetCounters()
        #expect(AppearanceCounter.shared.count == 0)
        #expect(BodyCounter.shared.count == 0)
    }
}
