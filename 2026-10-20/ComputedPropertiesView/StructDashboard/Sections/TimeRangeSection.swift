import DashboardKit
import SwiftUI

/// The Week / Month / Quarter / Year picker.
struct TimeRangeSection: View {
    @Binding var timeRange: TimeRange

    var body: some View {
        // BEGIN SECTION BODY: timeRange
        let evaluationCount = EvaluationCounter.shared.record(.timeRange)
        VStack(alignment: .leading) {
            Picker("Time range", selection: $timeRange.timed(.timeRange)) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            EvaluationBadge(section: .timeRange, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: timeRange
    }
}
