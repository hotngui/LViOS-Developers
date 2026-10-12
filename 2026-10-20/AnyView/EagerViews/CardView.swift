import DemoKit
import SwiftUI

/// One concrete row, copied from ConcreteViews so each card's view tree, and its touch targets, are the same in both
/// apps. Keep the two files identical apart from this comment.
struct CardView: View {
    let card: CardSnapshot

    var body: some View {
        VStack {
            switch card.kind {
            case .stat: StatCard(id: card.id, title: card.title, value: card.value)
            case .gauge: GaugeCard(id: card.id, title: card.title, value: card.value)
            case .toggle: ToggleCard(id: card.id, title: card.title, value: card.value)
            case .sparkline: SparklineCard(id: card.id, title: card.title, value: card.value, history: card.history)
            case .pulse: PulseCard(id: card.id, title: card.title, value: card.value)
            }
        }
    }
}
