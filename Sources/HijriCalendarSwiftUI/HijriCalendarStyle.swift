#if canImport(UIKit)
import SwiftUI
import UIKit
import HijriCalendarUIKit

public struct HijriCalendarStyle {
    public var background: Color
    public var monthTitle: Color
    public var weekdayText: Color
    public var dayText: Color
    public var adjacentMonthText: Color
    public var disabledText: Color
    public var selection: Color
    public var selectionText: Color
    public var today: Color
    public var event: Color
    public var dayCornerRadius: CGFloat

    public init(
        background: Color = Color(uiColor: .systemBackground),
        monthTitle: Color = .primary,
        weekdayText: Color = .secondary,
        dayText: Color = .primary,
        adjacentMonthText: Color = Color(uiColor: .tertiaryLabel),
        disabledText: Color = Color(uiColor: .quaternaryLabel),
        selection: Color = .teal,
        selectionText: Color = .white,
        today: Color = .teal,
        event: Color = .orange,
        dayCornerRadius: CGFloat = 12
    ) {
        self.background = background
        self.monthTitle = monthTitle
        self.weekdayText = weekdayText
        self.dayText = dayText
        self.adjacentMonthText = adjacentMonthText
        self.disabledText = disabledText
        self.selection = selection
        self.selectionText = selectionText
        self.today = today
        self.event = event
        self.dayCornerRadius = dayCornerRadius
    }

    public static let material = HijriCalendarStyle()

    func makeAppearance() -> HijriCalendarAppearance {
        HijriCalendarAppearance(
            backgroundColor: UIColor(background),
            monthTitleColor: UIColor(monthTitle),
            weekdayTextColor: UIColor(weekdayText),
            dayTextColor: UIColor(dayText),
            adjacentMonthTextColor: UIColor(adjacentMonthText),
            disabledTextColor: UIColor(disabledText),
            selectionColor: UIColor(selection),
            selectionTextColor: UIColor(selectionText),
            todayColor: UIColor(today),
            eventColor: UIColor(event),
            dayCornerRadius: dayCornerRadius
        )
    }
}

public struct HijriCalendarDayDecoration {
    public var label: String?
    public var background: Color?
    public var text: Color?
    public var event: Color?
    public var isEnabled: Bool
    public var accessibilityLabel: String?

    public init(
        label: String? = nil,
        background: Color? = nil,
        text: Color? = nil,
        event: Color? = nil,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil
    ) {
        self.label = label
        self.background = background
        self.text = text
        self.event = event
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
    }

    func makeUIKitDecoration() -> HijriDayDecoration {
        HijriDayDecoration(
            text: label,
            backgroundColor: background.map(UIColor.init),
            textColor: text.map(UIColor.init),
            eventColor: event.map(UIColor.init),
            isEnabled: isEnabled,
            accessibilityLabel: accessibilityLabel
        )
    }
}
#endif
