import Foundation

public enum HijriSelectionMode: String, CaseIterable, Codable, Sendable {
    case none
    case single
    case multiple
    case range
}

public struct HijriDateRange: Hashable, Codable, Sendable {
    public let lowerBound: HijriDate
    public let upperBound: HijriDate?

    public init(from first: HijriDate, to second: HijriDate? = nil) {
        if let second, second < first {
            self.lowerBound = second
            self.upperBound = first
        } else {
            self.lowerBound = first
            self.upperBound = second
        }
    }

    public func contains(_ date: HijriDate) -> Bool {
        guard let upperBound else { return date == lowerBound }
        return date >= lowerBound && date <= upperBound
    }
}

public enum HijriCalendarSelection: Hashable, Codable, Sendable {
    case none
    case single(HijriDate?)
    case multiple(Set<HijriDate>)
    case range(HijriDateRange?)

    public func contains(_ date: HijriDate) -> Bool {
        switch self {
        case .none:
            return false
        case .single(let selected):
            return selected == date
        case .multiple(let selected):
            return selected.contains(date)
        case .range(let range):
            return range?.contains(date) ?? false
        }
    }

    public static func empty(for mode: HijriSelectionMode) -> Self {
        switch mode {
        case .none: return .none
        case .single: return .single(nil)
        case .multiple: return .multiple([])
        case .range: return .range(nil)
        }
    }
}

public enum HijriSelectionReducer {
    public static func selecting(
        _ date: HijriDate,
        in selection: HijriCalendarSelection,
        mode: HijriSelectionMode
    ) -> HijriCalendarSelection {
        switch mode {
        case .none:
            return .none
        case .single:
            if case .single(let selected) = selection, selected == date {
                return .single(nil)
            }
            return .single(date)
        case .multiple:
            var values: Set<HijriDate>
            if case .multiple(let selected) = selection {
                values = selected
            } else {
                values = []
            }
            if values.contains(date) {
                values.remove(date)
            } else {
                values.insert(date)
            }
            return .multiple(values)
        case .range:
            guard case .range(let range) = selection else {
                return .range(HijriDateRange(from: date))
            }
            guard let range, range.upperBound == nil else {
                return .range(HijriDateRange(from: date))
            }
            return .range(HijriDateRange(from: range.lowerBound, to: date))
        }
    }
}
