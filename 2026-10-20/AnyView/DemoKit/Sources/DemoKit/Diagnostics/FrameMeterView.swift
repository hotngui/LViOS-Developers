import SwiftUI

/// The heads-up display pinned to the bottom of the screen: which app this is, the settings, the device, when the data
/// was loaded, the card count, the appearance and body counts, and live frame pacing.
/// It's its own view with its own state, so updating it every frame never invalidates the dashboard. Every row is a
/// single line that shrinks rather than wraps, so the HUD's height (which the dashboard reserves) never changes mid-take.
struct FrameMeterView: View {
    let variant: AppVariant
    let intensity: Intensity
    let tickRate: TickRate
    let containerStyle: ContainerStyle
    let liveUpdates: Bool
    let loadedAt: Date
    let cardCount: Int

    @State private var recorder = FrameRecorder()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation) { context in
            let stats = recorder.record(frameAt: context.date)
            VStack(alignment: .leading) {
                HStack {
                    VariantBadge(variant: variant)
                    Spacer()
                    Text(intensity.title)
                    Text(tickRate.title)
                    Text(containerStyle.title)
                    Text(liveUpdates ? "Live on" : "Live off")
                }
                HStack {
                    Text("Loaded \(loadedAt, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())")
                    Text("\(cardCount) cards")
                    Spacer()
                    Text(DeviceModel.identifier)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Appearances \(AppearanceCounter.shared.count)")
                    Text("Bodies \(BodyCounter.shared.count)")
                    Spacer()
                }
                HStack {
                    Text("FPS \(stats.framesPerSecond, format: .number.precision(.fractionLength(0)))")
                    Text("Hitches \(stats.hitchCount)")
                    Text("Worst \(stats.worstFrame.inMilliseconds, format: .number.precision(.fractionLength(1))) ms")
                    Spacer()
                    Button("Reset frame stats", systemImage: "arrow.counterclockwise") {
                        recorder.reset()
                        Self.resetCounters()
                    }
                    .labelStyle(.iconOnly)
                    .minimumTapTarget()
                }
                if !reduceMotion {
                    // The heartbeat: sweeps every 2 seconds and visibly stutters whenever the main thread misses frames.
                    ProgressView(value: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2), total: 2)
                        .accessibilityHidden(true)
                }
            }
            .font(.caption.monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                recorder.resume()
            } else {
                recorder.pause()
            }
        }
    }

    /// Clears the two counts a take starts from. The reset button calls this along with the recorder's reset.
    static func resetCounters() {
        AppearanceCounter.shared.reset()
        BodyCounter.shared.reset()
    }
}
