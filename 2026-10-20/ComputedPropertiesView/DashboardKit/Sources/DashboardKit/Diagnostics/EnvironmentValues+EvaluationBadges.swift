import SwiftUI

extension EnvironmentValues {
    /// Whether sections show their "body runs" badge. Off by default; keep it off for Instruments runs.
    @Entry public var showsEvaluationBadges = false

    /// Changes whenever the body-run counts are reset, so every badge redraws with its section's cleared count.
    @Entry public var evaluationBadgeResetGeneration = 0
}
