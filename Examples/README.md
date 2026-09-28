# Example Apps

This folder contains two complete, runnable iOS projects:

- `SwiftUIDemo/SwiftUIDemo.xcodeproj` demonstrates the binding and modifier APIs.
- `UIKitDemo/UIKitDemo.xcodeproj` demonstrates delegates, data sources, and programmatic Auto Layout.

Both projects resolve `HijriCalendar-iOS` from GitHub using Swift Package Manager, with an Up to Next Major requirement starting at `1.0.0`. Open either `.xcodeproj`, allow Xcode to resolve packages, choose an iPhone simulator or device, and run the app.

The demos cover all four Hijri calculation systems, all four selection modes, runtime English/Arabic switching, automatic and forced LTR/RTL layouts, date bounds, first weekday, adjacent dates, navigation controls, themes, locale-aware padded day labels, event decorations, disabled dates, callbacks, and programmatic month navigation.

Each app also includes a `-2...+2` day-adjustment selector and an **Official start demo (+1 day)** switch. The switch publishes a simulated start for the current Hijri month one Gregorian day after the calculated start, then uses the same authority-correction path an app would use with real country or moon-sighting data. Changing the calculation or correction rules clears the current selection and returns the calendar to the newly resolved current month.

The examples are intentionally offline. A production app should obtain official dates from its chosen authority, persist them, and pass them to `HijriCalendarConfiguration` as `HijriMonthStartOverride` values.
