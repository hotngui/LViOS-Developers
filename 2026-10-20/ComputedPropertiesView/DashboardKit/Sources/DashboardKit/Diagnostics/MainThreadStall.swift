/// Deliberately blocks the main thread. Used by "Simulate a 100 ms stall" to prove the HUD detects a known hitch.
enum MainThreadStall {
    @MainActor
    static func run(for duration: Duration) {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: duration)
        while clock.now < deadline {
            // Busy-wait on purpose: this simulates expensive main-thread work.
        }
    }
}
