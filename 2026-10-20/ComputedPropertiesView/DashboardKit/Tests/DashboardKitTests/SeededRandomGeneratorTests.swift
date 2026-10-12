import Testing
@testable import DashboardKit

@Suite struct SeededRandomGeneratorTests {
    @Test func seedZeroMatchesTheSplitMix64ReferenceValues() {
        var generator = SeededRandomGenerator(seed: 0)
        #expect(generator.next() == 0xE220_A839_7B1D_CDAF)
        #expect(generator.next() == 0x6E78_9E6A_A1B9_65F4)
    }

    @Test func sameSeedGivesTheSameSequence() {
        var first = SeededRandomGenerator(seed: 42)
        var second = SeededRandomGenerator(seed: 42)
        let firstValues = (0..<5).map { _ in first.next() }
        let secondValues = (0..<5).map { _ in second.next() }
        #expect(firstValues == secondValues)
    }

    @Test func differentSeedsGiveDifferentSequences() {
        var first = SeededRandomGenerator(seed: 1)
        var second = SeededRandomGenerator(seed: 2)
        let firstValues = (0..<5).map { _ in first.next() }
        let secondValues = (0..<5).map { _ in second.next() }
        #expect(firstValues != secondValues)
    }
}
