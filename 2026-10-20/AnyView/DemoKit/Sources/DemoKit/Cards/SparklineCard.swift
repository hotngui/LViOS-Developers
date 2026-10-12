import Charts
import SwiftUI

/// A Swift Charts line of the last thirty points. The expensive card: this is what drives the hitches.
public struct SparklineCard: View {
    private let id: Int
    private let title: String
    private let value: Double
    private let history: [HistoryPoint]

    public init(id: Int, title: String, value: Double, history: [HistoryPoint]) {
        self.id = id
        self.title = title
        self.value = value
        self.history = history
    }

    public var body: some View {
        CardChrome(id: id, title: title) {
            Chart(history) { point in
                LineMark(x: .value("Tick", point.id), y: .value("Value", point.value))
            }
            .chartXAxis(.hidden)
            .frame(minHeight: 60)
            .accessibilityLabel("Sparkline of \(history.count) points, latest \(Int(value), format: .number)")
            Text("Latest \(Int(value), format: .number)")
                .foregroundStyle(.secondary)
        }
    }
}
