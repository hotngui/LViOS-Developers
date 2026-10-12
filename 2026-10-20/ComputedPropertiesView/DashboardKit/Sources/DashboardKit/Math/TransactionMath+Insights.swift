import Foundation

/// Derived work for the ten additional dashboard sections. Pure functions, like the rest of `TransactionMath`.
extension TransactionMath {
    /// The start of every day in `range`.
    static func days(in range: Range<Date>, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: range.lowerBound)
        while day < range.upperBound {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The running net amount at the end of each day in `range`, starting from zero.
    public static func dailyBalances(
        of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar
    ) -> [DailyValue] {
        var netByDay: [Date: Decimal] = [:]
        for transaction in transactions where range.contains(transaction.date) {
            netByDay[calendar.startOfDay(for: transaction.date), default: 0] += transaction.amount
        }
        var running = Decimal.zero
        return days(in: range, calendar: calendar).map { day in
            running += netByDay[day, default: 0]
            return DailyValue(day: day, value: running)
        }
    }

    /// Spending on each day in `range`, including days with none.
    public static func dailySpend(
        of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar
    ) -> [DailyValue] {
        var spendByDay: [Date: Decimal] = [:]
        for transaction in transactions where transaction.amount < 0 && range.contains(transaction.date) {
            spendByDay[calendar.startOfDay(for: transaction.date), default: 0] -= transaction.amount
        }
        return days(in: range, calendar: calendar).map { DailyValue(day: $0, value: spendByDay[$0, default: 0]) }
    }

    /// Merchants by spending, largest first (ties by name).
    public static func topMerchants(of transactions: [AccountTransaction], limit: Int) -> [MerchantTotal] {
        var totals: [String: Decimal] = [:]
        var counts: [String: Int] = [:]
        for transaction in transactions where transaction.amount < 0 {
            totals[transaction.merchant, default: 0] -= transaction.amount
            counts[transaction.merchant, default: 0] += 1
        }
        let sorted = totals
            .map { MerchantTotal(merchant: $0.key, total: $0.value, count: counts[$0.key, default: 0]) }
            .sorted { $0.total != $1.total ? $0.total > $1.total : $0.merchant < $1.merchant }
        return Array(sorted.prefix(limit))
    }

    /// The biggest expenses, largest first (ties newest first).
    public static func largestExpenses(of transactions: [AccountTransaction], limit: Int) -> [AccountTransaction] {
        let sorted = transactions
            .filter { $0.amount < 0 }
            .sorted { $0.amount != $1.amount ? $0.amount < $1.amount : $0.date > $1.date }
        return Array(sorted.prefix(limit))
    }

    /// Average daily spending per weekday over the days in `range` (days without spending count as zero).
    public static func weekdayAverages(
        of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar
    ) -> [WeekdayAverage] {
        var sums: [Int: Decimal] = [:]
        var dayCounts: [Int: Int] = [:]
        for day in dailySpend(of: transactions, in: range, calendar: calendar) {
            let weekday = calendar.component(.weekday, from: day.day)
            sums[weekday, default: 0] += day.value
            dayCounts[weekday, default: 0] += 1
        }
        return (1...7).map { weekday in
            let dayCount = dayCounts[weekday, default: 0]
            let average = dayCount > 0 ? sums[weekday, default: 0] / Decimal(dayCount) : 0
            return WeekdayAverage(weekday: weekday, average: average)
        }
    }

    /// Each spending category's daily totals across `range`.
    public static func categorySeries(
        of transactions: [AccountTransaction], in range: Range<Date>, calendar: Calendar
    ) -> [CategorySeries] {
        var lookup: [DailyCategoryTotal.Key: Decimal] = [:]
        for bin in dailyTotals(of: transactions.filter { range.contains($0.date) }, calendar: calendar) {
            lookup[bin.key] = bin.total
        }
        let allDays = days(in: range, calendar: calendar)
        return TransactionCategory.spending.map { category in
            let points = allDays.map { day in
                DailyValue(day: day, value: lookup[DailyCategoryTotal.Key(day: day, category: category), default: 0])
            }
            return CategorySeries(category: category, points: points)
        }
    }

    /// Spending per category now vs the previous period, for all eight spending categories.
    public static func categoryComparison(current: [AccountTransaction], previous: [AccountTransaction]) -> [CategoryChange] {
        let now = categoryTotals(of: current)
        let before = categoryTotals(of: previous)
        return TransactionCategory.spending.map { category in
            CategoryChange(
                category: category,
                current: now.first { $0.category == category }?.total ?? 0,
                previous: before.first { $0.category == category }?.total ?? 0
            )
        }
    }

    /// Merchants charged the same amount at least three times, 27–32 days apart. Sorted by merchant.
    public static func recurringCharges(of transactions: [AccountTransaction], calendar: Calendar) -> [RecurringCharge] {
        let byMerchant = Dictionary(grouping: transactions.filter { $0.amount < 0 }, by: \.merchant)
        var result: [RecurringCharge] = []
        for (merchant, charges) in byMerchant where charges.count >= 3 {
            let sorted = charges.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last else { continue }
            guard sorted.allSatisfy({ $0.amount == first.amount }) else { continue }
            let isMonthly = zip(sorted, sorted.dropFirst()).allSatisfy { earlier, later in
                (27.0...32.0).contains(later.date.timeIntervalSince(earlier.date) / 86_400)
            }
            guard isMonthly, let next = calendar.date(byAdding: .month, value: 1, to: last.date) else { continue }
            result.append(
                RecurringCharge(
                    merchant: merchant, category: first.category, amount: -first.amount, lastDate: last.date, nextDate: next
                )
            )
        }
        return result.sorted { $0.merchant < $1.merchant }
    }

    /// Charges due after `anchor` and no later than `days` days after it, soonest first.
    public static func upcomingBills(
        _ charges: [RecurringCharge], after anchor: Date, within days: Int, calendar: Calendar
    ) -> [RecurringCharge] {
        let end = calendar.date(byAdding: .day, value: days, to: anchor) ?? anchor
        return charges.filter { $0.nextDate > anchor && $0.nextDate <= end }.sorted { $0.nextDate < $1.nextDate }
    }

    /// Fraction of the savings goal reached, clamped to 0…1. A goal ≤ 0 reads as reached if anything was saved.
    public static func savingsProgress(net: Decimal, goal: Decimal) -> Double {
        guard goal > 0 else { return net > 0 ? 1 : 0 }
        return min(max(NSDecimalNumber(decimal: net / goal).doubleValue, 0), 1)
    }
}
