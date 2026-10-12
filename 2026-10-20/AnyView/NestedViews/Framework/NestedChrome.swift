//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import DemoKit
import SwiftUI

/// `CardChrome` with one change: the content arrives as an `AnyView` input instead of a generic parameter.
///
/// An `AnyView` keeps its content in a class box, and every update builds a new box. SwiftUI compares class
/// references by identity, so this view never compares equal to its previous value and its body runs on every
/// update, whether or not the card's data changed.
struct NestedChrome: View {
    private let id: Int
    private let title: String
    private let content: AnyView
    @Environment(DashboardStore.self) private var store

    init(id: Int, title: String, content: AnyView) {
        self.id = id
        self.title = title
        self.content = content
    }

    var body: some View {
        // Counted here, not in `onAppear`: a card that SwiftUI re-runs without re-creating appears only once.
        BodyCounter.shared.record()
        return VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Remove \(title)", systemImage: "xmark.circle") {
                    withAnimation {
                        store.remove(id: id)
                    }
                }
                .labelStyle(.iconOnly)
                .minimumTapTarget()
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .onAppear {
            AppearanceCounter.shared.record()
        }
    }
}

// swiftlint:enable no_any_view
