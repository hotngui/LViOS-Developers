//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//
//  The Erased app with one change: each ViewModel forwards the snapshot's stable integer id instead of minting a
//  UUID. Every update still rebuilds every ViewModel and every AnyView, but ForEach matches every row, so what
//  remains is AnyView's own cost. The sibling app ErasedViews mints fresh UUIDs; ConcreteViews has no ViewModels.

import DemoKit
import SwiftUI

struct DashboardView: View {
    let store: DashboardStore
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        CardContainer {
            ForEach(viewModel.cards, id: \.id) { $0.view }
        }
        .onChange(of: store.dataVersion, initial: true) {
            viewModel.update(from: store.cards)
        }
    }
}
