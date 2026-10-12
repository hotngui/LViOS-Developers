import SwiftUI

/// Which of the two demo apps is running. Shown on the HUD so every video frame identifies itself.
public enum AppVariant: Sendable {
    case computed, structs

    public var title: LocalizedStringResource {
        switch self {
        case .computed: "Computed properties"
        case .structs: "View structs"
        }
    }

    /// One line on the start screen explaining what this variant demonstrates.
    public var explanation: LocalizedStringResource {
        switch self {
        case .computed:
            "Each dashboard section is a computed property, so every change re-runs all \(DashboardSection.allCases.count)."
        case .structs: "Each dashboard section is its own view, so a change re-runs only the sections that use it."
        }
    }

    /// Badge fill. The badge's text is black, which contrasts well with both colors.
    public var tint: Color {
        switch self {
        case .computed: .orange
        case .structs: .green
        }
    }
}
