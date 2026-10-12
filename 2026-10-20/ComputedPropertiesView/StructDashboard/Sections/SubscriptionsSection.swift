import DashboardKit
import SwiftUI

/// Recurring monthly charges and their total (whole-year data; ignores the range).
struct SubscriptionsSection: View {
    let transactions: [AccountTransaction]

    var body: some View {
        // BEGIN SECTION BODY: subscriptions
        let evaluationCount = EvaluationCounter.shared.record(.subscriptions)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let monthlyTotal = charges.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            Text("Subscriptions")
                .font(.headline)
            ForEach(charges) { charge in
                LabeledContent(charge.merchant) {
                    Text(charge.amount, format: .currency(code: "USD"))
                }
            }
            LabeledContent("Monthly total") {
                Text(monthlyTotal, format: .currency(code: "USD"))
                    .bold()
            }
            EvaluationBadge(section: .subscriptions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: subscriptions
    }
}
