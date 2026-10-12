//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import DemoKit
import SwiftUI

@MainActor
final class ToggleCardViewModel: CardViewModel {
    let id: Int
    let view: AnyView

    init(card: CardSnapshot) {
        id = card.id
        let content = AnyView(
            Group {
                ToggleSwitch()
                Text("Pending \(Int(card.value), format: .number)")
                    .foregroundStyle(.secondary)
            }
        )
        view = AnyView(NestedChrome(id: card.id, title: card.title, content: content))
    }
}

// swiftlint:enable no_any_view
