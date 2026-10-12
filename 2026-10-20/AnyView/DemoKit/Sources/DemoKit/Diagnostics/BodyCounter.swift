/// Counts body runs of the card chrome: one per card each time SwiftUI re-runs that card. Boxed and Concrete re-run
/// only the cards whose data changed; Erased and Nested re-run every card on every update.
///
/// Deliberately *not* `@Observable`: the chrome records from inside its `body` and the HUD polls it every frame, and
/// neither must trigger another update.
@MainActor
public final class BodyCounter {
    public static let shared = BodyCounter()

    public private(set) var count = 0

    public init() {}

    public func record() {
        count += 1
    }

    public func reset() {
        count = 0
    }
}
