//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import Charts
import DemoKit
import SwiftUI

@MainActor
final class SparklineCardViewModel: CardViewModel {
    let id: Int
    let view: AnyView

    init(card: CardSnapshot) {
        id = card.id
        let content = AnyView(
            Group {
                Chart(card.history) { point in
                    LineMark(x: .value("Tick", point.id), y: .value("Value", point.value))
                }
                .chartXAxis(.hidden)
                .frame(minHeight: 60)
                .accessibilityLabel("Sparkline of \(card.history.count) points, latest \(Int(card.value), format: .number)")
                Text("Latest \(Int(card.value), format: .number)")
                    .foregroundStyle(.secondary)
            }
        )
        view = AnyView(NestedChrome(id: card.id, title: card.title, content: content))
    }
}

// swiftlint:enable no_any_view
