# ``HijriCalendar``

Model, convert, display, and select Hijri dates on Apple platforms using Umm al-Qura, Islamic, Civil, or Tabular calculations.

## Overview

The core module provides Foundation-only date values, month-grid generation, bounds, and deterministic selection transitions. Add `HijriCalendarUIKit` for a `UIView` renderer or `HijriCalendarSwiftUI` for bindings and SwiftUI styling.

```swift
let calendar = Calendar.hijri(system: .civil)
let hijri = HijriDate(date: Date(), calendar: calendar)
let month = HijriMonth(date: hijri)
let configuration = HijriCalendarConfiguration(calendarSystem: .civil)
let grid = HijriCalendarEngine(configuration: configuration).monthGrid(for: month)
```

Use the configuration resolver when a jurisdiction applies a manual adjustment
or publishes an official Gregorian start for a Hijri month:

```swift
var configuration = HijriCalendarConfiguration(
    calendarSystem: .ummAlQura,
    dayAdjustment: 0
)
configuration.setMonthStartOverride(
    officialStartDate,
    for: HijriMonth(year: 1448, month: 9)
)

let hijriToday = configuration.hijriDate(from: Date())
let gregorianDay = configuration.foundationDate(from: hijriToday)
```

The host app is responsible for obtaining and persisting official dates from its
trusted authority. The package performs no country lookup or network request.

## Topics

### Dates and months

- ``HijriDate``
- ``HijriMonth``
- ``HijriCalendarEngine``
- ``HijriCalendarConfiguration``
- ``HijriCalendarSystem``
- ``HijriMonthStartOverride``
- ``HijriLayoutDirection``
- ``HijriMonthGrid``
- ``HijriCalendarDay``

### Selection

- ``HijriSelectionMode``
- ``HijriCalendarSelection``
- ``HijriDateRange``
- ``HijriSelectionReducer``
