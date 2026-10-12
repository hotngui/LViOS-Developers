import Foundation

/// The derived work each dashboard section does in its body. Pure functions, callable from any isolation.
///
/// Both apps call exactly these functions from their section bodies, so the per-section cost is identical;
/// the only difference between the apps is *how often* each section's body runs.
public enum TransactionMath {
    public static func transactions(_ transactions: [AccountTransaction], in range: Range<Date>) -> [AccountTransaction] {
        transactions.filter { range.contains($0.date) }
    }

    public static func income(of transactions: [AccountTransaction]) -> Decimal {
        transactions.reduce(into: Decimal.zero) { total, transaction in
            if transaction.amount > 0 { total += transaction.amount }
        }
    }

    /// Total spending as a positive amount.
    public static func expenses(of transactions: [AccountTransaction]) -> Decimal {
        transactions.reduce(into: Decimal.zero) { total, transaction in
            if transaction.amount < 0 { total -= transaction.amount }
        }
    }

    public static func net(of transactions: [AccountTransaction]) -> Decimal {
        income(of: transactions) - expenses(of: transactions)
    }

    /// Fraction of the budget used, clamped to 0…1. A $0 budget reads as full if anything was spent.
    public static func budgetUsage(spent: Decimal, budget: Double) -> Double {
        let spentValue = NSDecimalNumber(decimal: spent).doubleValue
        guard budget > 0 else { return spentValue > 0 ? 1 : 0 }
        return min(max(spentValue / budget, 0), 1)
    }

    /// The budget slider's upper bound: twice what was spent in the range, never below $100.
    public static func budgetCeiling(forSpent spent: Decimal) -> Double {
        max((NSDecimalNumber(decimal: spent).doubleValue * 2).rounded(.up), 100)
    }

    /// Spending per category, largest first. Empty when nothing was spent.
    public static func categoryTotals(of transactions: [AccountTransaction]) -> [CategoryTotal] {
        var totals: [TransactionCategory: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 {
            totals[transaction.category, default: 0] -= transaction.amount
        }
        let grandTotal = totals.values.reduce(Decimal.zero, +)
        guard grandTotal > 0 else { return [] }
        return totals
            .map { category, total in
                CategoryTotal(category: category, total: total, share: NSDecimalNumber(decimal: total / grandTotal).doubleValue)
            }
            .sorted { $0.total != $1.total ? $0.total > $1.total : $0.category < $1.category }
    }

    /// Spending per day and category, sorted by day and then category.
    public static func dailyTotals(of transactions: [AccountTransaction], calendar: Calendar) -> [DailyCategoryTotal] {
        var totals: [DailyCategoryTotal.Key: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 {
            let key = DailyCategoryTotal.Key(day: calendar.startOfDay(for: transaction.date), category: transaction.category)
            totals[key, default: 0] -= transaction.amount
        }
        return totals
            .map { DailyCategoryTotal(key: $0.key, total: $0.value) }
            .sorted { ($0.day, $0.category) < ($1.day, $1.category) }
    }

    public static func pendingOnly(_ transactions: [AccountTransaction]) -> [AccountTransaction] {
        transactions.filter(\.isPending)
    }

    public static func newestFirst(_ transactions: [AccountTransaction], limit: Int) -> [AccountTransaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(limit))
    }
}
