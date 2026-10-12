/// One spending category's daily totals across a range, for a sparkline.
public struct CategorySeries: Identifiable, Hashable, Sendable {
    public let category: TransactionCategory
    public let points: [DailyValue]

    public var id: TransactionCategory { category }
}
