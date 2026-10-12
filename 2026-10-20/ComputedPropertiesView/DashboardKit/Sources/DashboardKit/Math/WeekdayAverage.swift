import Foundation

/// Average daily spending on one weekday (1…7, in the calendar's numbering) within a range.
public struct WeekdayAverage: Identifiable, Hashable, Sendable {
    public let weekday: Int
    public let average: Decimal

    public var id: Int { weekday }
    public var amount: Double { NSDecimalNumber(decimal: average).doubleValue }
}
