import Foundation

/// One value for one day, e.g. a running balance or that day's spending.
public struct DailyValue: Identifiable, Hashable, Sendable {
    public let day: Date
    public let value: Decimal

    public var id: Date { day }
    /// `value` as a `Double`, the type Swift Charts plots.
    public var amount: Double { NSDecimalNumber(decimal: value).doubleValue }
}
