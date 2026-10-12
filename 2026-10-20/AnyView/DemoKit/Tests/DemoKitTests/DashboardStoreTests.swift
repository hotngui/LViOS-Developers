import Foundation
import Testing
@testable import DemoKit

@MainActor
@Suite struct DashboardStoreTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let later = Date(timeIntervalSinceReferenceDate: 2_000)

    func loadedStore() -> DashboardStore {
        let store = DashboardStore()
        store.load(.light, at: start)
        return store
    }

    func changedIndices(_ before: [CardSnapshot], _ after: [CardSnapshot]) -> [Int] {
        zip(before, after).enumerated().filter { $0.element.0 != $0.element.1 }.map(\.offset)
    }

    @Test func loadPopulatesCardsSetsTimeAndBumpsVersion() {
        let store = DashboardStore()
        #expect(store.cards.isEmpty)
        #expect(store.dataVersion == 0)
        store.load(.light, at: start)
        #expect(store.cards == CardGenerator.cards(count: 100))
        #expect(store.lastLoaded == start)
        #expect(store.dataVersion == 1)
    }

    @Test func tickBumpsVersionAndChangesOnlyTheExpectedCards() {
        let store = loadedStore()
        let before = store.cards
        store.tick()
        #expect(store.tickCount == 1)
        #expect(store.dataVersion == 2)
        #expect(store.cards == CardGenerator.tick(before, tick: 1))
        #expect(changedIndices(before, store.cards) == CardGenerator.changedIndices(tick: 1, count: 100))
    }

    @Test func removeDropsTheCardAndLaterTicksAndReloadsKeepItGone() {
        let store = loadedStore()
        store.remove(id: 7)
        #expect(store.dataVersion == 2)
        #expect(store.cards.count == 99)
        #expect(store.removedIDs == [7])
        store.tick()
        store.reload(at: later)
        #expect(store.cards.count == 99)
        #expect(!store.cards.contains { $0.id == 7 })
    }

    @Test func reloadYieldsEqualCardsANewerTimeAndABumpedVersion() {
        let store = loadedStore()
        let before = store.cards
        store.reload(at: later)
        #expect(store.cards == before)
        #expect(store.lastLoaded == later)
        #expect(store.dataVersion == 2)
    }

    @Test func resetRestoresRemovedCardsAndRestartsTheSequence() {
        let store = loadedStore()
        store.tick()
        store.remove(id: 3)
        store.reset(at: later)
        #expect(store.cards == CardGenerator.cards(count: 100))
        #expect(store.tickCount == 0)
        #expect(store.removedIDs.isEmpty)
        #expect(store.lastLoaded == later)
        #expect(store.dataVersion == 4)
    }

    /// Review Focus 3.
    @Test func changingIntensityRegeneratesAndClearsRemovalsAndTicks() {
        let store = loadedStore()
        store.tick()
        store.remove(id: 1)
        store.load(.heavy, at: later)
        #expect(store.cards == CardGenerator.cards(count: 300))
        #expect(store.removedIDs.isEmpty)
        #expect(store.tickCount == 0)
        #expect(store.lastLoaded == later)
    }

    @Test func cardCountTracksTheVisibleCards() {
        let store = DashboardStore()
        #expect(store.cardCount == 0)
        store.load(.light, at: start)
        #expect(store.cardCount == 100)
        store.remove(id: 7)
        #expect(store.cardCount == 99)
        store.reset(at: later)
        #expect(store.cardCount == 100)
    }

    /// Review Focus 1.
    @Test func removingEveryCardLeavesAnEmptyStoreThatStillWorks() {
        let store = loadedStore()
        for card in store.cards {
            store.remove(id: card.id)
        }
        #expect(store.cards.isEmpty)
        store.tick()
        store.reload(at: later)
        #expect(store.cards.isEmpty)
        store.reset(at: later)
        #expect(store.cards.count == 100)
    }

    @Test func loadingByCardCountPopulatesSetsTimeAndBumpsVersion() {
        let store = DashboardStore()
        store.load(cardCount: 10, at: start)
        #expect(store.cards == CardGenerator.cards(count: 10))
        #expect(store.cardCount == 10)
        #expect(store.lastLoaded == start)
        #expect(store.dataVersion == 1)
    }

    @Test func loadingByCardCountClearsRemovalsAndTicks() {
        let store = loadedStore()
        store.tick()
        store.remove(id: 1)
        store.load(cardCount: 300, at: later)
        #expect(store.cards == CardGenerator.cards(count: 300))
        #expect(store.removedIDs.isEmpty)
        #expect(store.tickCount == 0)
        #expect(store.lastLoaded == later)
    }

    @Test func loadingByIntensityStillYieldsTheIntensitysCount() {
        let store = DashboardStore()
        for level in Intensity.allCases {
            store.load(level, at: start)
            #expect(store.cards == CardGenerator.cards(count: level.cardCount))
        }
    }

    /// Review Focus 2.
    @Test func loadingZeroOrANegativeCountLeavesAnEmptyStoreThatStillLoads() {
        let store = DashboardStore()
        store.load(cardCount: 0, at: start)
        #expect(store.cards.isEmpty)
        #expect(store.cardCount == 0)
        store.load(cardCount: -5, at: start)
        #expect(store.cards.isEmpty)
        store.tick()
        store.reset(at: later)
        #expect(store.cards.isEmpty)
        store.load(cardCount: 10, at: later)
        #expect(store.cardCount == 10)
    }
}
