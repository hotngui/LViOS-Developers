//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.

import DemoKit

/// Maps a snapshot to the ViewModel for its kind. This is the only place that knows the concrete types.
@MainActor
enum CardViewModelFactory {
    static func make(_ card: CardSnapshot) -> any CardViewModel {
        switch card.kind {
        case .stat: StatCardViewModel(card: card)
        case .gauge: GaugeCardViewModel(card: card)
        case .toggle: ToggleCardViewModel(card: card)
        case .sparkline: SparklineCardViewModel(card: card)
        case .pulse: PulseCardViewModel(card: card)
        }
    }
}
