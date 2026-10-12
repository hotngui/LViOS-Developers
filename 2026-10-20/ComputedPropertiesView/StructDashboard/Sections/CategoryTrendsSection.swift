import Charts
import DashboardKit
import SwiftUI

/// One sparkline per spending category across the range.
struct CategoryTrendsSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: categoryTrends
        let evaluationCount = EvaluationCounter.shared.record(.categoryTrends)
        let series = TransactionMath.categorySeries(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Category trends")
                .font(.headline)
            ForEach(series) { categorySeries in
                HStack {
                    Label {
                        Text(categorySeries.category.title)
                    } icon: {
                        Image(systemName: categorySeries.category.systemImage)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Chart(categorySeries.points) { point in
                        LineMark(x: .value("Day", point.day, unit: .day), y: .value("Spent", point.amount))
                            .foregroundStyle(categorySeries.category.color)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(minHeight: 36)
                }
            }
            EvaluationBadge(section: .categoryTrends, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categoryTrends
    }
}
