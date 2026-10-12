/// The dashboard's sections in display order, used to label each section's "body runs" count.
public enum DashboardSection: String, CaseIterable, Sendable {
    case live, summary, timeRange, budget, chart, categories, transactions
    case cashFlow, topMerchants, largestTransactions, weekdayPattern, spendingCalendar, categoryTrends, versusPrevious
    case upcomingBills, subscriptions, savingsGoal
}
