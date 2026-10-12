import DashboardKit
import SwiftUI

/// Year-to-date savings against a goal of 20% of income (ignores the range).
struct SavingsGoalSection: View {
    let transactions: [AccountTransaction]

    var body: some View {
        // BEGIN SECTION BODY: savingsGoal
        let evaluationCount = EvaluationCounter.shared.record(.savingsGoal)
        let year = TransactionMath.transactions(transactions, in: TimeRange.year.dateRange())
        let net = TransactionMath.net(of: year)
        let goal = TransactionMath.income(of: year) / 5
        VStack(alignment: .leading) {
            Text("Savings goal")
                .font(.headline)
            Gauge(value: TransactionMath.savingsProgress(net: net, goal: goal)) {
                Text("Saved this year")
            } currentValueLabel: {
                Text(net, format: .currency(code: "USD"))
            }
            Text("Goal: \(goal, format: .currency(code: "USD"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(section: .savingsGoal, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: savingsGoal
    }
}
