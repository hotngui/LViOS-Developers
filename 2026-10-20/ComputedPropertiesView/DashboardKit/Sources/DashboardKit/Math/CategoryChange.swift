import Foundation

/// Spending in one category for the current range and the equally long range before it.
public struct CategoryChange: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    public let current: Decimal
    public let previous: Decimal

    public var id: TransactionCategory { category }
    public var difference: Decimal { current - previous }
}
