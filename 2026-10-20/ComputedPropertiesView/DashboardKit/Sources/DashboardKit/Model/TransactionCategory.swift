import Foundation

/// What a transaction was for. `income` is the only category with positive amounts; the other eight are spending.
public enum TransactionCategory: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case income, groceries, dining, transport, home, utilities, entertainment, shopping, health

    /// The eight spending categories, in display order.
    public static let spending: [TransactionCategory] = allCases.filter { $0 != .income }

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .income: "Income"
        case .groceries: "Groceries"
        case .dining: "Dining"
        case .transport: "Transport"
        case .home: "Home"
        case .utilities: "Utilities"
        case .entertainment: "Entertainment"
        case .shopping: "Shopping"
        case .health: "Health"
        }
    }

    /// `title` as a plain string, for Swift Charts series names.
    public var name: String { String(localized: title) }

    public var systemImage: String {
        switch self {
        case .income: "banknote"
        case .groceries: "cart"
        case .dining: "fork.knife"
        case .transport: "car"
        case .home: "house"
        case .utilities: "bolt"
        case .entertainment: "film"
        case .shopping: "bag"
        case .health: "cross.case"
        }
    }

    public static func < (lhs: TransactionCategory, rhs: TransactionCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
