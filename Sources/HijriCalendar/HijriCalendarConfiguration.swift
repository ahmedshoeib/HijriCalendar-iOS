import Foundation

/// Controls calendar mirroring independently from the app's interface direction.
public enum HijriLayoutDirection: String, CaseIterable, Codable, Sendable {
    case automatic
    case leftToRight
    case rightToLeft
}

/// Shared behavior used by both UIKit and SwiftUI calendar views.
public struct HijriCalendarConfiguration: Hashable, Codable, Sendable {
    public var localeIdentifier: String
    public var timeZoneIdentifier: String
    public var calendarSystem: HijriCalendarSystem
    /// Moves the calculated Hijri date by up to two days. Positive values show
    /// a later Hijri day. Authority month-start overrides take precedence.
    public var dayAdjustment: Int {
        didSet { dayAdjustment = min(max(dayAdjustment, -2), 2) }
    }
    /// Gregorian starts published by a trusted authority for specific Hijri months.
    ///
    /// Published dates must progress chronologically by Hijri month and remain
    /// consistent with 29- or 30-day lunar months. When duplicate months are
    /// present, the last entry is used.
    public var monthStartOverrides: [HijriMonthStartOverride]
    public var firstWeekday: Int {
        didSet { firstWeekday = min(max(firstWeekday, 1), 7) }
    }
    public var minimumDate: HijriDate?
    public var maximumDate: HijriDate?
    public var showsAdjacentMonthDates: Bool
    public var layoutDirection: HijriLayoutDirection

    public init(
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        calendarSystem: HijriCalendarSystem = .ummAlQura,
        dayAdjustment: Int = 0,
        monthStartOverrides: [HijriMonthStartOverride] = [],
        firstWeekday: Int = 1,
        minimumDate: HijriDate? = nil,
        maximumDate: HijriDate? = nil,
        showsAdjacentMonthDates: Bool = true,
        layoutDirection: HijriLayoutDirection = .automatic
    ) {
        precondition(
            minimumDate == nil || maximumDate == nil || minimumDate! <= maximumDate!,
            "minimumDate must not be later than maximumDate"
        )
        self.localeIdentifier = locale.identifier
        self.timeZoneIdentifier = timeZone.identifier
        self.calendarSystem = calendarSystem
        self.dayAdjustment = min(max(dayAdjustment, -2), 2)
        self.monthStartOverrides = monthStartOverrides
        self.firstWeekday = min(max(firstWeekday, 1), 7)
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.showsAdjacentMonthDates = showsAdjacentMonthDates
        self.layoutDirection = layoutDirection
    }

    public var locale: Locale {
        get { Locale(identifier: localeIdentifier) }
        set { localeIdentifier = newValue.identifier }
    }

    public var timeZone: TimeZone {
        get { TimeZone(identifier: timeZoneIdentifier) ?? .current }
        set { timeZoneIdentifier = newValue.identifier }
    }

    public var resolvedLayoutDirection: HijriLayoutDirection {
        guard layoutDirection == .automatic else { return layoutDirection }
        let rightToLeftLanguages: Set<String> = [
            "ar", "arc", "ckb", "dv", "fa", "he", "ku", "nqo", "ps", "sd", "syr", "ug", "ur", "yi"
        ]
        let languageCode = localeIdentifier
            .lowercased()
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? ""
        return rightToLeftLanguages.contains(languageCode)
            ? .rightToLeft
            : .leftToRight
    }

    public var calendar: Calendar {
        .hijri(
            system: calendarSystem,
            locale: locale,
            timeZone: timeZone,
            firstWeekday: firstWeekday
        )
    }

    public func contains(_ date: HijriDate) -> Bool {
        if let minimumDate, date < minimumDate { return false }
        if let maximumDate, date > maximumDate { return false }
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case localeIdentifier
        case timeZoneIdentifier
        case calendarSystem
        case dayAdjustment
        case monthStartOverrides
        case firstWeekday
        case minimumDate
        case maximumDate
        case showsAdjacentMonthDates
        case layoutDirection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        calendarSystem = try container.decodeIfPresent(
            HijriCalendarSystem.self,
            forKey: .calendarSystem
        ) ?? .ummAlQura
        dayAdjustment = min(max(
            try container.decodeIfPresent(Int.self, forKey: .dayAdjustment) ?? 0,
            -2
        ), 2)
        monthStartOverrides = try container.decodeIfPresent(
            [HijriMonthStartOverride].self,
            forKey: .monthStartOverrides
        ) ?? []
        firstWeekday = min(max(try container.decode(Int.self, forKey: .firstWeekday), 1), 7)
        minimumDate = try container.decodeIfPresent(HijriDate.self, forKey: .minimumDate)
        maximumDate = try container.decodeIfPresent(HijriDate.self, forKey: .maximumDate)
        showsAdjacentMonthDates = try container.decode(Bool.self, forKey: .showsAdjacentMonthDates)
        layoutDirection = try container.decode(HijriLayoutDirection.self, forKey: .layoutDirection)

        if let minimumDate, let maximumDate, minimumDate > maximumDate {
            throw DecodingError.dataCorruptedError(
                forKey: .maximumDate,
                in: container,
                debugDescription: "minimumDate must not be later than maximumDate"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(localeIdentifier, forKey: .localeIdentifier)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
        try container.encode(calendarSystem, forKey: .calendarSystem)
        try container.encode(dayAdjustment, forKey: .dayAdjustment)
        try container.encode(monthStartOverrides, forKey: .monthStartOverrides)
        try container.encode(firstWeekday, forKey: .firstWeekday)
        try container.encodeIfPresent(minimumDate, forKey: .minimumDate)
        try container.encodeIfPresent(maximumDate, forKey: .maximumDate)
        try container.encode(showsAdjacentMonthDates, forKey: .showsAdjacentMonthDates)
        try container.encode(layoutDirection, forKey: .layoutDirection)
    }
}
