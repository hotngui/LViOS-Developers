import Foundation

/// Spending for one category within a range.
public struct CategoryTotal: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    /// Positive amount spent.
    public let total: Decimal
    /// Fraction of all spending in the range, 0…1.
    public let share: Double

    public var id: TransactionCategory { category }
}
