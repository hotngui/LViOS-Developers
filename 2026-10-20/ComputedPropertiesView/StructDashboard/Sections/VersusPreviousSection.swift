import DashboardKit
import SwiftUI

/// Spending per category versus the equally long period before.
struct VersusPreviousSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: versusPrevious
        let evaluationCount = EvaluationCounter.shared.record(.versusPrevious)
        let current = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let previous = TransactionMath.transactions(transactions, in: timeRange.previousDateRange())
        let changes = TransactionMath.categoryComparison(current: current, previous: previous)
        VStack(alignment: .leading) {
            Text("Versus previous period")
                .font(.headline)
            ForEach(changes) { change in
                let before = Text(change.previous, format: .currency(code: "USD"))
                let after = Text(change.current, format: .currency(code: "USD"))
                LabeledContent {
                    Text(change.difference, format: .currency(code: "USD").sign(strategy: .always()))
                } label: {
                    Text(change.category.title)
                    Text("\(before) → \(after)")
                }
            }
            EvaluationBadge(section: .versusPrevious, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: versusPrevious
    }
}
