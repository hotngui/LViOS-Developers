import os

/// Reads launch arguments, so Instruments runs and recordings start in the same configuration every time.
public enum LaunchArguments {
    static let logger = Logger(subsystem: "com.hotngui.DashboardKit", category: "LaunchArguments")

    /// `-intensity <level>`, case-insensitive. Missing or unknown values fall back to `Intensity.standard`.
    public static func intensity(from arguments: [String]) -> Intensity {
        guard let flagIndex = arguments.firstIndex(of: "-intensity") else { return .standard }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else {
            logger.warning("-intensity has no value; using the default level.")
            return .standard
        }
        let value = arguments[valueIndex].lowercased()
        guard let level = Intensity(rawValue: value) else {
            logger.warning("Unknown -intensity value '\(value, privacy: .public)'; using the default level.")
            return .standard
        }
        return level
    }

    /// `-showEvaluationBadges` turns on the "body runs" badges.
    public static func showsEvaluationBadges(from arguments: [String]) -> Bool {
        arguments.contains("-showEvaluationBadges")
    }

    /// `-liveUpdates off` (any case) turns the live feed off; it's on otherwise.
    public static func liveUpdatesEnabled(from arguments: [String]) -> Bool {
        guard let flagIndex = arguments.firstIndex(of: "-liveUpdates") else { return true }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return true }
        return arguments[valueIndex].lowercased() != "off"
    }
}
