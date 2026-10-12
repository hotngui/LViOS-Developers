import DemoKit
import SwiftUI

/// Shown once every card has been removed. Picking the count that is already selected would not reload anything,
/// so the way back is a button. The store is read from the environment only inside the button's action.
struct NoCardsView: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        ContentUnavailableView {
            Label("No cards", systemImage: "rectangle.on.rectangle.slash")
        } description: {
            Text("Every card was removed.")
        } actions: {
            Button("Reload cards", systemImage: "arrow.clockwise") {
                store.reset()
            }
        }
    }
}
