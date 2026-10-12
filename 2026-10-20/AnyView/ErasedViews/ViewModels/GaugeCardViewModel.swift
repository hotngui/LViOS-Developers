//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import DemoKit
import SwiftUI

@MainActor
final class GaugeCardViewModel: CardViewModel {
    let id = UUID()
    let view: AnyView

    init(card: CardSnapshot) {
        view = AnyView(GaugeCard(id: card.id, title: card.title, value: card.value))
    }
}

// swiftlint:enable no_any_view
