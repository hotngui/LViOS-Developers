import DashboardKit
import SwiftUI

/// The ten largest expenses in the range.
struct LargestExpensesSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: largestTransactions
        let evaluationCount = EvaluationCounter.shared.record(.largestTransactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let largest = TransactionMath.largestExpenses(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Largest expenses")
                .font(.headline)
            ForEach(largest) { transaction in
                LabeledContent {
                    Text(transaction.amount, format: .currency(code: "USD"))
                } label: {
                    Text(transaction.merchant)
                    Text(transaction.date, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .largestTransactions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: largestTransactions
    }
}
