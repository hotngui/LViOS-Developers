//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//
//  The Boxed app with one change: each ViewModel builds its card from AnyViews inside AnyViews. The chrome takes its
//  content as an AnyView input, and that content is assembled inline from primitives. Ids are stable, so ForEach
//  matches every row; what remains is the cost of views that hold an AnyView and so can never be skipped.
//  The sibling app BoxedViews wraps one concrete card per AnyView; ConcreteViews has no ViewModels.

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
