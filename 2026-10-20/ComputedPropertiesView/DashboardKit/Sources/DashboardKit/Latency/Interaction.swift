import Foundation

/// A user action whose tap-to-display time the HUD measures.
public enum Interaction: String, CaseIterable, Sendable {
    case openDashboard, toggleBalances, pendingOnly, timeRange

    public var title: LocalizedStringResource {
        switch self {
        case .openDashboard: "Open"
        case .toggleBalances: "Balances"
        case .pendingOnly: "Pending only"
        case .timeRange: "Time range"
        }
    }
}
