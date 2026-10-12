import Foundation

/// One simulated pending charge arriving in the live-activity card.
public struct LiveArrival: Identifiable, Hashable, Sendable {
    /// The tick that produced it; increases by one per arrival.
    public let id: Int
    public let merchant: String
    /// Positive amount charged.
    public let amount: Decimal

    /// `amount` as a `Double`, the type Swift Charts plots.
    public var value: Double { NSDecimalNumber(decimal: amount).doubleValue }
}
