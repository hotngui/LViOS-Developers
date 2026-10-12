import Charts
import DashboardKit
import SwiftUI

/// Running net balance per day across the range.
struct CashFlowSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: cashFlow
        let evaluationCount = EvaluationCounter.shared.record(.cashFlow)
        let balances = TransactionMath.dailyBalances(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Cash flow")
                .font(.headline)
            Chart(balances) { point in
                LineMark(x: .value("Day", point.day, unit: .day), y: .value("Net", point.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .cashFlow, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: cashFlow
    }
}
