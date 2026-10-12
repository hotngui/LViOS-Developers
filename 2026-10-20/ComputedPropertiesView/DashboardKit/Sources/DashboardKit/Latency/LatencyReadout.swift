import SwiftUI

/// The HUD line with the latest tap-to-display timing, e.g. "Pending only 212 ms" or "Open 48 ms (first frame)".
/// An open is timed to the dashboard's first frame; "(first frame)" flags that the slide-in isn't included.
struct LatencyReadout: View {
    let measurement: LatencyMeasurement?

    private let milliseconds = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))

    var body: some View {
        if let measurement {
            let title = Text(measurement.interaction.title)
            let total = measurement.total.inMilliseconds
            if measurement.interaction == .openDashboard {
                Text("\(title) \(total, format: milliseconds) ms (first frame)")
            } else {
                Text("\(title) \(total, format: milliseconds) ms")
            }
        } else {
            Text("Tap something to time it")
                .foregroundStyle(.secondary)
        }
    }
}
