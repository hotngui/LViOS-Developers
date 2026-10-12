import Foundation

/// The demo's fixed "today". Data is generated relative to it, so captures made on different days show the same numbers.
public enum DemoClock {
    /// Gregorian calendar pinned to GMT, so day buckets and date labels agree on every device.
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// 2026-09-30 00:00:00 GMT.
    public static let anchorDate = Date(timeIntervalSince1970: 1_790_726_400)
}
