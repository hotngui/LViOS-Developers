import Foundation

/// Spending at one merchant within a range.
public struct MerchantTotal: Identifiable, Hashable, Sendable {
    public let merchant: String
    /// Positive amount spent.
    public let total: Decimal
    public let count: Int

    public var id: String { merchant }
    public var amount: Double { NSDecimalNumber(decimal: total).doubleValue }
}
