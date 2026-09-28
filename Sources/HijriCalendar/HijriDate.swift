import Foundation

/// Hijri date components interpreted using a chosen ``HijriCalendarSystem``.
public struct HijriDate: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        precondition(month >= 1 && month <= 12, "Hijri month must be between 1 and 12")
        precondition(day >= 1 && day <= 30, "Hijri day must be between 1 and 30")
        self.year = year
        self.month = month
        self.day = day
    }

    public init(
        date: Date,
        calendar: Calendar = .hijriUmmAlQura()
    ) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(
            year: components.year ?? 1,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    /// Resolves this Hijri value to noon in the supplied Foundation calendar.
    public func foundationDate(
        in calendar: Calendar = .hijriUmmAlQura()
    ) -> Date? {
        calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        ))
    }

    public static func < (lhs: HijriDate, rhs: HijriDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d AH", year, month, day)
    }
}
