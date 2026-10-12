import os

/// Reads launch arguments, so Instruments runs and recordings start in the same configuration every time.
/// Flags are exact (`-intensity`); values are case-insensitive. Anything missing or unknown falls back to the default
/// and logs a warning.
public enum LaunchArguments {
    static let logger = Logger(subsystem: "com.hotngui.DemoKit", category: "LaunchArguments")

    public static func intensity(from arguments: [String]) -> Intensity {
        value(for: "-intensity", from: arguments) ?? .standard
    }

    public static func tickRate(from arguments: [String]) -> TickRate {
        value(for: "-tickRate", from: arguments) ?? .standard
    }

    public static func containerStyle(from arguments: [String]) -> ContainerStyle {
        value(for: "-container", from: arguments) ?? .standard
    }

    /// `-cards <n>`, where `n` is one of `CardCount`'s six values. The Eager app's only setting.
    public static func cardCount(from arguments: [String]) -> CardCount {
        guard let raw = rawValue(after: "-cards", in: arguments) else { return .standard }
        guard let number = Int(raw), let count = CardCount(rawValue: number) else {
            logger.warning("Unknown -cards value '\(raw, privacy: .public)'; using the default.")
            return .standard
        }
        return count
    }

    /// `-liveUpdates off` (any case) turns the live feed off; it's on otherwise.
    public static func liveUpdatesEnabled(from arguments: [String]) -> Bool {
        rawValue(after: "-liveUpdates", in: arguments) != "off"
    }

    /// The lowercased value after `flag`, or nil when the flag is absent or has no value.
    static func rawValue(after flag: String, in arguments: [String]) -> String? {
        guard let flagIndex = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else {
            logger.warning("\(flag, privacy: .public) has no value; using the default.")
            return nil
        }
        return arguments[valueIndex].lowercased()
    }

    static func value<Setting: RawRepresentable>(for flag: String, from arguments: [String]) -> Setting?
    where Setting.RawValue == String {
        guard let raw = rawValue(after: flag, in: arguments) else { return nil }
        guard let setting = Setting(rawValue: raw) else {
            logger.warning("Unknown \(flag, privacy: .public) value '\(raw, privacy: .public)'; using the default.")
            return nil
        }
        return setting
    }
}
