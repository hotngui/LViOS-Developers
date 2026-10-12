import Charts
import DashboardKit
import SwiftUI

/// Average daily spending per weekday in the range.
struct WeekdayPatternSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: weekdayPattern
        let evaluationCount = EvaluationCounter.shared.record(.weekdayPattern)
        let averages = TransactionMath.weekdayAverages(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let symbols = DemoClock.calendar.shortWeekdaySymbols
        VStack(alignment: .leading) {
            Text("By weekday")
                .font(.headline)
            Chart(averages) { average in
                BarMark(x: .value("Weekday", symbols[average.weekday - 1]), y: .value("Average", average.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .weekdayPattern, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: weekdayPattern
    }
}
