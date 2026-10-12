//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//
//  The container works off a protocol and never sees a concrete view type. Whenever the data layer publishes a new
//  result set (`dataVersion`), the dashboard ViewModel rebuilds every per-card ViewModel; each is a new object with a
//  new UUID and a freshly boxed AnyView, so ForEach sees an entirely new set of ids and tears every card down.
//  The sibling app BoxedViews is identical except its ids are stable; ConcreteViews has no ViewModels at all.

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
