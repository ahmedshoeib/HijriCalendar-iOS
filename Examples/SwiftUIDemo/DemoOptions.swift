import SwiftUI
import HijriCalendar

enum DemoLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case arabic

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .system: return .current
        case .english: return Locale(identifier: "en_US")
        case .arabic: return Locale(identifier: "ar_SA")
        }
    }

    var title: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }

    var interfaceDirection: LayoutDirection {
        locale.identifier.lowercased().hasPrefix("ar") ? .rightToLeft : .leftToRight
    }

    func text(_ english: String, _ arabic: String) -> String {
        locale.identifier.lowercased().hasPrefix("ar") ? arabic : english
    }
}

enum DemoTheme: String, CaseIterable, Identifiable {
    case teal
    case indigo

    var id: Self { self }
    var title: String { rawValue.capitalized }
    var selection: Color { self == .teal ? .teal : .indigo }
    var today: Color { self == .teal ? .teal : .indigo }
    var event: Color { self == .teal ? .orange : .pink }
}
