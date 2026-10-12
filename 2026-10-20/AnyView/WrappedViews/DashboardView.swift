//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.
//
//  The Concrete app with one change: each row is wrapped in an AnyView. The row's structural identity is gone, so a
//  List cannot template its rows and evaluates every one of them on every update. Nothing else differs: no
//  ViewModels, stable ids, and a Reload with equal data still does not run this body.

import DemoKit
import SwiftUI

struct DashboardView: View {
    let store: DashboardStore

    var body: some View {
        CardContainer {
            ForEach(store.cards) { AnyView(CardView(card: $0)) }
        }
    }
}

// swiftlint:enable no_any_view
