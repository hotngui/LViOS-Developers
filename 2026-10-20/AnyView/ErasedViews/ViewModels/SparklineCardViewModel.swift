//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import DemoKit
import SwiftUI

@MainActor
final class SparklineCardViewModel: CardViewModel {
    let id = UUID()
    let view: AnyView

    init(card: CardSnapshot) {
        view = AnyView(SparklineCard(id: card.id, title: card.title, value: card.value, history: card.history))
    }
}

// swiftlint:enable no_any_view
