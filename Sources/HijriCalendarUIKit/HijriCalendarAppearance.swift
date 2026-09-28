#if canImport(UIKit)
import UIKit

/// Visual tokens used by ``HijriCalendarView``.
public struct HijriCalendarAppearance {
    public var backgroundColor: UIColor
    public var monthTitleColor: UIColor
    public var weekdayTextColor: UIColor
    public var dayTextColor: UIColor
    public var adjacentMonthTextColor: UIColor
    public var disabledTextColor: UIColor
    public var selectionColor: UIColor
    public var selectionTextColor: UIColor
    public var todayColor: UIColor
    public var eventColor: UIColor
    public var monthTitleFont: UIFont
    public var weekdayFont: UIFont
    public var dayFont: UIFont
    public var dayCornerRadius: CGFloat

    public init(
        backgroundColor: UIColor = .systemBackground,
        monthTitleColor: UIColor = .label,
        weekdayTextColor: UIColor = .secondaryLabel,
        dayTextColor: UIColor = .label,
        adjacentMonthTextColor: UIColor = .tertiaryLabel,
        disabledTextColor: UIColor = .quaternaryLabel,
        selectionColor: UIColor = .systemTeal,
        selectionTextColor: UIColor = .white,
        todayColor: UIColor = .systemTeal,
        eventColor: UIColor = .systemOrange,
        monthTitleFont: UIFont = .preferredFont(forTextStyle: .headline),
        weekdayFont: UIFont = .preferredFont(forTextStyle: .caption1),
        dayFont: UIFont = .preferredFont(forTextStyle: .body),
        dayCornerRadius: CGFloat = 12
    ) {
        self.backgroundColor = backgroundColor
        self.monthTitleColor = monthTitleColor
        self.weekdayTextColor = weekdayTextColor
        self.dayTextColor = dayTextColor
        self.adjacentMonthTextColor = adjacentMonthTextColor
        self.disabledTextColor = disabledTextColor
        self.selectionColor = selectionColor
        self.selectionTextColor = selectionTextColor
        self.todayColor = todayColor
        self.eventColor = eventColor
        self.monthTitleFont = monthTitleFont
        self.weekdayFont = weekdayFont
        self.dayFont = dayFont
        self.dayCornerRadius = dayCornerRadius
    }

    public static let material = HijriCalendarAppearance()
}

/// Per-day overrides supplied by a calendar data source.
public struct HijriDayDecoration {
    public var text: String?
    public var backgroundColor: UIColor?
    public var textColor: UIColor?
    public var eventColor: UIColor?
    public var isEnabled: Bool
    public var accessibilityLabel: String?

    public init(
        text: String? = nil,
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        eventColor: UIColor? = nil,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.eventColor = eventColor
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
    }
}
#endif
