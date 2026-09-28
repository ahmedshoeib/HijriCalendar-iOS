import Foundation

/// An authority-published Gregorian start date for a Hijri month.
///
/// The start date is normalized to the civil day in the configuration's time
/// zone. It anchors following months until a later override is supplied.
public struct HijriMonthStartOverride: Hashable, Codable, Sendable {
    public let month: HijriMonth
    public let gregorianStartDate: Date

    public init(month: HijriMonth, gregorianStartDate: Date) {
        self.month = month
        self.gregorianStartDate = gregorianStartDate
    }
}
