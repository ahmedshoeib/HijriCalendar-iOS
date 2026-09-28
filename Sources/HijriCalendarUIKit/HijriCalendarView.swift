#if canImport(UIKit)
import HijriCalendar
import UIKit

@MainActor
public protocol HijriCalendarViewDelegate: AnyObject {
    func calendarView(
        _ calendarView: HijriCalendarView,
        didChangeSelection selection: HijriCalendarSelection
    )

    func calendarView(
        _ calendarView: HijriCalendarView,
        didDisplay month: HijriMonth
    )

    func calendarView(_ calendarView: HijriCalendarView, didTap date: HijriDate)
}

public extension HijriCalendarViewDelegate {
    func calendarView(
        _ calendarView: HijriCalendarView,
        didChangeSelection selection: HijriCalendarSelection
    ) {}

    func calendarView(
        _ calendarView: HijriCalendarView,
        didDisplay month: HijriMonth
    ) {}

    func calendarView(_ calendarView: HijriCalendarView, didTap date: HijriDate) {}
}

@MainActor
public protocol HijriCalendarViewDataSource: AnyObject {
    func calendarView(
        _ calendarView: HijriCalendarView,
        decorationFor date: HijriDate
    ) -> HijriDayDecoration?
}

public extension HijriCalendarViewDataSource {
    func calendarView(
        _ calendarView: HijriCalendarView,
        decorationFor date: HijriDate
    ) -> HijriDayDecoration? { nil }
}

/// A reusable, fully programmatic UIKit Hijri month calendar.
@MainActor
public final class HijriCalendarView: UIView {
    public weak var delegate: HijriCalendarViewDelegate?
    public weak var dataSource: HijriCalendarViewDataSource?

    public var configuration = HijriCalendarConfiguration() {
        didSet { rebuildCalendar() }
    }

    public var selectionMode: HijriSelectionMode = .single {
        didSet {
            selection = .empty(for: selectionMode)
        }
    }

    public var selection: HijriCalendarSelection = .single(nil) {
        didSet {
            collectionView.reloadData()
            if oldValue != selection {
                delegate?.calendarView(self, didChangeSelection: selection)
            }
        }
    }

    public var displayedMonth: HijriMonth = HijriMonth(foundationDate: Date()) {
        didSet {
            guard oldValue != displayedMonth else { return }
            reloadMonth()
            delegate?.calendarView(self, didDisplay: displayedMonth)
        }
    }

    public var appearance: HijriCalendarAppearance = .material {
        didSet { applyAppearance() }
    }

    public var showsNavigationButtons = true {
        didSet {
            previousButton.isHidden = !showsNavigationButtons
            nextButton.isHidden = !showsNavigationButtons
        }
    }

    /// Overrides the localized month and year shown in the header.
    public var monthTitleFormatter: ((HijriMonth) -> String)? {
        didSet { reloadMonth() }
    }

    /// Overrides the numeric label rendered for every day.
    public var dayFormatter: ((HijriDate) -> String)? {
        didSet { collectionView.reloadData() }
    }

    /// The minimum number of digits in localized day labels. Custom `dayFormatter` output takes precedence.
    public var minimumDayLabelDigits = 1 {
        didSet {
            guard oldValue != minimumDayLabelDigits else { return }
            collectionView.reloadData()
        }
    }

    /// Seven symbols beginning with the configured first weekday.
    public var customWeekdaySymbols: [String]? {
        didSet {
            precondition(
                customWeekdaySymbols == nil || customWeekdaySymbols?.count == 7,
                "customWeekdaySymbols must contain exactly seven values"
            )
            rebuildWeekdayLabels()
        }
    }

    private var engine = HijriCalendarEngine()
    private var grid = HijriMonthGrid(month: HijriMonth(foundationDate: Date()), days: [])
    private let monthLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let weekdayStack = UIStackView()
    private let rootStack = UIStackView()
    private let collectionView: UICollectionView

    public override init(frame: CGRect) {
        let layout = HijriCalendarFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        configureView()
    }

    public required init?(coder: NSCoder) {
        let layout = HijriCalendarFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        configureView()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 350, height: 382)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    /// Moves to a month and optionally cross-fades the grid.
    public func display(_ month: HijriMonth, animated: Bool) {
        guard month != displayedMonth, canDisplay(month) else { return }
        if animated {
            UIView.transition(
                with: collectionView,
                duration: 0.22,
                options: [.transitionCrossDissolve, .allowAnimatedContent]
            ) {
                self.displayedMonth = month
            }
        } else {
            displayedMonth = month
        }
    }

    public func displayToday(animated: Bool = true) {
        display(
            HijriMonth(date: configuration.hijriDate(from: Date())),
            animated: animated
        )
    }

    public func select(_ date: HijriDate) {
        guard configuration.contains(date) else { return }
        selection = HijriSelectionReducer.selecting(date, in: selection, mode: selectionMode)
    }

    public func reloadData() {
        collectionView.reloadData()
    }

    private func configureView() {
        backgroundColor = appearance.backgroundColor

        rootStack.axis = .vertical
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.heightAnchor.constraint(equalToConstant: 52).isActive = true
        rootStack.addArrangedSubview(header)

        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.textAlignment = .center
        monthLabel.adjustsFontForContentSizeCategory = true
        header.addSubview(monthLabel)

        configureNavigationButton(previousButton, systemName: "chevron.backward", action: #selector(showPreviousMonth))
        configureNavigationButton(nextButton, systemName: "chevron.forward", action: #selector(showNextMonth))
        header.addSubview(previousButton)
        header.addSubview(nextButton)

        weekdayStack.axis = .horizontal
        weekdayStack.distribution = .fillEqually
        weekdayStack.translatesAutoresizingMaskIntoConstraints = false
        weekdayStack.heightAnchor.constraint(equalToConstant: 28).isActive = true
        rootStack.addArrangedSubview(weekdayStack)

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            HijriCalendarDayCell.self,
            forCellWithReuseIdentifier: HijriCalendarDayCell.reuseIdentifier
        )
        rootStack.addArrangedSubview(collectionView)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        collectionView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        collectionView.addGestureRecognizer(swipeRight)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            previousButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 8),
            previousButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 44),
            previousButton.heightAnchor.constraint(equalToConstant: 44),

            nextButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            nextButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),

            monthLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousButton.trailingAnchor, constant: 4),
            monthLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -4),
            monthLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        isAccessibilityElement = false
        rebuildCalendar()
        applyAppearance()
    }

    private func configureNavigationButton(_ button: UIButton, systemName: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func rebuildCalendar() {
        engine = HijriCalendarEngine(configuration: configuration)
        let semanticContent: UISemanticContentAttribute = configuration.resolvedLayoutDirection == .rightToLeft
            ? .forceRightToLeft
            : .forceLeftToRight
        semanticContentAttribute = semanticContent
        rootStack.semanticContentAttribute = semanticContent
        weekdayStack.semanticContentAttribute = semanticContent
        collectionView.semanticContentAttribute = semanticContent
        rebuildWeekdayLabels()
        displayedMonth = clampedMonth(displayedMonth)
        reloadMonth()
    }

    private func rebuildWeekdayLabels() {
        weekdayStack.arrangedSubviews.forEach {
            weekdayStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for symbol in customWeekdaySymbols ?? engine.weekdaySymbols() {
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.font = appearance.weekdayFont
            label.textColor = appearance.weekdayTextColor
            label.accessibilityLabel = symbol
            weekdayStack.addArrangedSubview(label)
        }
    }

    private func reloadMonth() {
        grid = engine.monthGrid(for: displayedMonth)
        monthLabel.text = monthTitleFormatter?(displayedMonth) ?? displayedMonth.title(
            locale: configuration.locale,
            calendar: configuration.calendar
        )
        previousButton.isEnabled = canDisplay(
            displayedMonth.advanced(by: -1, calendar: configuration.calendar)
        )
        nextButton.isEnabled = canDisplay(
            displayedMonth.advanced(by: 1, calendar: configuration.calendar)
        )
        collectionView.reloadData()
    }

    private func canDisplay(_ month: HijriMonth) -> Bool {
        if let minimumDate = configuration.minimumDate,
           month < HijriMonth(date: minimumDate) {
            return false
        }
        if let maximumDate = configuration.maximumDate,
           month > HijriMonth(date: maximumDate) {
            return false
        }
        return true
    }

    private func clampedMonth(_ month: HijriMonth) -> HijriMonth {
        if let minimumDate = configuration.minimumDate {
            let minimumMonth = HijriMonth(date: minimumDate)
            if month < minimumMonth { return minimumMonth }
        }
        if let maximumDate = configuration.maximumDate {
            let maximumMonth = HijriMonth(date: maximumDate)
            if month > maximumMonth { return maximumMonth }
        }
        return month
    }

    private func applyAppearance() {
        backgroundColor = appearance.backgroundColor
        monthLabel.font = appearance.monthTitleFont
        monthLabel.textColor = appearance.monthTitleColor
        previousButton.tintColor = appearance.selectionColor
        nextButton.tintColor = appearance.selectionColor
        rebuildWeekdayLabels()
        collectionView.reloadData()
    }

    @objc private func showPreviousMonth() {
        display(displayedMonth.advanced(by: -1, calendar: configuration.calendar), animated: true)
    }

    @objc private func showNextMonth() {
        display(displayedMonth.advanced(by: 1, calendar: configuration.calendar), animated: true)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let shouldAdvance = (gesture.direction == .left) != isRTL
        let offset = shouldAdvance ? 1 : -1
        display(displayedMonth.advanced(by: offset, calendar: configuration.calendar), animated: true)
    }

    private func decoration(for date: HijriDate) -> HijriDayDecoration? {
        dataSource?.calendarView(self, decorationFor: date)
    }

    private func accessibilityLabel(for day: HijriCalendarDay) -> String {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.calendar = configuration.calendar
        weekdayFormatter.locale = configuration.locale
        weekdayFormatter.timeZone = configuration.timeZone
        weekdayFormatter.setLocalizedDateFormatFromTemplate("EEEE")

        let hijriFormatter = DateFormatter()
        hijriFormatter.calendar = configuration.calendar
        hijriFormatter.locale = configuration.locale
        hijriFormatter.timeZone = configuration.timeZone
        hijriFormatter.setLocalizedDateFormatFromTemplate("d MMMM y")

        let weekday = weekdayFormatter.string(from: day.foundationDate)
        guard let componentDate = day.date.foundationDate(in: configuration.calendar) else {
            return weekday
        }
        return "\(weekday), \(hijriFormatter.string(from: componentDate))"
    }

}

extension HijriCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        grid.days.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HijriCalendarDayCell.reuseIdentifier,
                for: indexPath
            ) as? HijriCalendarDayCell
        else {
            return UICollectionViewCell()
        }
        let day = grid.days[indexPath.item]
        cell.apply(
            day: day,
            dayText: dayFormatter?(day.date) ?? engine.dayLabel(
                for: day.date,
                minimumIntegerDigits: minimumDayLabelDigits
            ),
            selection: selection,
            appearance: appearance,
            decoration: decoration(for: day.date),
            showsAdjacentMonthDates: configuration.showsAdjacentMonthDates,
            accessibilityLabel: accessibilityLabel(for: day)
        )
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: floor(collectionView.bounds.width / 7),
            height: floor(collectionView.bounds.height / 6)
        )
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let day = grid.days[indexPath.item]
        let dayDecoration = decoration(for: day.date)
        guard day.isWithinBounds, dayDecoration?.isEnabled ?? true else { return }
        guard day.monthPosition == .current || configuration.showsAdjacentMonthDates else { return }

        delegate?.calendarView(self, didTap: day.date)
        select(day.date)

        if day.monthPosition != .current {
            display(HijriMonth(date: day.date), animated: true)
        }
    }
}
#endif
