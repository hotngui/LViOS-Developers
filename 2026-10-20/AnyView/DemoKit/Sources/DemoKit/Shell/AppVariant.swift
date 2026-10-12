import SwiftUI

/// Which of the six demo apps is running. Shown on the HUD so every video frame identifies itself.
public enum AppVariant: Sendable {
    case erased, boxed, nested, wrapped, concrete, eager

    /// The short name: the app's display name and navigation title.
    public var name: LocalizedStringResource {
        switch self {
        case .erased: "Erased"
        case .boxed: "Boxed"
        case .nested: "Nested"
        case .wrapped: "Wrapped"
        case .concrete: "Concrete"
        case .eager: "Eager"
        }
    }

    /// The HUD badge text.
    public var title: LocalizedStringResource {
        switch self {
        case .erased: "AnyView + UUID"
        case .boxed: "AnyView + stable id"
        case .nested: "Nested + stable id"
        case .wrapped: "Wrapped + stable id"
        case .concrete: "Concrete + stable id"
        case .eager: "Eager VStack"
        }
    }

    /// One line explaining what this variant demonstrates.
    public var explanation: LocalizedStringResource {
        switch self {
        case .erased: "Every update rebuilds each card's ViewModel and its AnyView with a new UUID, so SwiftUI replaces every card."
        case .boxed:
            "Every update rebuilds each card's ViewModel and AnyView, but the ids stay stable, so only AnyView's own cost remains."
        case .nested:
            """
            Every card is built from AnyViews inside AnyViews, with stable ids, so each card's chrome re-runs on every \
            update, changed or not.
            """
        case .wrapped:
            """
            Concrete with one change: each row is wrapped in an AnyView, so a List can't template its rows and evaluates \
            every row on every update.
            """
        case .concrete: "Cards are concrete views with stable ids, so SwiftUI updates only what changed."
        case .eager:
            "A plain VStack in a ScrollView keeps every card alive, so every touch is tested against all of them."
        }
    }

    /// Badge fill. The badge's text is black, which contrasts with all six colors.
    public var tint: Color {
        switch self {
        case .erased: .orange
        case .boxed: .yellow
        case .nested: .pink
        case .wrapped: .purple
        case .concrete: .green
        case .eager: .cyan
        }
    }
}
