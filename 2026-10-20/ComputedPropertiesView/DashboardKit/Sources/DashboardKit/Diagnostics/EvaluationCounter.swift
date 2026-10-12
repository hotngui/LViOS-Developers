/// Counts how many times each dashboard section's body has run.
///
/// Deliberately *not* `@Observable`, and reached through `shared` rather than the environment: section bodies write to
/// it while they're being evaluated, and that write must never trigger another evaluation.
@MainActor
public final class EvaluationCounter {
    public static let shared = EvaluationCounter(interactionTimer: .shared)

    private var counts: [DashboardSection: Int] = [:]
    /// Told about every body run, so a tap's timing only ends on a frame drawn after the dashboard was rebuilt.
    private let interactionTimer: InteractionTimer?

    public init(interactionTimer: InteractionTimer? = nil) {
        self.interactionTimer = interactionTimer
    }

    /// Records one body evaluation and returns the section's new count.
    @discardableResult
    public func record(_ section: DashboardSection) -> Int {
        counts[section, default: 0] += 1
        interactionTimer?.contentUpdated()
        return counts[section, default: 0]
    }

    public func count(for section: DashboardSection) -> Int {
        counts[section, default: 0]
    }

    public func reset() {
        counts.removeAll()
    }
}
