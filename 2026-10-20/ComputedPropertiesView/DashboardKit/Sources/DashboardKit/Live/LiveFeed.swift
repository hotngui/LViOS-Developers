import Foundation

/// A deterministic stream of small pending charges, standing in for a live data feed.
public enum LiveFeed {
    static let merchants = [
        "Corner Coffee", "Metro Tap", "Snack Bar", "Bakery", "Bike Share", "Tea House", "Newsstand", "Juice Stand"
    ]

    /// The arrival for `tick`. The same tick always gives the same arrival.
    public static func arrival(at tick: Int, seed: UInt64 = SampleDataGenerator.defaultSeed) -> LiveArrival {
        var generator = SeededRandomGenerator(seed: seed &+ UInt64(truncatingIfNeeded: tick) &* 0x9E37_79B9)
        let merchant = merchants[Int.random(in: 0..<merchants.count, using: &generator)]
        let cents = Int.random(in: 99...2_500, using: &generator)
        return LiveArrival(id: tick, merchant: merchant, amount: Decimal(cents) / 100)
    }

    /// `arrivals` plus the next arrival, keeping only the last `limit`.
    public static func next(after arrivals: [LiveArrival], limit: Int = 30) -> [LiveArrival] {
        let tick = (arrivals.last?.id ?? -1) + 1
        return Array((arrivals + [arrival(at: tick)]).suffix(limit))
    }
}
