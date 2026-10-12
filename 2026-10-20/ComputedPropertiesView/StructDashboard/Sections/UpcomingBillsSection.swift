import DashboardKit
import SwiftUI

/// Recurring charges due in the next 30 days (whole-year data; ignores the range).
struct UpcomingBillsSection: View {
    let transactions: [AccountTransaction]

    var body: some View {
        // BEGIN SECTION BODY: upcomingBills
        let evaluationCount = EvaluationCounter.shared.record(.upcomingBills)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let bills = TransactionMath.upcomingBills(charges, after: DemoClock.anchorDate, within: 30, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Upcoming bills")
                .font(.headline)
            if bills.isEmpty {
                Text("No bills due in the next 30 days")
                    .foregroundStyle(.secondary)
            }
            ForEach(bills) { bill in
                LabeledContent {
                    Text(bill.amount, format: .currency(code: "USD"))
                } label: {
                    Text(bill.merchant)
                    Text(bill.nextDate, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .upcomingBills, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: upcomingBills
    }
}
