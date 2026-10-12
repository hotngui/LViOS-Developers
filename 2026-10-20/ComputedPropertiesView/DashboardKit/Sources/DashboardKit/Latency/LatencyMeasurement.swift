/// One completed tap-to-display timing: from the tap until the first frame that showed the result.
///
/// For an open, that's the dashboard's first frame; the push's slide-in animation (identical in both apps) isn't included.
public struct LatencyMeasurement: Equatable, Sendable {
    public let interaction: Interaction
    public let total: Duration
}
