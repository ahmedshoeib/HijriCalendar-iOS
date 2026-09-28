import Foundation

/// Hijri year and month components interpreted using a chosen calendar system.
public struct HijriMonth: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        precondition(month >= 1 && month <= 12, "Hijri month must be between 1 and 12")
        self.year = year
        self.month = month
    }

    public init(date: HijriDate) {
        self.init(year: date.year, month: date.month)
    }

    public init(
        foundationDate: Date,
        calendar: Calendar = .hijriUmmAlQura()
    ) {
        let date = HijriDate(date: foundationDate, calendar: calendar)
        self.init(date: date)
    }

    public func advanced(
        by offset: Int,
        calendar: Calendar = .hijriUmmAlQura()
    ) -> HijriMonth {
        guard
            let start = HijriDate(year: year, month: month, day: 1).foundationDate(in: calendar),
            let result = calendar.date(byAdding: .month, value: offset, to: start)
        else {
            return self
        }
        return HijriMonth(foundationDate: result, calendar: calendar)
    }

    public func title(
        locale: Locale = .current,
        calendar: Calendar = .hijriUmmAlQura()
    ) -> String {
        guard let date = HijriDate(year: year, month: month, day: 1).foundationDate(in: calendar) else {
            return description
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMM y")
        return formatter.string(from: date)
    }

    public static func < (lhs: HijriMonth, rhs: HijriMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    public var description: String {
        String(format: "%04d-%02d AH", year, month)
    }
}
