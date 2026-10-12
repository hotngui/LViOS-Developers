import Foundation

/// Spending for one category on one day: a single stacked bar segment in the spending chart.
public struct DailyCategoryTotal: Identifiable, Hashable, Sendable {
    public struct Key: Hashable, Sendable {
        public let day: Date
        public let category: TransactionCategory
    }

    public let key: Key
    /// Positive amount spent.
    public let total: Decimal

    public var id: Key { key }
    public var day: Date { key.day }
    public var category: TransactionCategory { key.category }

    /// `total` as a `Double`, the value type Swift Charts plots.
    public var amount: Double { NSDecimalNumber(decimal: total).doubleValue }
}
