import Foundation
import Observation

/// The demo's user-adjustable settings, shared by the Settings menu, the HUD, and the data loader.
@MainActor
@Observable
public final class DemoSettings {
    public var intensity: Intensity
    public var showsEvaluationBadges: Bool
    public var liveUpdatesEnabled: Bool
    /// Bumped by `resetBodyRunCounts`. Badges read it from the environment so they redraw with the cleared counts.
    public private(set) var badgeResetGeneration = 0

    public init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        intensity = LaunchArguments.intensity(from: arguments)
        showsEvaluationBadges = LaunchArguments.showsEvaluationBadges(from: arguments)
        liveUpdatesEnabled = LaunchArguments.liveUpdatesEnabled(from: arguments)
    }

    /// Clears every section's body-run count and tells the badges to redraw. Without the redraw, a badge would keep
    /// its old number until its own section happened to run again.
    public func resetBodyRunCounts(_ counter: EvaluationCounter = .shared) {
        counter.reset()
        badgeResetGeneration += 1
    }
}
