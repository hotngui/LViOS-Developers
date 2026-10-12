/// Everything a card view renders. A small `Equatable` value type with a stable integer id, so SwiftUI can compare it
/// cheaply and match it across updates.
public struct CardSnapshot: Identifiable, Equatable, Sendable {
    public let id: Int
    public let kind: CardKind
    public let title: String
    /// The live number: a count for most kinds, 0…1 for a gauge.
    public var value: Double
    /// The last `CardGenerator.historyLimit` values; empty for every kind but `.sparkline`.
    public var history: [HistoryPoint]

    public init(id: Int, kind: CardKind, title: String, value: Double, history: [HistoryPoint] = []) {
        self.id = id
        self.kind = kind
        self.title = title
        self.value = value
        self.history = history
    }
}
