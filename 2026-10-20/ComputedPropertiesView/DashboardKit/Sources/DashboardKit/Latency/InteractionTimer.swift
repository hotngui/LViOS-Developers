import Foundation
import os

/// The app-wide tap-to-display timer.
///
/// Deliberately not `@Observable`: the HUD reads `last` while it redraws every frame, and recording a tap or a frame
/// must never cause a view update. Each timing is also emitted as a Points of Interest interval for Instruments; intervals
/// that didn't produce a measurement end with a "replaced", "cancelled", or "stale" message.
@MainActor
public final class InteractionTimer {
    public static let shared = InteractionTimer()

    private var meter = LatencyMeter()
    private var signpostState: OSSignpostIntervalState?
    private let signposter = OSSignposter(subsystem: "com.hotngui.DashboardKit", category: .pointsOfInterest)

    public init() {}

    /// The most recent completed timing.
    public var last: LatencyMeasurement? { meter.last }

    public func begin(_ interaction: Interaction, at date: Date = .now) {
        endSignpost(outcome: "replaced")
        meter.begin(interaction, at: date)
        let id = signposter.makeSignpostID()
        signpostState = signposter.beginInterval("Interaction", id: id, "\(interaction.rawValue, privacy: .public)")
    }

    /// Called (via `EvaluationCounter`) whenever a dashboard section's body runs.
    public func contentUpdated(at date: Date = .now) {
        let wasTiming = meter.isTiming
        meter.contentUpdated(at: date)
        if wasTiming && !meter.isTiming {
            endSignpost(outcome: "stale")
        }
    }

    /// Called by the HUD for every frame it renders.
    public func frameRendered(at date: Date) {
        let wasTiming = meter.isTiming
        meter.frameRendered(at: date)
        if wasTiming && !meter.isTiming {
            endSignpost()
        }
    }

    public func cancel() {
        meter.cancel()
        endSignpost(outcome: "cancelled")
    }

    /// Ends the open interval. Completed timings end plainly; `outcome` labels intervals that didn't produce a
    /// measurement ("replaced", "cancelled", "stale"), so they stand out in Instruments.
    private func endSignpost(outcome: String? = nil) {
        guard let state = signpostState else { return }
        if let outcome {
            signposter.endInterval("Interaction", state, "\(outcome, privacy: .public)")
        } else {
            signposter.endInterval("Interaction", state)
        }
        signpostState = nil
    }
}
