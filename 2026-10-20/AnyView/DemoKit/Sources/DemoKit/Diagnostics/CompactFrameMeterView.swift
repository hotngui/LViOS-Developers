import SwiftUI

/// The Eager app's heads-up display: which app this is, the card count, live frame pacing, and the device.
///
/// Like `FrameMeterView`, it's its own view with its own state, so updating it every frame never invalidates the cards,
/// and every row is a single line that shrinks rather than wraps, so its height never changes mid-take.
/// A load (a new `loadedAt`) makes it wait for frame pacing to settle and then restart its statistics by itself.
public struct CompactFrameMeterView: View {
    private let variant: AppVariant
    private let cardCount: Int
    private let loadedAt: Date

    @State private var recorder = SettlingFrameRecorder()
    @Environment(\.scenePhase) private var scenePhase

    public init(variant: AppVariant, cardCount: Int, loadedAt: Date) {
        self.variant = variant
        self.cardCount = cardCount
        self.loadedAt = loadedAt
    }

    /// The count with its noun: "1 card", "300 cards".
    static func cardCountLabel(_ count: Int) -> LocalizedStringResource {
        count == 1 ? "1 card" : "\(count) cards"
    }

    public var body: some View {
        TimelineView(.animation) { context in
            let stats = recorder.record(frameAt: context.date)
            VStack(alignment: .leading) {
                HStack {
                    VariantBadge(variant: variant)
                    Spacer()
                    Text(Self.cardCountLabel(cardCount))
                }
                HStack {
                    if recorder.isSettling {
                        // Text, not a color change, so the state never depends on color alone.
                        Text("Settling…")
                    } else {
                        Text("FPS \(stats.framesPerSecond, format: .number.precision(.fractionLength(0)))")
                        Text("Hitches \(stats.hitchCount)")
                        Text("Worst \(stats.worstFrame.inMilliseconds, format: .number.precision(.fractionLength(1))) ms")
                    }
                    Spacer()
                    Button("Reset frame stats", systemImage: "arrow.counterclockwise") {
                        recorder.reset()
                    }
                    .labelStyle(.iconOnly)
                    .minimumTapTarget()
                }
                Text(DeviceModel.identifier)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
        }
        .onChange(of: loadedAt, initial: true) {
            recorder.arm()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                recorder.resume()
            } else {
                recorder.pause()
            }
        }
    }
}
