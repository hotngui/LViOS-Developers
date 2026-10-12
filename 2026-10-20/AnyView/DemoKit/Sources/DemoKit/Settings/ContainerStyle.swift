import Foundation

/// Which container the dashboard puts its cards in. Raw values are lowercase so launch arguments match after lowercasing.
public enum ContainerStyle: String, CaseIterable, Identifiable, Sendable {
    case stack
    case lazyStack = "lazystack"
    case list

    public static let standard: ContainerStyle = .stack

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .stack: "Stack"
        case .lazyStack: "Lazy stack"
        case .list: "List"
        }
    }
}
