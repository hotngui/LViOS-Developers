import Foundation

/// How much data the dashboard works with. Named steps, so a capture can be reproduced exactly.
public enum Intensity: String, CaseIterable, Identifiable, Sendable {
    case light, realistic, heavy, severe, extreme

    public static let standard: Intensity = .realistic

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .light: "Light"
        case .realistic: "Realistic"
        case .heavy: "Heavy"
        case .severe: "Severe"
        case .extreme: "Extreme"
        }
    }

    /// Transactions generated for the year.
    public var transactionCount: Int {
        switch self {
        case .light: 1_000
        case .realistic: 3_000
        case .heavy: 10_000
        case .severe: 30_000
        case .extreme: 100_000
        }
    }

    /// Rows shown in the non-lazy Recent Transactions list.
    public var recentRowLimit: Int {
        switch self {
        case .light: 25
        case .realistic: 50
        case .heavy: 150
        case .severe: 300
        case .extreme: 600
        }
    }
}
