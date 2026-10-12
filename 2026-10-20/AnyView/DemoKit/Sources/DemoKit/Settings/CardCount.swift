/// How many cards the Eager app's stack holds. The raw values are the counts, so the launch argument is the number.
public enum CardCount: Int, CaseIterable, Identifiable, Sendable {
    case ten = 10
    case oneHundred = 100
    case twoHundred = 200
    case threeHundred = 300
    case fourHundred = 400
    case fiveHundred = 500

    public static let standard: CardCount = .ten

    public var id: Self { self }
}
