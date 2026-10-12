import DashboardKit
import SwiftUI

/// Spending against the budget, with the slider that drives the headline demo.
struct BudgetSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    @Binding var budget: Double

    var body: some View {
        // BEGIN SECTION BODY: budget
        let evaluationCount = EvaluationCounter.shared.record(.budget)
        let spent = TransactionMath.expenses(of: TransactionMath.transactions(transactions, in: timeRange.dateRange()))
        let ceiling = TransactionMath.budgetCeiling(forSpent: spent)
        VStack(alignment: .leading) {
            Text("Budget")
                .font(.headline)
            Gauge(value: TransactionMath.budgetUsage(spent: spent, budget: budget)) {
                Text("Spent of budget")
            } currentValueLabel: {
                Text(spent, format: .currency(code: "USD"))
            }
            if spent > Decimal(budget) {
                Label("Over budget", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .bold()
            }
            Slider(value: $budget, in: 0...ceiling) {
                Text("Budget")
            }
            .accessibilityValue(Text(budget, format: .currency(code: "USD")))
            Text("Budget: \(budget, format: .currency(code: "USD").precision(.fractionLength(0)))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(section: .budget, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: budget
    }
}
