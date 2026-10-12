import DashboardKit
import SwiftUI

/// Spending per category, largest first.
struct CategoryBreakdownSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: categories
        let evaluationCount = EvaluationCounter.shared.record(.categories)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let categoryTotals = TransactionMath.categoryTotals(of: inRange)
        VStack(alignment: .leading) {
            Text("Where it went")
                .font(.headline)
            if categoryTotals.isEmpty {
                Text("No spending in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(categoryTotals) { categoryTotal in
                VStack(alignment: .leading) {
                    LabeledContent {
                        Text(categoryTotal.total, format: .currency(code: "USD"))
                    } label: {
                        Label {
                            Text(categoryTotal.category.title)
                        } icon: {
                            Image(systemName: categoryTotal.category.systemImage)
                        }
                    }
                    ProgressView(value: categoryTotal.share)
                        .tint(categoryTotal.category.color)
                        .accessibilityValue(Text(categoryTotal.share, format: .percent.precision(.fractionLength(1))))
                }
            }
            EvaluationBadge(section: .categories, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categories
    }
}
