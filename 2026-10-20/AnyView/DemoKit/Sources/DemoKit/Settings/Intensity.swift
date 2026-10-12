import Foundation

/// How many cards the dashboard shows. Named steps, so a capture can be reproduced exactly. Massive and Absurd are for
/// the lazy containers: a non-lazy stack of that many cards takes seconds to build and freezes on touch.
public enum Intensity: String, CaseIterable, Identifiable, Sendable {
    case light, realistic, heavy, severe, extreme, massive, absurd

    public static let standard: Intensity = .realistic

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .light: "Light"
        case .realistic: "Realistic"
        case .heavy: "Heavy"
        case .severe: "Severe"
        case .extreme: "Extreme"
        case .massive: "Massive"
        case .absurd: "Absurd"
        }
    }

    public var cardCount: Int {
        switch self {
        case .light: 100
        case .realistic: 200
        case .heavy: 300
        case .severe: 400
        case .extreme: 500
        case .massive: 2_000
        case .absurd: 5_000
        }
    }
}
