#if canImport(UIKit)
import SwiftUI
import HijriCalendar
import HijriCalendarUIKit

/// A binding-driven SwiftUI interface backed by the same renderer as UIKit.
public struct HijriCalendar: UIViewRepresentable {
    @Binding private var selection: HijriCalendarSelection
    @Binding private var displayedMonth: HijriMonth

    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    private var selectionMode: HijriSelectionMode
    private var configuration: HijriCalendarConfiguration
    private var style: HijriCalendarStyle = .material
    private var showsNavigationButtons = true
    private var decorationProvider: ((HijriDate) -> HijriCalendarDayDecoration?)?
    private var dateTapHandler: ((HijriDate) -> Void)?
    private var monthTitleProvider: ((HijriMonth) -> String)?
    private var dayLabelProvider: ((HijriDate) -> String)?
    private var minimumDayLabelDigits = 1
    private var weekdaySymbolsOverride: [String]?
    private var localeOverride: Locale?
    private var timeZoneOverride: TimeZone?
    private var calendarSystemOverride: HijriCalendarSystem?
    private var layoutDirectionOverride: HijriLayoutDirection?

    public init(
        selection: Binding<HijriCalendarSelection>,
        displayedMonth: Binding<HijriMonth>,
        selectionMode: HijriSelectionMode = .single,
        configuration: HijriCalendarConfiguration = .init()
    ) {
        _selection = selection
        _displayedMonth = displayedMonth
        self.selectionMode = selectionMode
        self.configuration = configuration
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> HijriCalendarView {
        let view = HijriCalendarView()
        view.delegate = context.coordinator
        view.dataSource = context.coordinator
        update(view, coordinator: context.coordinator)
        return view
    }

    public func updateUIView(_ uiView: HijriCalendarView, context: Context) {
        context.coordinator.parent = self
        update(uiView, coordinator: context.coordinator)
    }

    public func calendarStyle(_ style: HijriCalendarStyle) -> Self {
        var copy = self
        copy.style = style
        return copy
    }

    public func showsNavigationButtons(_ showsNavigationButtons: Bool) -> Self {
        var copy = self
        copy.showsNavigationButtons = showsNavigationButtons
        return copy
    }

    public func dayDecoration(
        _ provider: @escaping (HijriDate) -> HijriCalendarDayDecoration?
    ) -> Self {
        var copy = self
        copy.decorationProvider = provider
        return copy
    }

    public func onDateTap(_ handler: @escaping (HijriDate) -> Void) -> Self {
        var copy = self
        copy.dateTapHandler = handler
        return copy
    }

    public func monthTitle(_ provider: @escaping (HijriMonth) -> String) -> Self {
        var copy = self
        copy.monthTitleProvider = provider
        return copy
    }

    public func dayLabel(_ provider: @escaping (HijriDate) -> String) -> Self {
        var copy = self
        copy.dayLabelProvider = provider
        return copy
    }

    /// Sets the minimum width of localized numeric day labels, such as `01` or `٠١`.
    public func minimumDayLabelDigits(_ count: Int) -> Self {
        var copy = self
        copy.minimumDayLabelDigits = max(1, count)
        return copy
    }

    public func weekdaySymbols(_ symbols: [String]) -> Self {
        precondition(symbols.count == 7, "weekdaySymbols must contain exactly seven values")
        var copy = self
        copy.weekdaySymbolsOverride = symbols
        return copy
    }

    public func calendarLocale(_ locale: Locale) -> Self {
        var copy = self
        copy.localeOverride = locale
        return copy
    }

    public func calendarTimeZone(_ timeZone: TimeZone) -> Self {
        var copy = self
        copy.timeZoneOverride = timeZone
        return copy
    }

    public func calendarSystem(_ system: HijriCalendarSystem) -> Self {
        var copy = self
        copy.calendarSystemOverride = system
        return copy
    }

    public func calendarLayoutDirection(_ direction: HijriLayoutDirection) -> Self {
        var copy = self
        copy.layoutDirectionOverride = direction
        return copy
    }

    private func update(_ view: HijriCalendarView, coordinator: Coordinator) {
        coordinator.isUpdating = true
        defer { coordinator.isUpdating = false }

        var resolvedConfiguration = configuration
        resolvedConfiguration.locale = localeOverride ?? locale
        resolvedConfiguration.timeZone = timeZoneOverride ?? timeZone
        if let calendarSystemOverride {
            resolvedConfiguration.calendarSystem = calendarSystemOverride
        }
        if let layoutDirectionOverride {
            resolvedConfiguration.layoutDirection = layoutDirectionOverride
        }

        if view.configuration != resolvedConfiguration {
            view.configuration = resolvedConfiguration
        }
        if view.selectionMode != selectionMode {
            view.selectionMode = selectionMode
        }
        if view.selection != selection {
            view.selection = selection
        }
        if view.displayedMonth != displayedMonth {
            view.display(displayedMonth, animated: false)
        }
        view.appearance = style.makeAppearance()
        view.showsNavigationButtons = showsNavigationButtons
        view.monthTitleFormatter = monthTitleProvider
        view.minimumDayLabelDigits = minimumDayLabelDigits
        view.dayFormatter = dayLabelProvider
        view.customWeekdaySymbols = weekdaySymbolsOverride
    }

    @MainActor
    public final class Coordinator: NSObject, HijriCalendarViewDelegate, HijriCalendarViewDataSource {
        var parent: HijriCalendar
        var isUpdating = false

        init(parent: HijriCalendar) {
            self.parent = parent
        }

        public func calendarView(
            _ calendarView: HijriCalendarView,
            didChangeSelection selection: HijriCalendarSelection
        ) {
            guard !isUpdating else { return }
            parent.selection = selection
        }

        public func calendarView(
            _ calendarView: HijriCalendarView,
            didDisplay month: HijriMonth
        ) {
            guard !isUpdating else { return }
            parent.displayedMonth = month
        }

        public func calendarView(_ calendarView: HijriCalendarView, didTap date: HijriDate) {
            parent.dateTapHandler?(date)
        }

        public func calendarView(
            _ calendarView: HijriCalendarView,
            decorationFor date: HijriDate
        ) -> HijriDayDecoration? {
            parent.decorationProvider?(date)?.makeUIKitDecoration()
        }
    }
}
#endif
