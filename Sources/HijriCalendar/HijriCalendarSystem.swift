import Foundation

/// The Foundation-backed calculation system used to interpret Hijri components.
public enum HijriCalendarSystem: String, CaseIterable, Codable, Sendable {
    /// The astronomy-based Umm al-Qura calendar used in Saudi Arabia.
    case ummAlQura

    /// Foundation's Islamic calendar implementation.
    case islamic

    /// The arithmetic Islamic civil calendar.
    case civil

    /// The tabular Islamic calendar.
    case tabular

    public var foundationIdentifier: Calendar.Identifier {
        switch self {
        case .ummAlQura: return .islamicUmmAlQura
        case .islamic: return .islamic
        case .civil: return .islamicCivil
        case .tabular: return .islamicTabular
        }
    }
}

public extension Calendar {
    /// Creates a configured Foundation calendar for the selected Hijri system.
    static func hijri(
        system: HijriCalendarSystem = .ummAlQura,
        locale: Locale = Locale(identifier: "ar_SA"),
        timeZone: TimeZone = .current,
        firstWeekday: Int = 1
    ) -> Calendar {
        var calendar = Calendar(identifier: system.foundationIdentifier)
        calendar.locale = locale
        calendar.timeZone = timeZone
        calendar.firstWeekday = min(max(firstWeekday, 1), 7)
        return calendar
    }

    /// A compatibility convenience for Apple's Umm al-Qura implementation.
    static func hijriUmmAlQura(
        locale: Locale = Locale(identifier: "ar_SA"),
        timeZone: TimeZone = .current,
        firstWeekday: Int = 1
    ) -> Calendar {
        .hijri(
            system: .ummAlQura,
            locale: locale,
            timeZone: timeZone,
            firstWeekday: firstWeekday
        )
    }
}
