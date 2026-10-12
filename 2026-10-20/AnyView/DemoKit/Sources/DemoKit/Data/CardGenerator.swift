/// Deterministic card data. Pure functions, so every app and every test sees the same sequence for a seed.
public enum CardGenerator {
    public static let defaultSeed: UInt64 = 0x5EED_CA2D
    /// How many cards change on each tick, whatever the intensity: work proportional to what changed, not to what exists.
    public static let changesPerTick = 10
    public static let historyLimit = 30
    /// One title word per kind, in `CardKind.allCases` order.
    static let titleWords = ["Orders", "Load", "Alerts", "Latency", "Rate"]

    /// The base set: kinds cycle in order, ids run from 0, titles and values are deterministic for the seed.
    public static func cards(count: Int, seed: UInt64 = defaultSeed) -> [CardSnapshot] {
        guard count > 0 else { return [] }
        var generator = SeededRandomGenerator(seed: seed)
        return (0..<count).map { index in
            let kind = CardKind.allCases[index % CardKind.allCases.count]
            let value = initialValue(for: kind, using: &generator)
            let history = kind == .sparkline ? [HistoryPoint(id: 0, value: value)] : []
            return CardSnapshot(id: index, kind: kind, title: title(for: kind, index: index), value: value, history: history)
        }
    }

    /// The indices `tick` changes: `changesPerTick` consecutive positions, cycling through the set, fewer only when
    /// fewer cards exist. Consecutive residues are distinct, so no card is changed twice in one tick.
    public static func changedIndices(tick: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        let changes = min(changesPerTick, count)
        return (0..<changes).map { (tick * changesPerTick + $0) % count }
    }

    /// `cards` after `tick`: the changed cards random-walk, and a changed sparkline gains one history point.
    public static func tick(_ cards: [CardSnapshot], tick: Int, seed: UInt64 = defaultSeed) -> [CardSnapshot] {
        var generator = SeededRandomGenerator(seed: seed &+ UInt64(tick) &* 0x9E37_79B9)
        var updated = cards
        for index in changedIndices(tick: tick, count: cards.count) {
            updated[index] = step(updated[index], tick: tick, using: &generator)
        }
        return updated
    }

    static func title(for kind: CardKind, index: Int) -> String {
        let word = titleWords[CardKind.allCases.firstIndex(of: kind) ?? 0]
        return "\(word) \(index)"
    }

    static func initialValue(for kind: CardKind, using generator: inout SeededRandomGenerator) -> Double {
        switch kind {
        case .gauge: Double.random(in: 0.1...0.9, using: &generator)
        case .stat, .toggle, .sparkline, .pulse: Double(Int.random(in: 100...9_999, using: &generator))
        }
    }

    /// One random-walk step that always produces a different snapshot: the delta is never zero, a count never goes
    /// below zero (it steps up instead), and a gauge reflects off 0 and 1 rather than sticking to them.
    static func step(_ card: CardSnapshot, tick: Int, using generator: inout SeededRandomGenerator) -> CardSnapshot {
        var next = card
        switch card.kind {
        case .gauge:
            let magnitude = Double.random(in: 0.02...0.15, using: &generator)
            let delta = Bool.random(using: &generator) ? magnitude : -magnitude
            next.value = steppedGauge(card.value, by: delta)
        case .stat, .toggle, .sparkline, .pulse:
            let magnitude = Double(Int.random(in: 1...50, using: &generator))
            let goesDown = Bool.random(using: &generator) && card.value - magnitude >= 0
            next.value = goesDown ? card.value - magnitude : card.value + magnitude
        }
        if card.kind == .sparkline {
            next.history = Array((card.history + [HistoryPoint(id: tick, value: next.value)]).suffix(historyLimit))
        }
        return next
    }

    /// A gauge value moved by `delta` and reflected back into 0…1. Reflection can land exactly on the starting value
    /// (when `delta == 2 - 2 × value`), so that case is nudged toward the middle to keep the step a real change.
    static func steppedGauge(_ value: Double, by delta: Double) -> Double {
        let stepped = reflected(value + delta, into: 0...1)
        guard stepped == value else { return stepped }
        return reflected(value < 0.5 ? value + abs(delta) / 2 : value - abs(delta) / 2, into: 0...1)
    }

    static func reflected(_ value: Double, into range: ClosedRange<Double>) -> Double {
        if value > range.upperBound { return range.upperBound - (value - range.upperBound) }
        if value < range.lowerBound { return range.lowerBound + (range.lowerBound - value) }
        return value
    }
}
