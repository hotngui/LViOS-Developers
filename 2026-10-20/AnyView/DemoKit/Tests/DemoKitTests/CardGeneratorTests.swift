import Testing
@testable import DemoKit

@Suite struct CardGeneratorTests {
    let base = CardGenerator.cards(count: 200)

    /// Indices whose snapshot differs between two arrays of the same length.
    func changedIndices(_ before: [CardSnapshot], _ after: [CardSnapshot]) -> [Int] {
        zip(before, after).enumerated().filter { $0.element.0 != $0.element.1 }.map(\.offset)
    }

    @Test func countMatchesAndZeroIsEmpty() {
        #expect(base.count == 200)
        #expect(CardGenerator.cards(count: 0).isEmpty)
    }

    @Test func kindsCycleInOrder() {
        let expected: [CardKind] = [.stat, .gauge, .toggle, .sparkline, .pulse, .stat, .gauge, .toggle, .sparkline, .pulse]
        #expect(base.prefix(10).map(\.kind) == expected)
    }

    @Test func idsRunFromZero() {
        #expect(base.map(\.id) == Array(0..<200))
    }

    @Test func baseDataIsDeterministicPerSeed() {
        #expect(CardGenerator.cards(count: 50, seed: 1) == CardGenerator.cards(count: 50, seed: 1))
        #expect(CardGenerator.cards(count: 50, seed: 1) != CardGenerator.cards(count: 50, seed: 2))
    }

    @Test func aTickChangesExactlyTheExpectedTenCards() {
        let next = CardGenerator.tick(base, tick: 1)
        #expect(CardGenerator.changedIndices(tick: 1, count: 200) == Array(10..<20))
        #expect(changedIndices(base, next) == Array(10..<20))
    }

    @Test func fewerThanTenCardsAllChangeAndNoneIsFine() {
        #expect(CardGenerator.changedIndices(tick: 3, count: 3).sorted() == [0, 1, 2])
        #expect(CardGenerator.changedIndices(tick: 3, count: 0).isEmpty)
        #expect(CardGenerator.tick([], tick: 3).isEmpty)
        let three = CardGenerator.cards(count: 3)
        #expect(changedIndices(three, CardGenerator.tick(three, tick: 3)) == [0, 1, 2])
    }

    @Test func aChangedSparklineGainsOnePointCappedAtThirty() {
        let next = CardGenerator.tick(base, tick: 1)
        #expect(base[13].kind == .sparkline)
        #expect(next[13].history.count == 2)
        #expect(next[13].history.last == HistoryPoint(id: 1, value: next[13].value))

        var ten = CardGenerator.cards(count: 10)
        for tick in 1...40 {
            ten = CardGenerator.tick(ten, tick: tick)
        }
        #expect(ten[3].history.count == CardGenerator.historyLimit)
        #expect(ten[3].history.first?.id == 11)
        #expect(ten[3].history.last?.id == 40)
    }

    @Test func theTickSequenceIsDeterministic() {
        var first = CardGenerator.cards(count: 30, seed: 7)
        var second = CardGenerator.cards(count: 30, seed: 7)
        for tick in 1...5 {
            first = CardGenerator.tick(first, tick: tick, seed: 7)
            second = CardGenerator.tick(second, tick: tick, seed: 7)
        }
        #expect(first == second)
    }

    /// A reflected gauge step can land exactly on the starting value (v + d reflects to 2 - v - d, which equals v when
    /// d == 2 - 2v). The step must still change the value so every tick changes exactly ten cards.
    @Test func aGaugeStepNeverLandsOnTheStartingValue() {
        #expect(CardGenerator.steppedGauge(0.95, by: 0.1) != 0.95)
        #expect((0...1).contains(CardGenerator.steppedGauge(0.95, by: 0.1)))
        #expect(CardGenerator.steppedGauge(0.5, by: 0.1) == 0.6)
        #expect(CardGenerator.steppedGauge(0.02, by: -0.1) == 0.08)
    }

    /// Review Focus 2: values stay in range and every tick keeps changing its ten cards, even after a long run.
    @Test func aThousandTicksStayInRangeAndKeepChanging() {
        var cards = CardGenerator.cards(count: 25)
        for tick in 1...1_000 {
            let next = CardGenerator.tick(cards, tick: tick)
            #expect(changedIndices(cards, next).count == 10)
            cards = next
        }
        for card in cards {
            if card.kind == .gauge {
                #expect((0...1).contains(card.value))
            } else {
                #expect(card.value >= 0)
            }
        }
    }
}
