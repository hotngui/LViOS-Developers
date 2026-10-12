import Observation

/// Owns the generated transactions. Generation runs off the main actor; only the latest request is applied.
@MainActor
@Observable
public final class TransactionStore {
    public private(set) var transactions: [AccountTransaction] = []
    public private(set) var loadedIntensity: Intensity?
    public private(set) var isLoading = false

    @ObservationIgnored private var latestRequest = 0
    private let seed: UInt64

    public init(seed: UInt64 = SampleDataGenerator.defaultSeed) {
        self.seed = seed
    }

    /// Generates data for `intensity`. A newer call, including one for the level already loaded, supersedes older ones.
    public func load(_ intensity: Intensity) async {
        latestRequest += 1
        let request = latestRequest
        guard loadedIntensity != intensity else {
            isLoading = false
            return
        }
        isLoading = true
        let generated = await SampleDataGenerator.transactions(count: intensity.transactionCount, seed: seed)
        guard request == latestRequest, !Task.isCancelled else { return }
        transactions = generated
        loadedIntensity = intensity
        isLoading = false
    }
}
