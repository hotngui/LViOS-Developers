//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//  swiftlint:disable no_any_view
//  AnyView is the anti-pattern under test in this target; the rule is disabled for this file on purpose.

import SwiftUI

/// A ViewModel that owns its view. The container only ever sees this protocol.
@MainActor
protocol CardViewModel {
    var id: UUID { get }
    var view: AnyView { get }
}

// swiftlint:enable no_any_view
