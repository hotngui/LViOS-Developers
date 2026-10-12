import SwiftUI

/// Shows how many times the enclosing section's body has run.
///
/// The section records each run itself (see `EvaluationCounter`) and passes the new `count` in, which makes this badge
/// redraw whenever that section's body runs. The badge also redraws when the counts are reset
/// (`evaluationBadgeResetGeneration`), so it always shows the section's live count rather than a stale number.
public struct EvaluationBadge: View {
    private let section: DashboardSection
    private let count: Int
    @Environment(\.showsEvaluationBadges) private var isVisible
    @Environment(\.evaluationBadgeResetGeneration) private var resetGeneration

    public init(section: DashboardSection, count: Int) {
        self.section = section
        self.count = count
    }

    public var body: some View {
        if isVisible {
            Text("body runs: \(liveCount)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.black)
                .padding(.horizontal)
                .background(.yellow, in: .capsule)
                .accessibilityLabel("\(section.rawValue) section body evaluated \(liveCount) times")
        }
    }

    /// The section's current count. `count` (a new value each time the section runs) and `resetGeneration` are what
    /// trigger a redraw; reading `resetGeneration` here makes the reset dependency explicit.
    private var liveCount: Int {
        _ = resetGeneration
        return EvaluationCounter.shared.count(for: section)
    }
}
