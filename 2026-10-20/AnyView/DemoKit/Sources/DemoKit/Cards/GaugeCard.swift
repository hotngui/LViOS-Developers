import SwiftUI

/// A 0…1 gauge. With stable identity it eases to the new value; a re-created card snaps.
public struct GaugeCard: View {
    private let id: Int
    private let title: String
    private let value: Double

    public init(id: Int, title: String, value: Double) {
        self.id = id
        self.title = title
        self.value = value
    }

    public var body: some View {
        CardChrome(id: id, title: title) {
            Gauge(value: value) {
                Text("Load")
            } currentValueLabel: {
                Text(value, format: .percent.precision(.fractionLength(0)))
            }
            .gaugeStyle(.linearCapacity)
            .animation(.easeInOut, value: value)
        }
    }
}
