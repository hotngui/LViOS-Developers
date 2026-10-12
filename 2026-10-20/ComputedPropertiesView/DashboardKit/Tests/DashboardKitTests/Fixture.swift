import Foundation
@testable import DashboardKit

/// Builders for hand-made test data, anchored to the demo clock so dates are easy to reason about.
enum Fixture {
    static let secondsPerDay: TimeInterval = 86_400

    /// A date `dayOffset` days from the anchor day (2026-09-30, GMT) at the given time of day.
    static func date(dayOffset: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let seconds = TimeInterval(dayOffset) * secondsPerDay + TimeInterval(hour * 3_600 + minute * 60)
        return DemoClock.anchorDate.addingTimeInterval(seconds)
    }

    static func transaction(
        _ amount: Decimal, _ category: TransactionCategory, on date: Date,
        merchant: String = "Test Merchant", isPending: Bool = false
    ) -> AccountTransaction {
        AccountTransaction(id: 0, date: date, merchant: merchant, category: category, amount: amount, isPending: isPending)
    }

    /// The year, month, and day of `date` in the demo calendar.
    static func ymd(_ date: Date) -> [Int?] {
        let parts = DemoClock.calendar.dateComponents([.year, .month, .day], from: date)
        return [parts.year, parts.month, parts.day]
    }
}
