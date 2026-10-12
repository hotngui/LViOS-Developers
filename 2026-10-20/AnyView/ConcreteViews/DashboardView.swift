import DemoKit
import SwiftUI

/// The right way: a concrete row view per stable id. This body runs on every data change and SwiftUI matches every
/// card by id, so only cards whose snapshot changed re-render. A Reload with equal data does not even run this body.
struct DashboardView: View {
    let store: DashboardStore

    var body: some View {
        CardContainer {
            ForEach(store.cards) { CardView(card: $0) }
        }
    }
}
