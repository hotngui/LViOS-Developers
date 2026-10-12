import Charts
import DashboardKit
import SwiftUI

/// The ten merchants with the most spending in the range.
struct TopMerchantsSection: View {
    let transactions: [AccountTransaction]
    let timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: topMerchants
        let evaluationCount = EvaluationCounter.shared.record(.topMerchants)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let merchants = TransactionMath.topMerchants(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Top merchants")
                .font(.headline)
            Chart(merchants) { merchant in
                BarMark(x: .value("Spent", merchant.amount), y: .value("Merchant", merchant.merchant))
            }
            .frame(minHeight: 240)
            EvaluationBadge(section: .topMerchants, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: topMerchants
    }
}
