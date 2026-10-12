import DemoKit
import Foundation
import SwiftUI

/// The whole app: a plain `VStack` in a `ScrollView`, a bar to pick how many cards it holds, and the HUD.
/// A non-lazy stack builds and keeps every card, and every touch is tested against all of them. That is what this
/// app is here to show.
///
/// The bar and the HUD sit beside the list, not over it. Drawn over the list, a touch on their background falls
/// through to the card scrolled beneath, and that card's Remove button is easy to hit by accident.
struct EagerStackView: View {
    @State private var cardCount = LaunchArguments.cardCount(from: ProcessInfo.processInfo.arguments)
    @State private var store = DashboardStore()

    var body: some View {
        VStack {
            CardCountBar(selection: $cardCount)
            ScrollView {
                VStack {
                    ForEach(store.cards) { CardView(card: $0) }
                }
                .padding()
            }
            .id(store.lastLoaded)
            .frame(maxWidth: .infinity)
            .overlay {
                // Only after a load: before the first load the store is empty too, and that is not "removed".
                if store.cardCount == 0, store.dataVersion > 0 {
                    NoCardsView()
                }
            }
            CompactFrameMeterView(variant: .eager, cardCount: store.cardCount, loadedAt: store.lastLoaded)
        }
        .environment(store)
        .task(id: cardCount) {
            store.load(cardCount: cardCount.rawValue)
        }
    }
}
