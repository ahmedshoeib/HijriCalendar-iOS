#if canImport(UIKit)
import HijriCalendar
import UIKit

final class HijriCalendarDayCell: UICollectionViewCell {
    static let reuseIdentifier = "HijriCalendarDayCell"

    private let selectionView = UIView()
    private let dayLabel = UILabel()
    private let eventView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionView.backgroundColor = .clear
        selectionView.layer.borderWidth = 0
        eventView.isHidden = true
        accessibilityTraits = [.button]
    }

    func apply(
        day: HijriCalendarDay,
        dayText: String,
        selection: HijriCalendarSelection,
        appearance: HijriCalendarAppearance,
        decoration: HijriDayDecoration?,
        showsAdjacentMonthDates: Bool,
        accessibilityLabel: String
    ) {
        let isAdjacent = day.monthPosition != .current
        let isVisible = !isAdjacent || showsAdjacentMonthDates
        let isEnabled = isVisible && day.isWithinBounds && (decoration?.isEnabled ?? true)
        let isSelected = selection.contains(day.date)

        dayLabel.text = isVisible ? decoration?.text ?? dayText : nil
        dayLabel.font = appearance.dayFont
        dayLabel.adjustsFontForContentSizeCategory = true
        dayLabel.textColor = resolvedTextColor(
            day: day,
            isEnabled: isEnabled,
            isSelected: isSelected,
            appearance: appearance,
            decoration: decoration
        )

        selectionView.layer.cornerRadius = min(
            appearance.dayCornerRadius,
            min(bounds.width, bounds.height) / 2
        )
        selectionView.backgroundColor = isSelected
            ? appearance.selectionColor
            : decoration?.backgroundColor ?? .clear
        selectionView.layer.borderWidth = day.isToday && !isSelected ? 1.5 : 0
        selectionView.layer.borderColor = appearance.todayColor.cgColor

        eventView.backgroundColor = decoration?.eventColor ?? appearance.eventColor
        eventView.isHidden = decoration?.eventColor == nil

        isUserInteractionEnabled = isEnabled
        alpha = isEnabled ? 1 : 0.48
        isAccessibilityElement = isVisible
        self.accessibilityLabel = decoration?.accessibilityLabel ?? accessibilityLabel
        if !isEnabled {
            accessibilityTraits = [.button, .notEnabled]
        } else {
            accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    private func resolvedTextColor(
        day: HijriCalendarDay,
        isEnabled: Bool,
        isSelected: Bool,
        appearance: HijriCalendarAppearance,
        decoration: HijriDayDecoration?
    ) -> UIColor {
        if isSelected { return appearance.selectionTextColor }
        if !isEnabled { return appearance.disabledTextColor }
        if let color = decoration?.textColor { return color }
        if day.monthPosition != .current { return appearance.adjacentMonthTextColor }
        return appearance.dayTextColor
    }

    private func configureView() {
        isAccessibilityElement = true

        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.isUserInteractionEnabled = false
        contentView.addSubview(selectionView)

        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.textAlignment = .center
        dayLabel.adjustsFontForContentSizeCategory = true
        selectionView.addSubview(dayLabel)

        eventView.translatesAutoresizingMaskIntoConstraints = false
        eventView.layer.cornerRadius = 2
        eventView.isHidden = true
        selectionView.addSubview(eventView)

        NSLayoutConstraint.activate([
            selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionView.widthAnchor.constraint(lessThanOrEqualToConstant: 40),
            selectionView.heightAnchor.constraint(equalTo: selectionView.widthAnchor),
            selectionView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.78),
            selectionView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor, multiplier: 0.82),

            dayLabel.centerXAnchor.constraint(equalTo: selectionView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: selectionView.centerYAnchor, constant: -1),

            eventView.centerXAnchor.constraint(equalTo: selectionView.centerXAnchor),
            eventView.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor, constant: -3),
            eventView.widthAnchor.constraint(equalToConstant: 4),
            eventView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
}
#endif
