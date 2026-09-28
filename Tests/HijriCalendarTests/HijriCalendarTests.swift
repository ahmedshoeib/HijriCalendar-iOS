import XCTest
@testable import HijriCalendar

final class HijriCalendarTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!

    func testGregorianToUmmAlQuraConversion() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let date = try XCTUnwrap(gregorian.date(from: DateComponents(
            year: 2024,
            month: 3,
            day: 11,
            hour: 12
        )))

        let hijri = HijriDate(
            date: date,
            calendar: .hijriUmmAlQura(timeZone: utc)
        )

        XCTAssertEqual(hijri, HijriDate(year: 1445, month: 9, day: 1))
    }

    func testDefaultCalendarSystemRemainsUmmAlQura() {
        let configuration = HijriCalendarConfiguration(timeZone: utc)

        XCTAssertEqual(configuration.calendarSystem, .ummAlQura)
        XCTAssertEqual(configuration.calendar.identifier, .islamicUmmAlQura)
    }

    func testCalendarSystemsMapToFoundationIdentifiers() {
        XCTAssertEqual(HijriCalendarSystem.ummAlQura.foundationIdentifier, .islamicUmmAlQura)
        XCTAssertEqual(HijriCalendarSystem.islamic.foundationIdentifier, .islamic)
        XCTAssertEqual(HijriCalendarSystem.civil.foundationIdentifier, .islamicCivil)
        XCTAssertEqual(HijriCalendarSystem.tabular.foundationIdentifier, .islamicTabular)
    }

    func testEveryCalendarSystemRoundTripsAndBuildsGrid() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let referenceDate = try XCTUnwrap(gregorian.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 27,
            hour: 12
        )))

        for system in HijriCalendarSystem.allCases {
            let configuration = HijriCalendarConfiguration(
                locale: Locale(identifier: "en_US"),
                timeZone: utc,
                calendarSystem: system,
                firstWeekday: 7
            )
            let calendar = configuration.calendar
            let hijriDate = configuration.hijriDate(from: referenceDate)
            let roundTrip = try XCTUnwrap(configuration.foundationDate(from: hijriDate))
            let grid = HijriCalendarEngine(configuration: configuration)
                .monthGrid(for: HijriMonth(date: hijriDate))

            XCTAssertEqual(calendar.identifier, system.foundationIdentifier)
            XCTAssertEqual(
                gregorian.dateComponents([.year, .month, .day], from: roundTrip),
                gregorian.dateComponents([.year, .month, .day], from: referenceDate),
                "Failed Gregorian round trip for \(system.rawValue)"
            )
            XCTAssertEqual(grid.days.count, 42, "Invalid grid for \(system.rawValue)")
            XCTAssertEqual(grid.weeks.count, 6, "Invalid week count for \(system.rawValue)")
        }
    }

    func testDayAdjustmentIsBidirectionalAndClamped() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let date = try XCTUnwrap(gregorian.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 27,
            hour: 12
        )))
        let nextDay = try XCTUnwrap(gregorian.date(byAdding: .day, value: 1, to: date))
        var configuration = HijriCalendarConfiguration(
            timeZone: utc,
            dayAdjustment: 1
        )
        let expected = HijriDate(date: nextDay, calendar: configuration.calendar)

        XCTAssertEqual(configuration.hijriDate(from: date), expected)
        XCTAssertEqual(try XCTUnwrap(configuration.foundationDate(from: expected)), date)

        configuration.dayAdjustment = 20
        XCTAssertEqual(configuration.dayAdjustment, 2)
        configuration.dayAdjustment = -20
        XCTAssertEqual(configuration.dayAdjustment, -2)
    }

    func testOfficialMonthStartOverrideIsBidirectional() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        var configuration = HijriCalendarConfiguration(timeZone: utc)
        let month = HijriMonth(year: 1448, month: 4)
        let firstDay = HijriDate(year: month.year, month: month.month, day: 1)
        let calculatedStart = try XCTUnwrap(configuration.foundationDate(from: firstDay))
        let officialStart = try XCTUnwrap(
            gregorian.date(byAdding: .day, value: 1, to: calculatedStart)
        )

        configuration.setMonthStartOverride(officialStart, for: month)

        XCTAssertEqual(configuration.foundationDate(from: firstDay), officialStart)
        XCTAssertEqual(configuration.hijriDate(from: officialStart), firstDay)

        for offset in -35...70 {
            let date = try XCTUnwrap(gregorian.date(byAdding: .day, value: offset, to: officialStart))
            let hijriDate = configuration.hijriDate(from: date)
            XCTAssertEqual(
                configuration.foundationDate(from: hijriDate),
                date,
                "Official override failed at offset \(offset)"
            )
        }

        configuration.setMonthStartOverride(nil, for: month)
        XCTAssertTrue(configuration.monthStartOverrides.isEmpty)
        XCTAssertEqual(configuration.foundationDate(from: firstDay), calculatedStart)
    }

    func testOfficialOverrideTakesPrecedenceAndLastDuplicateWins() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let calculationOnly = HijriCalendarConfiguration(timeZone: utc)
        let month = HijriMonth(year: 1448, month: 4)
        let firstDay = HijriDate(year: month.year, month: month.month, day: 1)
        let calculatedStart = try XCTUnwrap(
            calculationOnly.foundationDate(from: firstDay)
        )
        let firstOverride = try XCTUnwrap(
            gregorian.date(byAdding: .day, value: -1, to: calculatedStart)
        )
        let finalOverrideDay = try XCTUnwrap(
            gregorian.date(byAdding: .day, value: 1, to: calculatedStart)
        )
        let finalOverrideWithTime = try XCTUnwrap(
            gregorian.date(byAdding: .hour, value: 9, to: finalOverrideDay)
        )
        var configuration = HijriCalendarConfiguration(
            timeZone: utc,
            dayAdjustment: -2,
            monthStartOverrides: [
                HijriMonthStartOverride(
                    month: month,
                    gregorianStartDate: firstOverride
                ),
                HijriMonthStartOverride(
                    month: month,
                    gregorianStartDate: finalOverrideWithTime
                )
            ]
        )

        XCTAssertEqual(configuration.foundationDate(from: firstDay), finalOverrideDay)
        XCTAssertEqual(configuration.hijriDate(from: finalOverrideWithTime), firstDay)

        configuration.dayAdjustment = 2
        XCTAssertEqual(configuration.foundationDate(from: firstDay), finalOverrideDay)
    }

    func testInvalidOfficialMonthLengthsRejectHijriConversion() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let base = HijriCalendarConfiguration(timeZone: utc)
        let month = HijriMonth(year: 1448, month: 4)
        let nextMonth = month.advanced(by: 1, calendar: base.calendar)
        let firstDay = HijriDate(year: month.year, month: month.month, day: 1)
        let start = try XCTUnwrap(base.foundationDate(from: firstDay))

        for invalidLength in [28, 31] {
            let nextStart = try XCTUnwrap(
                gregorian.date(byAdding: .day, value: invalidLength, to: start)
            )
            let configuration = HijriCalendarConfiguration(
                timeZone: utc,
                monthStartOverrides: [
                    HijriMonthStartOverride(
                        month: month,
                        gregorianStartDate: start
                    ),
                    HijriMonthStartOverride(
                        month: nextMonth,
                        gregorianStartDate: nextStart
                    )
                ]
            )

            XCTAssertNil(
                configuration.foundationDate(from: firstDay),
                "Accepted an invalid \(invalidLength)-day official month"
            )
        }
    }

    func testConsecutiveOverridesCanChangeOfficialMonthLength() throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let base = HijriCalendarConfiguration(timeZone: utc)
        let month = HijriMonth(year: 1448, month: 4)
        let nextMonth = month.advanced(by: 1, calendar: base.calendar)
        let start = try XCTUnwrap(base.foundationDate(from: HijriDate(
            year: month.year,
            month: month.month,
            day: 1
        )))
        let calculatedNextStart = try XCTUnwrap(base.foundationDate(from: HijriDate(
            year: nextMonth.year,
            month: nextMonth.month,
            day: 1
        )))
        let calculatedLength = try XCTUnwrap(
            gregorian.dateComponents([.day], from: start, to: calculatedNextStart).day
        )
        let correction = calculatedLength == 29 ? 1 : -1
        let officialNextStart = try XCTUnwrap(
            gregorian.date(byAdding: .day, value: correction, to: calculatedNextStart)
        )
        let officialLength = calculatedLength + correction
        let configuration = HijriCalendarConfiguration(
            timeZone: utc,
            monthStartOverrides: [
                HijriMonthStartOverride(month: month, gregorianStartDate: start),
                HijriMonthStartOverride(month: nextMonth, gregorianStartDate: officialNextStart)
            ]
        )
        let lastOfficialDay = HijriDate(
            year: month.year,
            month: month.month,
            day: officialLength
        )

        XCTAssertEqual(
            configuration.foundationDate(from: lastOfficialDay),
            gregorian.date(byAdding: .day, value: officialLength - 1, to: start)
        )
        XCTAssertEqual(
            configuration.hijriDate(from: officialNextStart),
            HijriDate(year: nextMonth.year, month: nextMonth.month, day: 1)
        )
        if officialLength == 29 {
            XCTAssertNil(configuration.foundationDate(from: HijriDate(
                year: month.year,
                month: month.month,
                day: 30
            )))
        }

        let grid = HijriCalendarEngine(configuration: configuration).monthGrid(for: month)
        XCTAssertEqual(
            grid.days.filter { $0.monthPosition == .current }.count,
            officialLength
        )
    }

    func testHijriDateRoundTrip() throws {
        let calendar = Calendar.hijriUmmAlQura(timeZone: utc)
        let expected = HijriDate(year: 1447, month: 10, day: 12)
        let date = try XCTUnwrap(expected.foundationDate(in: calendar))

        XCTAssertEqual(HijriDate(date: date, calendar: calendar), expected)
    }

    func testHijriDatesSortChronologically() {
        let dates = [
            HijriDate(year: 1447, month: 10, day: 1),
            HijriDate(year: 1446, month: 12, day: 30),
            HijriDate(year: 1447, month: 9, day: 29)
        ]

        XCTAssertEqual(dates.sorted(), [dates[1], dates[2], dates[0]])
        XCTAssertEqual(dates[0].description, "1447-10-01 AH")
    }

    func testHijriDateCodableRoundTrip() throws {
        let value = HijriDate(year: 1447, month: 9, day: 1)
        let data = try JSONEncoder().encode(value)

        XCTAssertEqual(try JSONDecoder().decode(HijriDate.self, from: data), value)
    }

    func testMonthAdvancementCrossesYearBoundary() {
        let calendar = Calendar.hijriUmmAlQura(timeZone: utc)

        XCTAssertEqual(
            HijriMonth(year: 1447, month: 12).advanced(by: 1, calendar: calendar),
            HijriMonth(year: 1448, month: 1)
        )
        XCTAssertEqual(
            HijriMonth(year: 1447, month: 1).advanced(by: -1, calendar: calendar),
            HijriMonth(year: 1446, month: 12)
        )
    }

    func testMonthGridAlwaysContainsSixWeeks() {
        let configuration = HijriCalendarConfiguration(
            locale: Locale(identifier: "en_US"),
            timeZone: utc,
            firstWeekday: 2
        )
        let grid = HijriCalendarEngine(configuration: configuration)
            .monthGrid(for: HijriMonth(year: 1447, month: 9))

        XCTAssertEqual(grid.days.count, 42)
        XCTAssertEqual(grid.weeks.count, 6)
        XCTAssertEqual(grid.weeks.allSatisfy { $0.count == 7 }, true)
        XCTAssertEqual(grid.days.filter { $0.monthPosition == .current }.first?.date.day, 1)
    }

    func testMonthGridDatesAreConsecutive() {
        let configuration = HijriCalendarConfiguration(timeZone: utc)
        let calendar = configuration.calendar
        let grid = HijriCalendarEngine(configuration: configuration)
            .monthGrid(for: HijriMonth(year: 1447, month: 9))

        for pair in zip(grid.days, grid.days.dropFirst()) {
            XCTAssertEqual(
                calendar.date(byAdding: .day, value: 1, to: pair.0.foundationDate),
                pair.1.foundationDate
            )
        }
    }

    func testGridCurrentMonthCountMatchesFoundation() throws {
        let configuration = HijriCalendarConfiguration(timeZone: utc)
        let calendar = configuration.calendar
        let month = HijriMonth(year: 1447, month: 9)
        let monthStart = try XCTUnwrap(
            HijriDate(year: month.year, month: month.month, day: 1).foundationDate(in: calendar)
        )
        let expectedCount = try XCTUnwrap(calendar.range(of: .day, in: .month, for: monthStart)?.count)
        let grid = HijriCalendarEngine(configuration: configuration).monthGrid(for: month)

        XCTAssertEqual(grid.days.filter { $0.monthPosition == .current }.count, expectedCount)
        XCTAssertTrue(grid.days.contains { $0.monthPosition == .previous })
        XCTAssertTrue(grid.days.contains { $0.monthPosition == .next })
    }

    func testDateBoundsAreAppliedToGridDays() {
        let minimum = HijriDate(year: 1447, month: 9, day: 5)
        let maximum = HijriDate(year: 1447, month: 9, day: 20)
        let configuration = HijriCalendarConfiguration(
            timeZone: utc,
            minimumDate: minimum,
            maximumDate: maximum
        )
        let grid = HijriCalendarEngine(configuration: configuration)
            .monthGrid(for: HijriMonth(year: 1447, month: 9))

        XCTAssertFalse(try XCTUnwrap(grid.days.first { $0.date == HijriDate(year: 1447, month: 9, day: 4) }).isWithinBounds)
        XCTAssertTrue(try XCTUnwrap(grid.days.first { $0.date == minimum }).isWithinBounds)
        XCTAssertTrue(try XCTUnwrap(grid.days.first { $0.date == maximum }).isWithinBounds)
        XCTAssertFalse(try XCTUnwrap(grid.days.first { $0.date == HijriDate(year: 1447, month: 9, day: 21) }).isWithinBounds)
    }

    func testConfigurationContainsInclusiveBounds() {
        let minimum = HijriDate(year: 1447, month: 9, day: 5)
        let maximum = HijriDate(year: 1447, month: 9, day: 20)
        let configuration = HijriCalendarConfiguration(
            minimumDate: minimum,
            maximumDate: maximum
        )

        XCTAssertTrue(configuration.contains(minimum))
        XCTAssertTrue(configuration.contains(maximum))
        XCTAssertFalse(configuration.contains(HijriDate(year: 1447, month: 9, day: 4)))
        XCTAssertFalse(configuration.contains(HijriDate(year: 1447, month: 9, day: 21)))
    }

    func testFirstWeekdayIsClamped() {
        var configuration = HijriCalendarConfiguration(firstWeekday: -3)
        XCTAssertEqual(configuration.firstWeekday, 1)
        configuration.firstWeekday = 99
        XCTAssertEqual(configuration.firstWeekday, 7)
    }

    func testLocaleAndTimeZoneCanChangeAtRuntime() {
        var configuration = HijriCalendarConfiguration(
            locale: Locale(identifier: "en_US"),
            timeZone: utc
        )

        configuration.locale = Locale(identifier: "ar_SA")
        configuration.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        configuration.calendarSystem = .civil

        XCTAssertTrue(configuration.locale.identifier.lowercased().hasPrefix("ar"))
        XCTAssertEqual(configuration.timeZone.identifier, "Asia/Riyadh")
        XCTAssertEqual(configuration.calendar.identifier, .islamicCivil)
    }

    func testAutomaticLayoutDirectionUsesLocale() {
        XCTAssertEqual(
            HijriCalendarConfiguration(locale: Locale(identifier: "en_US")).resolvedLayoutDirection,
            .leftToRight
        )
        XCTAssertEqual(
            HijriCalendarConfiguration(locale: Locale(identifier: "ar_SA")).resolvedLayoutDirection,
            .rightToLeft
        )
    }

    func testExplicitLayoutDirectionOverridesLocale() {
        XCTAssertEqual(
            HijriCalendarConfiguration(
                locale: Locale(identifier: "ar_SA"),
                layoutDirection: .leftToRight
            ).resolvedLayoutDirection,
            .leftToRight
        )
        XCTAssertEqual(
            HijriCalendarConfiguration(
                locale: Locale(identifier: "en_US"),
                layoutDirection: .rightToLeft
            ).resolvedLayoutDirection,
            .rightToLeft
        )
    }

    func testConfigurationCodableRoundTrip() throws {
        let value = HijriCalendarConfiguration(
            locale: Locale(identifier: "ar_SA"),
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            calendarSystem: .tabular,
            dayAdjustment: -1,
            monthStartOverrides: [
                HijriMonthStartOverride(
                    month: HijriMonth(year: 1447, month: 9),
                    gregorianStartDate: Date(timeIntervalSince1970: 1_772_323_200)
                )
            ],
            firstWeekday: 7,
            minimumDate: HijriDate(year: 1447, month: 9, day: 1),
            maximumDate: HijriDate(year: 1447, month: 10, day: 1),
            showsAdjacentMonthDates: false,
            layoutDirection: .rightToLeft
        )
        let data = try JSONEncoder().encode(value)

        XCTAssertEqual(try JSONDecoder().decode(HijriCalendarConfiguration.self, from: data), value)
    }

    func testLegacyConfigurationDefaultsToUmmAlQuraWhenDecoded() throws {
        let data = try XCTUnwrap("""
        {
          "localeIdentifier": "en_US",
          "timeZoneIdentifier": "GMT",
          "firstWeekday": 1,
          "showsAdjacentMonthDates": true,
          "layoutDirection": "automatic"
        }
        """.data(using: .utf8))

        let configuration = try JSONDecoder().decode(
            HijriCalendarConfiguration.self,
            from: data
        )

        XCTAssertEqual(configuration.calendarSystem, .ummAlQura)
        XCTAssertEqual(configuration.calendar.identifier, .islamicUmmAlQura)
        XCTAssertEqual(configuration.dayAdjustment, 0)
        XCTAssertTrue(configuration.monthStartOverrides.isEmpty)
    }

    func testDayLabelsUseConfiguredLocale() {
        let date = HijriDate(year: 1447, month: 9, day: 12)
        let english = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US")
        )).dayLabel(for: date)
        let arabic = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "ar_SA")
        )).dayLabel(for: date)

        XCTAssertEqual(english, "12")
        XCTAssertFalse(arabic.isEmpty)
    }

    func testPaddedDayLabelsUseConfiguredLocale() {
        let date = HijriDate(year: 1447, month: 9, day: 1)
        let english = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US")
        )).dayLabel(for: date, minimumIntegerDigits: 2)
        let arabic = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "ar_SA")
        )).dayLabel(for: date, minimumIntegerDigits: 2)

        XCTAssertEqual(english, "01")
        XCTAssertEqual(arabic, "٠١")
    }

    func testDayLabelClampsInvalidMinimumIntegerDigits() {
        let date = HijriDate(year: 1447, month: 9, day: 1)
        let engine = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US")
        ))

        XCTAssertEqual(engine.dayLabel(for: date, minimumIntegerDigits: 0), "1")
    }

    func testFullDateLabelsAreLocalizedAndUseHijriComponents() {
        let date = HijriDate(year: 1447, month: 9, day: 12)
        let englishEngine = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US")
        ))
        let arabicEngine = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "ar_SA")
        ))
        let english = englishEngine.dateLabel(for: date)
        let arabic = arabicEngine.dateLabel(for: date)

        XCTAssertTrue(english.hasPrefix("12 "))
        XCTAssertTrue(english.contains("1447"))
        XCTAssertNotEqual(arabic, english)
        XCTAssertFalse(arabic.isEmpty)
    }

    func testNoneSelectionNeverSelectsDate() {
        let date = HijriDate(year: 1447, month: 9, day: 1)
        let result = HijriSelectionReducer.selecting(date, in: .none, mode: .none)

        XCTAssertEqual(result, .none)
        XCTAssertFalse(result.contains(date))
    }

    func testSingleSelectionSelectsAndTogglesOff() {
        let date = HijriDate(year: 1447, month: 9, day: 1)
        let selected = HijriSelectionReducer.selecting(
            date,
            in: .single(nil),
            mode: .single
        )
        XCTAssertEqual(selected, .single(date))

        let cleared = HijriSelectionReducer.selecting(
            date,
            in: selected,
            mode: .single
        )
        XCTAssertEqual(cleared, .single(nil))
    }

    func testMultipleSelectionTogglesDates() {
        let date = HijriDate(year: 1447, month: 9, day: 1)
        let selected = HijriSelectionReducer.selecting(
            date,
            in: .multiple([]),
            mode: .multiple
        )
        XCTAssertTrue(selected.contains(date))

        let deselected = HijriSelectionReducer.selecting(
            date,
            in: selected,
            mode: .multiple
        )
        XCTAssertFalse(deselected.contains(date))
    }

    func testRangeSelectionNormalizesReverseInput() throws {
        let later = HijriDate(year: 1447, month: 9, day: 20)
        let earlier = HijriDate(year: 1447, month: 9, day: 4)
        let started = HijriSelectionReducer.selecting(
            later,
            in: .range(nil),
            mode: .range
        )
        let completed = HijriSelectionReducer.selecting(
            earlier,
            in: started,
            mode: .range
        )

        guard case .range(let range) = completed else {
            return XCTFail("Expected range selection")
        }
        XCTAssertEqual(range?.lowerBound, earlier)
        XCTAssertEqual(range?.upperBound, later)
        XCTAssertTrue(try XCTUnwrap(range).contains(HijriDate(year: 1447, month: 9, day: 10)))
    }

    func testRangeSelectionCompletesForward() {
        let start = HijriDate(year: 1447, month: 9, day: 4)
        let end = HijriDate(year: 1447, month: 9, day: 20)
        let started = HijriSelectionReducer.selecting(start, in: .range(nil), mode: .range)
        let completed = HijriSelectionReducer.selecting(end, in: started, mode: .range)

        XCTAssertEqual(completed, .range(HijriDateRange(from: start, to: end)))
        XCTAssertTrue(completed.contains(start))
        XCTAssertTrue(completed.contains(end))
    }

    func testThirdRangeTapStartsNewRange() {
        let oldRange = HijriDateRange(
            from: HijriDate(year: 1447, month: 9, day: 4),
            to: HijriDate(year: 1447, month: 9, day: 20)
        )
        let newStart = HijriDate(year: 1447, month: 10, day: 1)
        let result = HijriSelectionReducer.selecting(
            newStart,
            in: .range(oldRange),
            mode: .range
        )

        XCTAssertEqual(result, .range(HijriDateRange(from: newStart)))
    }

    func testEmptySelectionMatchesEveryMode() {
        XCTAssertEqual(HijriCalendarSelection.empty(for: .none), .none)
        XCTAssertEqual(HijriCalendarSelection.empty(for: .single), .single(nil))
        XCTAssertEqual(HijriCalendarSelection.empty(for: .multiple), .multiple([]))
        XCTAssertEqual(HijriCalendarSelection.empty(for: .range), .range(nil))
    }

    func testSelectionCodableRoundTripsEveryMode() throws {
        let date = HijriDate(year: 1447, month: 9, day: 4)
        let values: [HijriCalendarSelection] = [
            .none,
            .single(date),
            .multiple([date, HijriDate(year: 1447, month: 9, day: 8)]),
            .range(HijriDateRange(from: date, to: HijriDate(year: 1447, month: 9, day: 20)))
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            XCTAssertEqual(try JSONDecoder().decode(HijriCalendarSelection.self, from: data), value)
        }
    }

    func testReducersRecoverFromMismatchedSelectionValues() {
        let date = HijriDate(year: 1447, month: 9, day: 4)

        XCTAssertEqual(
            HijriSelectionReducer.selecting(date, in: .single(nil), mode: .multiple),
            .multiple([date])
        )
        XCTAssertEqual(
            HijriSelectionReducer.selecting(date, in: .multiple([]), mode: .range),
            .range(HijriDateRange(from: date))
        )
    }

    func testPartialRangeContainsOnlyItsStart() {
        let start = HijriDate(year: 1447, month: 9, day: 4)
        let range = HijriDateRange(from: start)

        XCTAssertTrue(range.contains(start))
        XCTAssertFalse(range.contains(HijriDate(year: 1447, month: 9, day: 5)))
    }

    func testWeekdaySymbolsRespectFirstWeekday() {
        let sunday = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US"),
            timeZone: utc,
            firstWeekday: 1
        )).weekdaySymbols()
        let monday = HijriCalendarEngine(configuration: .init(
            locale: Locale(identifier: "en_US"),
            timeZone: utc,
            firstWeekday: 2
        )).weekdaySymbols()

        XCTAssertEqual(sunday.count, 7)
        XCTAssertEqual(monday.first, sunday[1])
    }
}
