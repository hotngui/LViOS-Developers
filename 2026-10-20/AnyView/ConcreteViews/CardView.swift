import DemoKit
import SwiftUI

/// One concrete row. The `switch` sits inside a single-root container, so the row is unary and a lazy container can
/// template row ids from the element ids without evaluating every row.
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
