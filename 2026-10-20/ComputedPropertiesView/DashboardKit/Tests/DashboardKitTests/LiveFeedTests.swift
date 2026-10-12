import Foundation
import Testing
@testable import DashboardKit

@Suite struct LiveFeedTests {
    @Test func arrivalsAreDeterministicPerTickAndWithinRange() {
        #expect(LiveFeed.arrival(at: 5) == LiveFeed.arrival(at: 5))
        let arrivals = (0..<200).map { LiveFeed.arrival(at: $0) }
        #expect(Set(arrivals.map(\.merchant)).count > 1)
        #expect(arrivals.allSatisfy { $0.amount >= Decimal(99) / 100 && $0.amount <= 25 })
        #expect(arrivals.map(\.id) == Array(0..<200))
    }

    @Test func nextAppendsTheFollowingTickAndKeepsTheLastThirty() {
        var arrivals = LiveFeed.next(after: [])
        #expect(arrivals.map(\.id) == [0])
        for _ in 0..<34 {
            arrivals = LiveFeed.next(after: arrivals)
        }
        #expect(arrivals.count == 30)
        #expect(arrivals.map(\.id) == Array(5...34))
    }
}
