import Testing
@testable import DemoKit

@MainActor
@Suite struct AppearanceCounterTests {
    @Test func recordIncrementsAndResetClears() {
        let counter = AppearanceCounter()
        #expect(counter.count == 0)
        counter.record()
        counter.record()
        #expect(counter.count == 2)
        counter.reset()
        #expect(counter.count == 0)
    }
}
