import Foundation
import Observation

/// The data layer both kinds of dashboard read. Every mutation recomputes the stored `cards` array and bumps
/// `dataVersion`; `cards` is `Equatable`, so an equal assignment (a Reload) does not notify observers, while
/// `dataVersion` and `lastLoaded` always change.
@MainActor
@Observable
public final class DashboardStore {
    /// The cards a dashboard shows: everything generated, minus the removed ids.
    public private(set) var cards: [CardSnapshot] = []
    /// When the data was last "pulled from the server" (load, reload, reset).
    public private(set) var lastLoaded: Date = .distantPast
    /// Bumped by every mutation, including reloads that produce equal data.
    public private(set) var dataVersion = 0
    public private(set) var removedIDs: Set<Int> = []
    public private(set) var tickCount = 0
    /// `cards.count`, stored so a view that shows only the count depends on this and not on the whole array.
    public private(set) var cardCount = 0
    public let seed: UInt64

    /// The full set, including removed cards, so ticks follow the same sequence whatever was removed.
    private var allCards: [CardSnapshot] = []
    private var generatedCount = 0

    public init(seed: UInt64 = CardGenerator.defaultSeed) {
        self.seed = seed
    }

    /// Regenerates the base set for `intensity`, clearing removals and the tick sequence.
    public func load(_ intensity: Intensity, at date: Date = .now) {
        load(cardCount: intensity.cardCount, at: date)
    }

    /// Regenerates a base set of `count` cards, clearing removals and the tick sequence. Zero or less gives none.
    public func load(cardCount count: Int, at date: Date = .now) {
        generatedCount = count
        restart(at: date)
    }

    /// One live update: the generator changes ten cards of the full set.
    public func tick() {
        tickCount += 1
        allCards = CardGenerator.tick(allCards, tick: tickCount, seed: seed)
        publishCards()
    }

    /// Removes the card for the rest of the session; reloads do not bring it back, `reset` does.
    public func remove(id: Int) {
        removedIDs.insert(id)
        publishCards()
    }

    /// Simulates pulling the data from the server again and getting exactly the same result.
    public func reload(at date: Date = .now) {
        lastLoaded = date
        publishCards()
    }

    /// Restores removed cards and restarts the tick sequence at the current intensity.
    public func reset(at date: Date = .now) {
        restart(at: date)
    }

    private func restart(at date: Date) {
        removedIDs = []
        tickCount = 0
        allCards = CardGenerator.cards(count: generatedCount, seed: seed)
        lastLoaded = date
        publishCards()
    }

    private func publishCards() {
        cards = allCards.filter { !removedIDs.contains($0.id) }
        cardCount = cards.count
        dataVersion += 1
    }
}
