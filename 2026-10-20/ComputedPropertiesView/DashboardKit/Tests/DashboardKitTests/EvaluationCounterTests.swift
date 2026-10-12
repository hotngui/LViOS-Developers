import Foundation
import Testing
@testable import DashboardKit

@Suite @MainActor struct EvaluationCounterTests {
    @Test func recordReturnsTheIncrementedCount() {
        let counter = EvaluationCounter()
        #expect(counter.record(.budget) == 1)
        #expect(counter.record(.budget) == 2)
        #expect(counter.count(for: .budget) == 2)
    }

    @Test func sectionsAreCountedIndependently() {
        let counter = EvaluationCounter()
        counter.record(.budget)
        counter.record(.budget)
        counter.record(.chart)
        #expect(counter.count(for: .budget) == 2)
        #expect(counter.count(for: .chart) == 1)
        #expect(counter.count(for: .summary) == 0)
    }

    @Test func recordingABodyRunTellsTheInteractionTimerContentWasRebuilt() {
        let timer = InteractionTimer()
        let counter = EvaluationCounter(interactionTimer: timer)
        let tap = Date.now
        timer.begin(.toggleBalances, at: tap)
        counter.record(.summary)
        timer.frameRendered(at: tap.addingTimeInterval(0.25))
        #expect(timer.last?.interaction == .toggleBalances)
        #expect(abs((timer.last?.total.inMilliseconds ?? 0) - 250) < 0.01)
    }

    @Test func resetClearsAllCounts() {
        let counter = EvaluationCounter()
        counter.record(.categories)
        counter.reset()
        #expect(counter.count(for: .categories) == 0)
        #expect(counter.record(.categories) == 1)
    }
}
