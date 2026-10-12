import Foundation

/// Times one interaction at a time, from the tap to the first frame that shows its result.
///
/// "Shows its result" means a frame dated after the latest dashboard-section rebuild since the tap. The HUD can draw a
/// frame during the tap's own update pass, before (or while) sections re-run, and that frame mustn't count, whichever
/// order SwiftUI happens to update the HUD and the sections in. A first rebuild that starts more than
/// `rebuildWindow` after the tap belongs to something else, so the timing is dropped instead of completing.
/// Pure value logic; `InteractionTimer` supplies the clock and the rebuild signal.
public struct LatencyMeter: Equatable, Sendable {
    /// How soon after the tap its update must start re-running sections. Only the start is bounded, so slow updates
    /// (a multi-second open at Extreme) are still measured.
    public static let rebuildWindow: Duration = .seconds(1)

    private struct Pending: Equatable, Sendable {
        let interaction: Interaction
        let start: Date
        var lastRebuild: Date?
    }

    private var pending: Pending?
    public private(set) var last: LatencyMeasurement?

    public init() {}

    public var isTiming: Bool { pending != nil }

    /// Starts timing `interaction`. A timing that hasn't finished yet is replaced: the latest tap wins.
    public mutating func begin(_ interaction: Interaction, at start: Date) {
        pending = Pending(interaction: interaction, start: start)
    }

    /// Call whenever a dashboard section's body runs, with the time it ran.
    public mutating func contentUpdated(at date: Date) {
        guard var current = pending else { return }
        if current.lastRebuild == nil && date.timeIntervalSince(current.start) > Self.rebuildWindow.inSeconds {
            pending = nil
            return
        }
        current.lastRebuild = max(date, current.start)
        pending = current
    }

    /// Feed every rendered frame. The first frame dated after the latest rebuild completes the timing.
    public mutating func frameRendered(at date: Date) {
        guard let current = pending, let rebuild = current.lastRebuild, date > rebuild else { return }
        last = LatencyMeasurement(interaction: current.interaction, total: .seconds(date.timeIntervalSince(current.start)))
        pending = nil
    }

    /// Discards the pending timing, e.g. because the app left the foreground.
    public mutating func cancel() {
        pending = nil
    }
}
