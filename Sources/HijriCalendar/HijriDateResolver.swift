import Foundation

public extension HijriCalendarConfiguration {
    /// Resolves an absolute date using the configured calculation, manual day
    /// adjustment, and authority-published month starts.
    func hijriDate(from foundationDate: Date) -> HijriDate {
        let day = normalizedDay(foundationDate)
        let calculatedDate = gregorianCalendar.date(
            byAdding: .day,
            value: dayAdjustment,
            to: day
        ) ?? day
        let estimate = HijriMonth(
            date: HijriDate(date: calculatedDate, calendar: calendar)
        )

        // Authority corrections are month-boundary changes, so a small range of
        // nearby calculated months contains the resolved day.
        for offset in -2...2 {
            let month = estimate.advanced(by: offset, calendar: calendar)
            let start = effectiveMonthStart(for: month)
            let nextMonth = month.advanced(by: 1, calendar: calendar)
            let nextStart = effectiveMonthStart(for: nextMonth)
            guard day >= start, day < nextStart else { continue }

            let dayOffset = gregorianCalendar.dateComponents(
                [.day],
                from: start,
                to: day
            ).day ?? -1
            let resolvedDay = dayOffset + 1
            guard (1...30).contains(resolvedDay) else { break }
            return HijriDate(year: month.year, month: month.month, day: resolvedDay)
        }

        return HijriDate(date: calculatedDate, calendar: calendar)
    }

    /// Resolves Hijri components to noon on their Gregorian civil day in the
    /// configured time zone, including configured corrections.
    func foundationDate(from hijriDate: HijriDate) -> Date? {
        let month = HijriMonth(date: hijriDate)
        let start = effectiveMonthStart(for: month)
        let nextMonth = month.advanced(by: 1, calendar: calendar)
        let nextStart = effectiveMonthStart(for: nextMonth)
        let monthLength = gregorianCalendar.dateComponents(
            [.day],
            from: start,
            to: nextStart
        ).day ?? 0

        guard (29...30).contains(monthLength), hijriDate.day <= monthLength else {
            return nil
        }
        return gregorianCalendar.date(
            byAdding: .day,
            value: hijriDate.day - 1,
            to: start
        )
    }

    /// Adds, replaces, or removes the official start for a month.
    ///
    /// Pass `nil` to remove the override. Published starts should form valid
    /// 29- or 30-day month intervals; otherwise affected conversions return `nil`.
    mutating func setMonthStartOverride(_ date: Date?, for month: HijriMonth) {
        monthStartOverrides.removeAll { $0.month == month }
        if let date {
            monthStartOverrides.append(
                HijriMonthStartOverride(month: month, gregorianStartDate: date)
            )
        }
    }
}

private extension HijriCalendarConfiguration {
    var gregorianCalendar: Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.locale = locale
        gregorian.timeZone = timeZone
        return gregorian
    }

    var canonicalMonthStartOverrides: [HijriMonthStartOverride] {
        var overridesByMonth: [HijriMonth: HijriMonthStartOverride] = [:]
        for override in monthStartOverrides {
            overridesByMonth[override.month] = override
        }
        return overridesByMonth.values.sorted { $0.month < $1.month }
    }

    func normalizedDay(_ date: Date) -> Date {
        let components = gregorianCalendar.dateComponents([.year, .month, .day], from: date)
        return gregorianCalendar.date(from: DateComponents(
            calendar: gregorianCalendar,
            timeZone: timeZone,
            year: components.year,
            month: components.month,
            day: components.day,
            hour: 12
        )) ?? date
    }

    func calculatedMonthStart(for month: HijriMonth) -> Date {
        let firstDay = HijriDate(year: month.year, month: month.month, day: 1)
        guard let calculatedDate = firstDay.foundationDate(in: calendar) else {
            return normalizedDay(Date.distantPast)
        }
        return gregorianCalendar.date(
            byAdding: .day,
            value: -dayAdjustment,
            to: normalizedDay(calculatedDate)
        ) ?? calculatedDate
    }

    func effectiveMonthStart(for month: HijriMonth) -> Date {
        let overrides = canonicalMonthStartOverrides
        if let exact = overrides.last(where: { $0.month == month }) {
            return normalizedDay(exact.gregorianStartDate)
        }

        if let previous = overrides.last(where: { $0.month < month }) {
            let calculatedDistance = gregorianCalendar.dateComponents(
                [.day],
                from: calculatedMonthStart(for: previous.month),
                to: calculatedMonthStart(for: month)
            ).day ?? 0
            return gregorianCalendar.date(
                byAdding: .day,
                value: calculatedDistance,
                to: normalizedDay(previous.gregorianStartDate)
            ) ?? calculatedMonthStart(for: month)
        }

        if let next = overrides.first(where: { $0.month > month }) {
            let calculatedDistance = gregorianCalendar.dateComponents(
                [.day],
                from: calculatedMonthStart(for: month),
                to: calculatedMonthStart(for: next.month)
            ).day ?? 0
            return gregorianCalendar.date(
                byAdding: .day,
                value: -calculatedDistance,
                to: normalizedDay(next.gregorianStartDate)
            ) ?? calculatedMonthStart(for: month)
        }

        return calculatedMonthStart(for: month)
    }
}
