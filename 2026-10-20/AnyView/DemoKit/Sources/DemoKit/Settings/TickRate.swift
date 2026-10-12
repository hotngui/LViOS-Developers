import Foundation

/// How often the live data ticks.
public enum TickRate: String, CaseIterable, Identifiable, Sendable {
    case slow, normal, fast

    public static let standard: TickRate = .normal

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .slow: "Slow"
        case .normal: "Normal"
        case .fast: "Fast"
        }
    }

    public var interval: Duration {
        switch self {
        case .slow: .seconds(1)
        case .normal: .milliseconds(200)
        case .fast: .milliseconds(100)
        }
    }
}
