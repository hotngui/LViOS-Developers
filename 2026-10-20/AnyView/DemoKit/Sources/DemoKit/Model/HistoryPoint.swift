/// One point of a sparkline. Its id is the tick that produced it, so chart points have real identity, not an offset.
public struct HistoryPoint: Identifiable, Equatable, Sendable {
    public let id: Int
    public let value: Double

    public init(id: Int, value: Double) {
        self.id = id
        self.value = value
    }
}
