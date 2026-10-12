import Charts
import DashboardKit
import SwiftUI

/// Stacked daily spending bars by category.
struct SpendingChartSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: chart
        let evaluationCount = EvaluationCounter.shared.record(.chart)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let dailyTotals = TransactionMath.dailyTotals(of: inRange, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Spending by day")
                .font(.headline)
            Chart(dailyTotals) { dailyTotal in
                BarMark(x: .value("Day", dailyTotal.day, unit: .day), y: .value("Spent", dailyTotal.amount))
                    .foregroundStyle(by: .value("Category", dailyTotal.category.name))
            }
            .chartForegroundStyleScale(
                domain: TransactionCategory.spending.map(\.name), range: TransactionCategory.spending.map(\.color)
            )
            .frame(minHeight: 220)
            EvaluationBadge(section: .chart, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: chart
    }
}
