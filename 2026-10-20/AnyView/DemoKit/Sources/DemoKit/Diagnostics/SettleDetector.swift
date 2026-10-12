/// Decides when frame pacing has settled after a load, so the compact HUD can restart its statistics by itself.
///
/// Arm it when a load happens, then feed it every frame. It asks for a restart exactly once per arming: after
/// `requiredCalmFrames` frames in a row that were not hitches, or at the first frame `maximumWait` or more after the
/// first frame it saw since arming, whichever comes first.
struct SettleDetector: Sendable, Equatable {
    static let requiredCalmFrames = 30
    /// The longest it waits, counted from the first frame after arming, so a stack that never runs on pace still
    /// gets its statistics restarted.
    static let maximumWait: Duration = .seconds(5)

    private(set) var isArmed = false
    private var calmFrames = 0
    private var firstFrame: Duration?

    /// A load happened. Arming while armed starts the wait again.
    mutating func arm() {
        isArmed = true
        calmFrames = 0
        firstFrame = nil
    }

    /// Stops waiting without asking for a restart.
    mutating func disarm() {
        isArmed = false
        calmFrames = 0
        firstFrame = nil
    }

    /// Feeds one frame. Returns true when the statistics should restart now.
    mutating func frame(at timestamp: Duration, wasHitch: Bool) -> Bool {
        guard isArmed else { return false }
        let start = firstFrame ?? timestamp
        firstFrame = start
        calmFrames = wasHitch ? 0 : calmFrames + 1
        guard calmFrames >= Self.requiredCalmFrames || timestamp - start >= Self.maximumWait else { return false }
        disarm()
        return true
    }
}
