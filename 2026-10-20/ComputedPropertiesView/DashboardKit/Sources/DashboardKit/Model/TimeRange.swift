import Foundation

/// The dashboard's time-range picker values. Each covers the last `dayCount` whole days up to and including the anchor day.
public enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case week, month, quarter, year

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .quarter: "Quarter"
        case .year: "Year"
        }
    }

    public var dayCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        }
    }

    /// Half-open range from the start of the first day to the start of the day after `anchor`.
    public func dateRange(endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar) -> Range<Date> {
        let startOfAnchorDay = calendar.startOfDay(for: anchor)
        let end = calendar.date(byAdding: .day, value: 1, to: startOfAnchorDay) ?? startOfAnchorDay
        let start = calendar.date(byAdding: .day, value: -dayCount, to: end) ?? end
        return start..<end
    }

    /// The equally long range that ends where `dateRange` starts.
    public func previousDateRange(
        endingOn anchor: Date = DemoClock.anchorDate, calendar: Calendar = DemoClock.calendar
    ) -> Range<Date> {
        let current = dateRange(endingOn: anchor, calendar: calendar)
        let start = calendar.date(byAdding: .day, value: -dayCount, to: current.lowerBound) ?? current.lowerBound
        return start..<current.lowerBound
    }
}
