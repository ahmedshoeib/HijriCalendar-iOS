import SwiftUI
import HijriCalendar
import HijriCalendarSwiftUI

struct ContentView: View {
    @State private var selectionMode: HijriSelectionMode = .range
    @State private var selection: HijriCalendarSelection = .range(nil)
    @State private var displayedMonth = HijriMonth(foundationDate: Date())
    @State private var language: DemoLanguage = CommandLine.arguments.contains("-ArabicDemo")
        ? .arabic
        : .english
    @State private var calendarSystem: HijriCalendarSystem = .ummAlQura
    @State private var dayAdjustment = 0
    @State private var usesOfficialStartOverride = false
    @State private var direction: HijriLayoutDirection = .automatic
    @State private var theme: DemoTheme = .teal
    @State private var firstWeekday = 7
    @State private var showsAdjacentDates = true
    @State private var showsNavigation = true
    @State private var usesPaddedDayLabels = false
    @State private var lastTappedDate: HijriDate?

    private var baseConfiguration: HijriCalendarConfiguration {
        HijriCalendarConfiguration(
            locale: language.locale,
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            calendarSystem: calendarSystem,
            dayAdjustment: dayAdjustment,
            firstWeekday: firstWeekday,
            minimumDate: HijriDate(year: 1445, month: 1, day: 1),
            maximumDate: HijriDate(year: 1450, month: 12, day: 30),
            showsAdjacentMonthDates: showsAdjacentDates,
            layoutDirection: direction
        )
    }

    private var configuration: HijriCalendarConfiguration {
        var configuration = baseConfiguration
        if usesOfficialStartOverride, let override = demoMonthStartOverride {
            configuration.monthStartOverrides = [override]
        }
        return configuration
    }

    private var demoMonthStartOverride: HijriMonthStartOverride? {
        var calculationOnlyConfiguration = baseConfiguration
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
        guard let officialStart = gregorian.date(byAdding: .day, value: 1, to: calculatedStart) else {
            return nil
        }
        return HijriMonthStartOverride(
            month: month,
            gregorianStartDate: officialStart
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    optionPanel

                    HijriCalendarSwiftUI.HijriCalendar(
                        selection: $selection,
                        displayedMonth: $displayedMonth,
                        selectionMode: selectionMode,
                        configuration: configuration
                    )
                    .calendarLocale(language.locale)
                    .calendarTimeZone(TimeZone(identifier: "Asia/Riyadh")!)
                    .calendarSystem(calendarSystem)
                    .calendarLayoutDirection(direction)
                    .calendarStyle(HijriCalendarStyle(
                        background: Color(uiColor: .secondarySystemBackground),
                        selection: theme.selection,
                        today: theme.today,
                        event: theme.event,
                        dayCornerRadius: 11
                    ))
                    .showsNavigationButtons(showsNavigation)
                    .monthTitle { month in
                        month.title(locale: language.locale, calendar: configuration.calendar)
                    }
                    .minimumDayLabelDigits(usesPaddedDayLabels ? 2 : 1)
                    .dayDecoration { decoration(for: $0) }
                    .onDateTap { lastTappedDate = $0 }
                    .frame(height: 382)

                    statusPanel
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(language.text("SwiftUI Demo", "مثال SwiftUI"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("Today", "اليوم")) {
                        displayedMonth = HijriMonth(
                            date: configuration.hijriDate(from: Date())
                        )
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .environment(\.locale, language.locale)
        .environment(\.layoutDirection, language.interfaceDirection)
        .onChange(of: calendarSystem) { _ in resetDateRules() }
        .onChange(of: dayAdjustment) { _ in resetDateRules() }
        .onChange(of: usesOfficialStartOverride) { _ in resetDateRules() }
    }

    private var optionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(language.text("Language", "اللغة"), selection: $language) {
                ForEach(DemoLanguage.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Picker(language.text("Selection", "التحديد"), selection: selectionModeBinding) {
                ForEach(HijriSelectionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            optionMenu(
                title: language.text("Calendar system", "نظام التقويم"),
                selection: $calendarSystem,
                values: HijriCalendarSystem.allCases,
                label: { calendarSystemName($0) }
            )

            optionMenu(
                title: language.text("Day adjustment", "تعديل اليوم"),
                selection: $dayAdjustment,
                values: Array(-2...2),
                label: { signedAdjustment($0) }
            )

            Toggle(
                language.text("Official start demo (+1 day)", "مثال بداية رسمية (+١ يوم)"),
                isOn: $usesOfficialStartOverride
            )

            HStack {
                optionMenu(
                    title: language.text("Direction", "الاتجاه"),
                    selection: $direction,
                    values: HijriLayoutDirection.allCases,
                    label: { $0.rawValue }
                )
                optionMenu(
                    title: language.text("First weekday", "بداية الأسبوع"),
                    selection: $firstWeekday,
                    values: [1, 7, 2],
                    label: { weekdayName($0) }
                )
                optionMenu(
                    title: language.text("Theme", "المظهر"),
                    selection: $theme,
                    values: DemoTheme.allCases,
                    label: { $0.title }
                )
            }

            Toggle(language.text("Show adjacent dates", "إظهار أيام الشهر المجاور"), isOn: $showsAdjacentDates)
            Toggle(language.text("Show navigation buttons", "إظهار أزرار التنقل"), isOn: $showsNavigation)
            Toggle(language.text("Use padded day labels", "عرض اليوم برقمين"), isOn: $usesPaddedDayLabels)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(selectionSummary, systemImage: "calendar.badge.checkmark")
            Label(
                lastTappedDate.map {
                    language.text(
                        "Last tap: \(dateLabel(for: $0))",
                        "آخر اختيار: \(dateLabel(for: $0))"
                    )
                }
                    ?? language.text("Tap a date", "اختر تاريخاً"),
                systemImage: "hand.tap"
            )
            Label(
                language.text(
                    "Day 15 is disabled; event days have dots.",
                    "اليوم ١٥ معطل، وأيام الأحداث عليها نقاط."
                ),
                systemImage: "info.circle"
            )
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var selectionModeBinding: Binding<HijriSelectionMode> {
        Binding(
            get: { selectionMode },
            set: { mode in
                selectionMode = mode
                selection = .empty(for: mode)
            }
        )
    }

    private func decoration(for date: HijriDate) -> HijriCalendarDayDecoration? {
        if date.day == 15 {
            return HijriCalendarDayDecoration(
                text: .secondary,
                isEnabled: false,
                accessibilityLabel: language.text("Unavailable date", "تاريخ غير متاح")
            )
        }
        if [1, 10, 18, 27].contains(date.day) {
            return HijriCalendarDayDecoration(
                event: theme.event,
                accessibilityLabel: language.text("Event on day \(date.day)", "حدث في اليوم \(date.day)")
            )
        }
        return nil
    }

    private var selectionSummary: String {
        switch selection {
        case .none:
            return language.text("Read-only mode", "وضع العرض فقط")
        case .single(let date):
            return date.map {
                language.text(
                    "Selected: \(dateLabel(for: $0))",
                    "المحدد: \(dateLabel(for: $0))"
                )
            }
                ?? language.text("No selected date", "لا يوجد تاريخ محدد")
        case .multiple(let dates):
            let count = numberLabel(for: dates.count)
            return language.text("Selected dates: \(count)", "التواريخ المحددة: \(count)")
        case .range(let range):
            guard let range else { return language.text("Choose a range", "اختر فترة") }
            guard let end = range.upperBound else {
                let start = dateLabel(for: range.lowerBound)
                return language.text("Range start: \(start)", "بداية الفترة: \(start)")
            }
            let start = dateLabel(for: range.lowerBound)
            let finish = dateLabel(for: end)
            return language.text(
                "Selected range: \(start) to \(finish)",
                "الفترة المحددة: من \(start) إلى \(finish)"
            )
        }
    }

    private func dateLabel(for date: HijriDate) -> String {
        HijriCalendarEngine(configuration: configuration).dateLabel(for: date)
    }

    private func numberLabel(for value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func weekdayName(_ value: Int) -> String {
        switch value {
        case 1: return language.text("Sun", "الأحد")
        case 2: return language.text("Mon", "الاثنين")
        default: return language.text("Sat", "السبت")
        }
    }

    private func calendarSystemName(_ system: HijriCalendarSystem) -> String {
        switch system {
        case .ummAlQura: return language.text("Umm al-Qura", "أم القرى")
        case .islamic: return language.text("Islamic", "إسلامي")
        case .civil: return language.text("Civil", "مدني")
        case .tabular: return language.text("Tabular", "جدولي")
        }
    }

    private func signedAdjustment(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private func resetDateRules() {
        selection = .empty(for: selectionMode)
        displayedMonth = HijriMonth(date: configuration.hijriDate(from: Date()))
    }

    private func optionMenu<Value: Hashable>(
        title: String,
        selection: Binding<Value>,
        values: [Value],
        label: @escaping (Value) -> String
    ) -> some View {
        Menu {
            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(label(selection.wrappedValue)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
