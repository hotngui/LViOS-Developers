import DashboardKit
import SwiftUI

/// A heatmap of daily spending across the range.
struct SpendingCalendarSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: spendingCalendar
        let evaluationCount = EvaluationCounter.shared.record(.spendingCalendar)
        let days = TransactionMath.dailySpend(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let busiest = days.map(\.amount).max() ?? 0
        VStack(alignment: .leading) {
            Text("Spending calendar")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red.opacity(busiest > 0 ? day.amount / busiest : 0))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(Text(day.day, format: .dateTime.month().day()))
                        .accessibilityValue(Text(day.value, format: .currency(code: "USD")))
                }
            }
            EvaluationBadge(section: .spendingCalendar, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: spendingCalendar
    }
}
