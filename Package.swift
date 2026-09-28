// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HijriCalendar",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "HijriCalendar", targets: ["HijriCalendar"]),
        .library(name: "HijriCalendarUIKit", targets: ["HijriCalendarUIKit"]),
        .library(name: "HijriCalendarSwiftUI", targets: ["HijriCalendarSwiftUI"])
    ],
    targets: [
        .target(name: "HijriCalendar"),
        .target(
            name: "HijriCalendarUIKit",
            dependencies: ["HijriCalendar"]
        ),
        .target(
            name: "HijriCalendarSwiftUI",
            dependencies: ["HijriCalendar", "HijriCalendarUIKit"]
        ),
        .testTarget(
            name: "HijriCalendarTests",
            dependencies: ["HijriCalendar"]
        )
    ],
    swiftLanguageModes: [.v5]
)
