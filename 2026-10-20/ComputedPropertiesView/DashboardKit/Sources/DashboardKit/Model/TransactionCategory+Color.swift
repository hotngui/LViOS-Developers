import SwiftUI

extension TransactionCategory {
    /// The category's color in the chart and breakdown. Text never relies on it alone.
    public var color: Color {
        switch self {
        case .income: .green
        case .groceries: .mint
        case .dining: .orange
        case .transport: .blue
        case .home: .brown
        case .utilities: .yellow
        case .entertainment: .purple
        case .shopping: .pink
        case .health: .red
        }
    }
}
