import UIKit
import HijriCalendar
import HijriCalendarUIKit

final class CalendarDemoViewController: UIViewController {
    private enum DemoLanguage: Int {
        case system
        case english
        case arabic

        var locale: Locale {
            switch self {
            case .system: return .current
            case .english: return Locale(identifier: "en_US")
            case .arabic: return Locale(identifier: "ar_SA")
            }
        }

        func text(_ english: String, _ arabic: String) -> String {
            locale.identifier.lowercased().hasPrefix("ar") ? arabic : english
        }
    }

    private let calendarView = HijriCalendarView()
    private let languageControl = UISegmentedControl(items: ["System", "English", "العربية"])
    private let selectionControl = UISegmentedControl(items: ["None", "Single", "Multiple", "Range"])
    private let calendarSystemControl = UISegmentedControl(items: ["Umm al-Qura", "Islamic", "Civil", "Tabular"])
    private let adjustmentControl = UISegmentedControl(items: ["-2", "-1", "0", "+1", "+2"])
    private let directionControl = UISegmentedControl(items: ["Auto", "LTR", "RTL"])
    private let weekdayControl = UISegmentedControl(items: ["Sun", "Sat", "Mon"])
    private let themeControl = UISegmentedControl(items: ["Teal", "Indigo"])
    private let adjacentSwitch = UISwitch()
    private let navigationSwitch = UISwitch()
    private let paddedLabelsSwitch = UISwitch()
    private let officialOverrideSwitch = UISwitch()
    private let selectionLabel = UILabel()
    private let tappedLabel = UILabel()
    private let languageTitleLabel = UILabel()
    private let selectionTitleLabel = UILabel()
    private let calendarSystemTitleLabel = UILabel()
    private let adjustmentTitleLabel = UILabel()
    private let directionTitleLabel = UILabel()
    private let weekdayTitleLabel = UILabel()
    private let themeTitleLabel = UILabel()
    private let adjacentTitleLabel = UILabel()
    private let navigationTitleLabel = UILabel()
    private let paddedLabelsTitleLabel = UILabel()
    private let officialOverrideTitleLabel = UILabel()
    private lazy var todayButton = actionButton(title: "Today", action: #selector(showToday))
    private lazy var nextMonthButton = actionButton(title: "Next month", action: #selector(showNextMonth))
    private var language: DemoLanguage = .english

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        configureControls()
        configureCalendar()
        buildLayout()
        applyConfiguration()
    }

    private func configureControls() {
        languageControl.selectedSegmentIndex = CommandLine.arguments.contains("-ArabicDemo")
            ? DemoLanguage.arabic.rawValue
            : DemoLanguage.english.rawValue
        selectionControl.selectedSegmentIndex = 3
        calendarSystemControl.selectedSegmentIndex = 0
        adjustmentControl.selectedSegmentIndex = 2
        directionControl.selectedSegmentIndex = 0
        weekdayControl.selectedSegmentIndex = 1
        themeControl.selectedSegmentIndex = 0
        adjacentSwitch.isOn = true
        navigationSwitch.isOn = true

        [languageControl, selectionControl, calendarSystemControl, adjustmentControl, directionControl, weekdayControl, themeControl].forEach {
            $0.addTarget(self, action: #selector(controlValueChanged(_:)), for: .valueChanged)
        }
        [adjacentSwitch, navigationSwitch, paddedLabelsSwitch, officialOverrideSwitch].forEach {
            $0.addTarget(self, action: #selector(controlValueChanged(_:)), for: .valueChanged)
        }

        selectionLabel.numberOfLines = 0
        selectionLabel.font = .preferredFont(forTextStyle: .footnote)
        tappedLabel.numberOfLines = 0
        tappedLabel.font = .preferredFont(forTextStyle: .footnote)
        tappedLabel.textColor = .secondaryLabel
    }

    private func configureCalendar() {
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.selectionMode = .range
        calendarView.selection = .range(nil)
    }

    private func buildLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(section(label: languageTitleLabel, control: languageControl))
        contentStack.addArrangedSubview(section(label: selectionTitleLabel, control: selectionControl))
        contentStack.addArrangedSubview(section(label: calendarSystemTitleLabel, control: calendarSystemControl))
        contentStack.addArrangedSubview(compactSection(label: adjustmentTitleLabel, control: adjustmentControl))
        contentStack.addArrangedSubview(switchRow(label: officialOverrideTitleLabel, control: officialOverrideSwitch))

        let optionRow = UIStackView(arrangedSubviews: [
            compactSection(label: directionTitleLabel, control: directionControl),
            compactSection(label: weekdayTitleLabel, control: weekdayControl),
            compactSection(label: themeTitleLabel, control: themeControl)
        ])
        optionRow.axis = .vertical
        optionRow.spacing = 10
        contentStack.addArrangedSubview(optionRow)

        contentStack.addArrangedSubview(switchRow(label: adjacentTitleLabel, control: adjacentSwitch))
        contentStack.addArrangedSubview(switchRow(label: navigationTitleLabel, control: navigationSwitch))
        contentStack.addArrangedSubview(switchRow(label: paddedLabelsTitleLabel, control: paddedLabelsSwitch))

        contentStack.addArrangedSubview(calendarView)
        calendarView.heightAnchor.constraint(equalToConstant: 382).isActive = true

        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 10
        actionStack.addArrangedSubview(todayButton)
        actionStack.addArrangedSubview(nextMonthButton)
        contentStack.addArrangedSubview(actionStack)

        let statusStack = UIStackView(arrangedSubviews: [selectionLabel, tappedLabel])
        statusStack.axis = .vertical
        statusStack.spacing = 8
        statusStack.isLayoutMarginsRelativeArrangement = true
        statusStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        statusStack.backgroundColor = .secondarySystemGroupedBackground
        statusStack.layer.cornerRadius = 8
        contentStack.addArrangedSubview(statusStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func applyConfiguration() {
        language = DemoLanguage(rawValue: languageControl.selectedSegmentIndex) ?? .english
        let direction: HijriLayoutDirection = [.automatic, .leftToRight, .rightToLeft][directionControl.selectedSegmentIndex]
        let calendarSystem = HijriCalendarSystem.allCases[calendarSystemControl.selectedSegmentIndex]
        let dayAdjustment = [-2, -1, 0, 1, 2][adjustmentControl.selectedSegmentIndex]
        let firstWeekday = [1, 7, 2][weekdayControl.selectedSegmentIndex]
        var configuration = HijriCalendarConfiguration(
            locale: language.locale,
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            calendarSystem: calendarSystem,
            dayAdjustment: dayAdjustment,
            firstWeekday: firstWeekday,
            minimumDate: HijriDate(year: 1445, month: 1, day: 1),
            maximumDate: HijriDate(year: 1450, month: 12, day: 30),
            showsAdjacentMonthDates: adjacentSwitch.isOn,
            layoutDirection: direction
        )
        if officialOverrideSwitch.isOn,
           let override = demoMonthStartOverride(configuration: configuration) {
            configuration.monthStartOverrides = [override]
        }
        calendarView.configuration = configuration
        calendarView.showsNavigationButtons = navigationSwitch.isOn
        calendarView.minimumDayLabelDigits = paddedLabelsSwitch.isOn ? 2 : 1

        let selectionColor: UIColor = themeControl.selectedSegmentIndex == 0 ? .systemTeal : .systemIndigo
        calendarView.appearance = HijriCalendarAppearance(
            backgroundColor: .secondarySystemGroupedBackground,
            selectionColor: selectionColor,
            todayColor: selectionColor,
            eventColor: themeControl.selectedSegmentIndex == 0 ? .systemOrange : .systemPink,
            dayCornerRadius: 11
        )

        let mode = HijriSelectionMode.allCases[selectionControl.selectedSegmentIndex]
        if calendarView.selectionMode != mode {
            calendarView.selectionMode = mode
        }

        applyLocalizedText()
        let isRTL = language.locale.identifier.lowercased().hasPrefix("ar")
        applyInterfaceDirection(
            isRTL ? .forceRightToLeft : .forceLeftToRight,
            to: view
        )
        title = language.text("UIKit Demo", "مثال UIKit")
        updateSelectionLabel(calendarView.selection)
        calendarView.reloadData()
    }

    @objc private func controlValueChanged(_ sender: UIControl) {
        applyConfiguration()
        if sender === calendarSystemControl
            || sender === adjustmentControl
            || sender === officialOverrideSwitch {
            calendarView.selection = .empty(for: calendarView.selectionMode)
            calendarView.displayToday(animated: false)
        }
    }

    @objc private func showToday() {
        calendarView.displayToday()
    }

    @objc private func showNextMonth() {
        calendarView.display(
            calendarView.displayedMonth.advanced(
                by: 1,
                calendar: calendarView.configuration.calendar
            ),
            animated: true
        )
    }

    private func updateSelectionLabel(_ selection: HijriCalendarSelection) {
        switch selection {
        case .none:
            selectionLabel.text = language.text("Read-only mode", "وضع العرض فقط")
        case .single(let date):
            selectionLabel.text = date.map {
                language.text(
                    "Selected: \(dateLabel(for: $0))",
                    "المحدد: \(dateLabel(for: $0))"
                )
            } ?? language.text("No selected date", "لا يوجد تاريخ محدد")
        case .multiple(let dates):
            let count = numberLabel(for: dates.count)
            selectionLabel.text = language.text(
                "Selected dates: \(count)",
                "التواريخ المحددة: \(count)"
            )
        case .range(let range):
            guard let range else {
                selectionLabel.text = language.text("Choose a range", "اختر فترة")
                return
            }
            let start = dateLabel(for: range.lowerBound)
            guard let end = range.upperBound else {
                selectionLabel.text = language.text(
                    "Range start: \(start)",
                    "بداية الفترة: \(start)"
                )
                return
            }
            selectionLabel.text = language.text(
                "Selected range: \(start) to \(dateLabel(for: end))",
                "الفترة المحددة: من \(start) إلى \(dateLabel(for: end))"
            )
        }
    }

    private func dateLabel(for date: HijriDate) -> String {
        HijriCalendarEngine(configuration: calendarView.configuration).dateLabel(for: date)
    }

    private func numberLabel(for value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func applyLocalizedText() {
        languageTitleLabel.text = "Language / اللغة"
        selectionTitleLabel.text = language.text("Selection mode", "وضع التحديد")
        calendarSystemTitleLabel.text = language.text("Calendar system", "نظام التقويم")
        adjustmentTitleLabel.text = language.text("Day adjustment", "تعديل اليوم")
        directionTitleLabel.text = language.text("Direction", "الاتجاه")
        weekdayTitleLabel.text = language.text("First weekday", "بداية الأسبوع")
        themeTitleLabel.text = language.text("Theme", "المظهر")
        adjacentTitleLabel.text = language.text("Show adjacent dates", "إظهار أيام الشهر المجاور")
        navigationTitleLabel.text = language.text("Show navigation buttons", "إظهار أزرار التنقل")
        paddedLabelsTitleLabel.text = language.text("Use padded day labels", "عرض اليوم برقمين")
        officialOverrideTitleLabel.text = language.text(
            "Official start demo (+1 day)",
            "مثال بداية رسمية (+١ يوم)"
        )

        let selectionTitles = language == .arabic
            ? ["بدون", "فردي", "متعدد", "فترة"]
            : ["None", "Single", "Multiple", "Range"]
        for (index, title) in selectionTitles.enumerated() {
            selectionControl.setTitle(title, forSegmentAt: index)
        }
        for (index, system) in HijriCalendarSystem.allCases.enumerated() {
            calendarSystemControl.setTitle(calendarSystemName(system), forSegmentAt: index)
        }
        directionControl.setTitle(language.text("Auto", "تلقائي"), forSegmentAt: 0)
        weekdayControl.setTitle(language.text("Sun", "الأحد"), forSegmentAt: 0)
        weekdayControl.setTitle(language.text("Sat", "السبت"), forSegmentAt: 1)
        weekdayControl.setTitle(language.text("Mon", "الاثنين"), forSegmentAt: 2)
        themeControl.setTitle(language.text("Teal", "فيروزي"), forSegmentAt: 0)
        themeControl.setTitle(language.text("Indigo", "نيلي"), forSegmentAt: 1)
        todayButton.setTitle(language.text("Today", "اليوم"), for: .normal)
        nextMonthButton.setTitle(language.text("Next month", "الشهر التالي"), for: .normal)
    }

    private func calendarSystemName(_ system: HijriCalendarSystem) -> String {
        switch system {
        case .ummAlQura: return language.text("Umm al-Qura", "أم القرى")
        case .islamic: return language.text("Islamic", "إسلامي")
        case .civil: return language.text("Civil", "مدني")
        case .tabular: return language.text("Tabular", "جدولي")
        }
    }

    private func demoMonthStartOverride(
        configuration: HijriCalendarConfiguration
    ) -> HijriMonthStartOverride? {
        var calculationOnlyConfiguration = configuration
        calculationOnlyConfiguration.dayAdjustment = 0
        calculationOnlyConfiguration.monthStartOverrides = []
        let month = HijriMonth(
            date: calculationOnlyConfiguration.hijriDate(from: Date())
        )
        let firstDay = HijriDate(year: month.year, month: month.month, day: 1)
        guard let calculatedStart = calculationOnlyConfiguration.foundationDate(from: firstDay) else {
            return nil
        }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calculationOnlyConfiguration.timeZone
        guard let officialStart = gregorian.date(
            byAdding: .day,
            value: 1,
            to: calculatedStart
        ) else {
            return nil
        }
        return HijriMonthStartOverride(
            month: month,
            gregorianStartDate: officialStart
        )
    }

    private func applyInterfaceDirection(_ direction: UISemanticContentAttribute, to root: UIView) {
        guard root !== calendarView else { return }
        root.semanticContentAttribute = direction
        root.subviews.forEach { applyInterfaceDirection(direction, to: $0) }
    }

    private func section(label: UILabel, control: UIView) -> UIView {
        label.font = .preferredFont(forTextStyle: .headline)
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func compactSection(label: UILabel, control: UIView) -> UIView {
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func switchRow(label: UILabel, control: UISwitch) -> UIView {
        label.adjustsFontForContentSizeCategory = true
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }

    private func actionButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

extension CalendarDemoViewController: HijriCalendarViewDelegate {
    func calendarView(
        _ calendarView: HijriCalendarView,
        didChangeSelection selection: HijriCalendarSelection
    ) {
        updateSelectionLabel(selection)
    }

    func calendarView(_ calendarView: HijriCalendarView, didTap date: HijriDate) {
        let date = dateLabel(for: date)
        tappedLabel.text = language.text("Last tap: \(date)", "آخر اختيار: \(date)")
    }
}

extension CalendarDemoViewController: HijriCalendarViewDataSource {
    func calendarView(
        _ calendarView: HijriCalendarView,
        decorationFor date: HijriDate
    ) -> HijriDayDecoration? {
        if date.day == 15 {
            return HijriDayDecoration(
                textColor: .secondaryLabel,
                isEnabled: false,
                accessibilityLabel: language.text("Unavailable date", "تاريخ غير متاح")
            )
        }
        if [1, 10, 18, 27].contains(date.day) {
            return HijriDayDecoration(
                eventColor: themeControl.selectedSegmentIndex == 0 ? .systemOrange : .systemPink,
                accessibilityLabel: language.text("Event on day \(date.day)", "حدث في اليوم \(date.day)")
            )
        }
        return nil
    }
}
