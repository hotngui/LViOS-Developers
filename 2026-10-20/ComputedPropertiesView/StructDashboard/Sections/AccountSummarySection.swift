import DashboardKit
import SwiftUI

/// Net, income, and spending for the selected range, plus the button that hides the amounts.
struct AccountSummarySection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange
    @Binding var hideBalances: Bool

    var body: some View {
        // BEGIN SECTION BODY: summary
        let evaluationCount = EvaluationCounter.shared.record(.summary)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        VStack(alignment: .leading) {
            HStack {
                Text("Account summary")
                    .font(.headline)
                Spacer()
                Button("Toggle balance visibility", systemImage: hideBalances ? "eye.slash" : "eye") {
                    InteractionTimer.shared.begin(.toggleBalances)
                    hideBalances.toggle()
                }
                .labelStyle(.iconOnly)
            }
            Text(TransactionMath.net(of: inRange), format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .redacted(reason: hideBalances ? .placeholder : [])
            LabeledContent("Income") {
                Text(TransactionMath.income(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            LabeledContent("Spent") {
                Text(TransactionMath.expenses(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            EvaluationBadge(section: .summary, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: summary
    }
}
