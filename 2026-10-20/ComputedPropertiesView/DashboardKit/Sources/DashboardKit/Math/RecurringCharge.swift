import Foundation

/// A charge that repeats monthly for the same amount, with its projected next date.
public struct RecurringCharge: Identifiable, Hashable, Sendable {
    public let merchant: String
    public let category: TransactionCategory
    /// Positive monthly amount.
    public let amount: Decimal
    public let lastDate: Date
    public let nextDate: Date

    public var id: String { merchant }
}
