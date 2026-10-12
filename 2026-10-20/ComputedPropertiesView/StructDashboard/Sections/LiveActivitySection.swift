import Charts
import DashboardKit
import SwiftUI

/// The live feed: the only section that reads the dashboard's ten-per-second state.
struct LiveActivitySection: View {
    let liveArrivals: [LiveArrival]

    var body: some View {
        // BEGIN SECTION BODY: live
        let evaluationCount = EvaluationCounter.shared.record(.live)
        let shownTotal = liveArrivals.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            HStack {
                Label("Live activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                Text("\(liveArrivals.count) recent")
                    .foregroundStyle(.secondary)
            }
            if let latest = liveArrivals.last {
                LabeledContent(latest.merchant) {
                    Text(latest.amount, format: .currency(code: "USD"))
                }
            } else {
                Text("Waiting for activity…")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Pending (shown)") {
                Text(shownTotal, format: .currency(code: "USD"))
            }
            Chart(liveArrivals) { arrival in
                LineMark(x: .value("Arrival", arrival.id), y: .value("Amount", arrival.value))
            }
            .chartXAxis(.hidden)
            .frame(minHeight: 60)
            EvaluationBadge(section: .live, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: live
    }
}
