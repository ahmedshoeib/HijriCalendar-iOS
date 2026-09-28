import Foundation

public enum HijriMonthPosition: String, Codable, Sendable {
    case previous
    case current
    case next
}

public struct HijriCalendarDay: Hashable, Sendable {
    public let date: HijriDate
    public let foundationDate: Date
    public let monthPosition: HijriMonthPosition
    public let isToday: Bool
    public let isWithinBounds: Bool

    public init(
        date: HijriDate,
        foundationDate: Date,
        monthPosition: HijriMonthPosition,
        isToday: Bool,
        isWithinBounds: Bool
    ) {
        self.date = date
        self.foundationDate = foundationDate
        self.monthPosition = monthPosition
        self.isToday = isToday
        self.isWithinBounds = isWithinBounds
    }
}

public struct HijriMonthGrid: Hashable, Sendable {
    public let month: HijriMonth
    public let days: [HijriCalendarDay]

    public init(month: HijriMonth, days: [HijriCalendarDay]) {
        self.month = month
        self.days = days
    }

    public var weeks: [[HijriCalendarDay]] {
        stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
}

/// Generates the stable 6x7 month model consumed by both UI frameworks.
public struct HijriCalendarEngine: Sendable {
    public var configuration: HijriCalendarConfiguration

    public init(configuration: HijriCalendarConfiguration = .init()) {
        self.configuration = configuration
    }

    public func monthGrid(for month: HijriMonth) -> HijriMonthGrid {
        let calendar = configuration.calendar
        let monthStartValue = HijriDate(year: month.year, month: month.month, day: 1)
        guard let monthStart = configuration.foundationDate(from: monthStartValue) else {
            return HijriMonthGrid(month: month, days: [])
        }

        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingDayCount = (weekday - configuration.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDayCount, to: monthStart) else {
            return HijriMonthGrid(month: month, days: [])
        }

        let today = configuration.hijriDate(from: Date())
        let days = (0..<42).compactMap { offset -> HijriCalendarDay? in
            guard let foundationDate = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let date = configuration.hijriDate(from: foundationDate)
            let position: HijriMonthPosition
            if HijriMonth(date: date) < month {
                position = .previous
            } else if HijriMonth(date: date) > month {
                position = .next
            } else {
                position = .current
            }
            return HijriCalendarDay(
                date: date,
                foundationDate: foundationDate,
                monthPosition: position,
                isToday: date == today,
                isWithinBounds: configuration.contains(date)
            )
        }
        return HijriMonthGrid(month: month, days: days)
    }

    public func weekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = configuration.calendar
        formatter.locale = configuration.locale
        var symbols = formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        guard symbols.count == 7 else { return symbols }
        let offset = configuration.firstWeekday - 1
        symbols = Array(symbols[offset...] + symbols[..<offset])
        return symbols
    }

    public func dayLabel(for date: HijriDate) -> String {
        dayLabel(for: date, minimumIntegerDigits: 1)
    }

    /// Returns a localized day number padded to at least the requested width.
    public func dayLabel(
        for date: HijriDate,
        minimumIntegerDigits: Int
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = configuration.locale
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = max(1, minimumIntegerDigits)
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: date.day)) ?? String(date.day)
    }

    /// A localized, user-facing Hijri date such as "10 Ramadan 1447".
    ///
    /// This formats the supplied Hijri components directly, so manual day
    /// adjustments and official month-start overrides remain represented
    /// correctly in the label.
    public func dateLabel(for date: HijriDate) -> String {
        let monthTitle = HijriMonth(date: date).title(
            locale: configuration.locale,
            calendar: configuration.calendar
        )
        return "\(dayLabel(for: date)) \(monthTitle)"
    }
}
