import SwiftUI

/// The heads-up display pinned to the bottom of both screens: which app this is, the intensity, the device, live frame
/// pacing, and the latest tap-to-display timing.
/// It's its own view with its own state, so updating it every frame never invalidates the dashboard.
struct FrameMeterView: View {
    let variant: AppVariant
    let intensity: Intensity
    let liveUpdates: Bool

    @State private var recorder = FrameRecorder()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation) { context in
            let stats = recorder.record(frameAt: context.date)
            VStack(alignment: .leading) {
                HStack {
                    Text(variant.title)
                        .bold()
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                        .background(variant.tint, in: .capsule)
                    Spacer()
                    Text(intensity.title)
                    if liveUpdates {
                        Text("Live on")
                    } else {
                        Text("Live off")
                    }
                    Text(DeviceModel.identifier)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("FPS \(stats.framesPerSecond, format: .number.precision(.fractionLength(0)))")
                    Text("Hitches \(stats.hitchCount)")
                    Text("Worst \(stats.worstFrame.inMilliseconds, format: .number.precision(.fractionLength(1))) ms")
                    Spacer()
                    Button("Reset frame stats", systemImage: "arrow.counterclockwise") {
                        recorder.reset()
                    }
                    .labelStyle(.iconOnly)
                }
                LatencyReadout(measurement: InteractionTimer.shared.last)
                if !reduceMotion {
                    // The heartbeat: sweeps every 2 seconds and visibly stutters whenever the main thread misses frames.
                    ProgressView(value: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2), total: 2)
                        .accessibilityHidden(true)
                }
            }
            .font(.caption.monospacedDigit())
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                recorder.resume()
            } else {
                recorder.pause()
                InteractionTimer.shared.cancel()
            }
        }
    }
}
