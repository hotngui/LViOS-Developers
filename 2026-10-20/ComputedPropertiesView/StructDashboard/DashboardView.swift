import DashboardKit
import SwiftUI

/// The same dashboard as the Computed app, but each section is its own `View` struct with narrow inputs.
///
/// This body only forwards inputs. It never filters or aggregates, so a slider tick or a live-feed tick changes only
/// the one section that reads that value, and SwiftUI skips the other sixteen section bodies.
struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    @State private var budget = 2_000.0
    @State private var hideBalances = false
    @State private var showPendingOnly = false
    @State private var timeRange = TimeRange.month
    @State private var liveArrivals: [LiveArrival] = []
    @Environment(\.liveUpdatesEnabled) private var liveUpdatesEnabled

    var body: some View {
        ScrollView {
            VStack {
                LiveActivitySection(liveArrivals: liveArrivals)
                AccountSummarySection(transactions: transactions, timeRange: timeRange, hideBalances: $hideBalances)
                TimeRangeSection(timeRange: $timeRange)
                BudgetSection(transactions: transactions, timeRange: timeRange, budget: $budget)
                SpendingChartSection(transactions: transactions, timeRange: timeRange)
                CategoryBreakdownSection(transactions: transactions, timeRange: timeRange)
                RecentTransactionsSection(
                    transactions: transactions, timeRange: timeRange, rowLimit: rowLimit, showPendingOnly: $showPendingOnly
                )
                CashFlowSection(transactions: transactions, timeRange: timeRange)
                TopMerchantsSection(transactions: transactions, timeRange: timeRange)
                LargestExpensesSection(transactions: transactions, timeRange: timeRange)
                WeekdayPatternSection(transactions: transactions, timeRange: timeRange)
                SpendingCalendarSection(transactions: transactions, timeRange: timeRange)
                CategoryTrendsSection(transactions: transactions, timeRange: timeRange)
                VersusPreviousSection(transactions: transactions, timeRange: timeRange)
                UpcomingBillsSection(transactions: transactions)
                SubscriptionsSection(transactions: transactions)
                SavingsGoalSection(transactions: transactions)
            }
            .padding()
        }
        .task(id: liveUpdatesEnabled) {
            // Identical in both apps: ten arrivals a second from the dashboard's own state.
            guard liveUpdatesEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                liveArrivals = LiveFeed.next(after: liveArrivals)
            }
        }
    }
}
