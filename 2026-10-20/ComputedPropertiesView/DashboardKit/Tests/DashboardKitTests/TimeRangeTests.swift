import Foundation
import Testing
@testable import DashboardKit

@Suite struct TimeRangeTests {
    static let expectedStarts: [(TimeRange, [Int?])] = [
        (.week, [2026, 9, 24]),
        (.month, [2026, 9, 1]),
        (.quarter, [2026, 7, 3]),
        (.year, [2025, 10, 1])
    ]

    @Test func anchorIsSeptember30th2026() {
        #expect(Fixture.ymd(DemoClock.anchorDate) == [2026, 9, 30])
    }

    @Test(arguments: TimeRangeTests.expectedStarts)
    func rangeStartsTheRightNumberOfDaysBeforeTheEndOfTheAnchorDay(range: TimeRange, expectedStart: [Int?]) {
        let dates = range.dateRange()
        #expect(Fixture.ymd(dates.lowerBound) == expectedStart)
        #expect(dates.upperBound == DemoClock.anchorDate.addingTimeInterval(Fixture.secondsPerDay))
        #expect(dates.upperBound.timeIntervalSince(dates.lowerBound) == TimeInterval(range.dayCount) * Fixture.secondsPerDay)
    }

    @Test func thereAreEightSpendingCategoriesAndIncomeIsNotOne() {
        #expect(TransactionCategory.spending.count == 8)
        #expect(!TransactionCategory.spending.contains(.income))
    }
}
