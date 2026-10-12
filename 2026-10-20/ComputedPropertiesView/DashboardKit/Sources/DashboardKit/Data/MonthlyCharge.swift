/// A fixed charge the sample data repeats every month, so the recurring-charge sections have something real to find.
struct MonthlyCharge: Sendable {
    let merchant: String
    let category: TransactionCategory
    let cents: Int
    /// Day of the month it posts (at 10:00 GMT).
    let day: Int
}
