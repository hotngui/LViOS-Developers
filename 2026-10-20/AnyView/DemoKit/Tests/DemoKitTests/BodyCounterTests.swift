import Observation
import Testing
@testable import DemoKit

@MainActor
@Suite struct BodyCounterTests {
    @Test func recordIncrementsAndResetClears() {
        let counter = BodyCounter()
        #expect(counter.count == 0)
        counter.record()
        counter.record()
        #expect(counter.count == 2)
        counter.reset()
        #expect(counter.count == 0)
    }

    /// Review Focus 2: an observable counter would schedule an update from inside the body that recorded it.
    @Test func theCounterIsNotObservable() {
        let counter: Any = BodyCounter()
        #expect(!(counter is any Observable))
    }
}
