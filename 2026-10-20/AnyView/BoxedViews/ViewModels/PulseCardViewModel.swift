//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import DemoKit
import SwiftUI

@MainActor
final class PulseCardViewModel: CardViewModel {
    let id: Int
    let view: AnyView

    init(card: CardSnapshot) {
        id = card.id
        view = AnyView(PulseCard(id: card.id, title: card.title, value: card.value))
    }
}

// swiftlint:enable no_any_view
