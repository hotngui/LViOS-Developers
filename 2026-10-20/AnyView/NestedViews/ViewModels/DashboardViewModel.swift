//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.

import DemoKit
import Observation

/// Rebuilds every per-card ViewModel whenever the data layer publishes a new result set. Because each ViewModel baked
/// its view in at `init`, there is no way to update one in place; rebuilding is the only option, and every rebuild
/// mints new ids.
@MainActor
@Observable
final class DashboardViewModel {
    private(set) var cards: [any CardViewModel] = []

    func update(from snapshots: [CardSnapshot]) {
        cards = snapshots.map(CardViewModelFactory.make)
    }
}
