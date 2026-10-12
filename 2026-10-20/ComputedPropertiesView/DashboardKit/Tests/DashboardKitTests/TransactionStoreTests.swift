import Testing
@testable import DashboardKit

@Suite @MainActor struct TransactionStoreTests {
    @Test func loadGeneratesTheIntensitysTransactionCount() async {
        let store = TransactionStore()
        await store.load(.light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(store.loadedIntensity == .light)
        #expect(!store.isLoading)
    }

    @Test func theLatestRequestWinsWhenAnEarlierOneFinishesLater() async {
        let store = TransactionStore()
        let heavy = Task { await store.load(.heavy) }
        await Task.yield()
        let light = Task { await store.load(.light) }
        heavy.cancel()
        await heavy.value
        await light.value
        #expect(store.loadedIntensity == .light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(!store.isLoading)
    }

    @Test func switchingBackToTheLoadedLevelDiscardsTheInFlightLoad() async {
        let store = TransactionStore()
        await store.load(.light)
        let heavy = Task { await store.load(.heavy) }
        await Task.yield()
        let backToLight = Task { await store.load(.light) }
        await heavy.value
        await backToLight.value
        #expect(store.loadedIntensity == .light)
        #expect(store.transactions.count == Intensity.light.transactionCount)
        #expect(!store.isLoading)
    }
}
