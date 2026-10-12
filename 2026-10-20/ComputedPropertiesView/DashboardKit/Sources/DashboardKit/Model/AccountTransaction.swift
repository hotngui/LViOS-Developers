import Foundation

/// One account transaction. Income is positive, spending is negative.
///
/// Named `AccountTransaction` rather than `Transaction` because `SwiftUI.Transaction` already exists.
public struct AccountTransaction: Identifiable, Hashable, Sendable {
    public let id: Int
    public let date: Date
    public let merchant: String
    public let category: TransactionCategory
    public let amount: Decimal
    public let isPending: Bool

    public var isIncome: Bool { amount > 0 }
}
