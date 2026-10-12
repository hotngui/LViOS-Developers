import DashboardKit
import SwiftUI

/// The newest transactions in the range, optionally only pending ones.
struct RecentTransactionsSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    let rowLimit: Int
    @Binding var showPendingOnly: Bool

    var body: some View {
        // BEGIN SECTION BODY: transactions
        let evaluationCount = EvaluationCounter.shared.record(.transactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let filtered = showPendingOnly ? TransactionMath.pendingOnly(inRange) : inRange
        let rows = TransactionMath.newestFirst(filtered, limit: rowLimit)
        VStack(alignment: .leading) {
            Text("Recent transactions")
                .font(.headline)
            Toggle("Pending only", isOn: $showPendingOnly.timed(.pendingOnly))
            if rows.isEmpty {
                Text("No transactions in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(rows) { transaction in
                HStack {
                    Image(systemName: transaction.category.systemImage)
                        .foregroundStyle(transaction.category.color)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(transaction.merchant)
                        Text(transaction.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(transaction.amount, format: .currency(code: "USD").sign(strategy: .always()))
                        if transaction.isPending {
                            Label("Pending", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
            EvaluationBadge(section: .transactions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: transactions
    }
}
