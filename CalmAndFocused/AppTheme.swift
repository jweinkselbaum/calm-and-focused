import SwiftUI

enum ThemeID: String, CaseIterable, Codable {
    case wood, warmDark, slateBlue, forest, monochrome

    var displayName: String {
        switch self {
        case .wood:       return "Wood"
        case .warmDark:   return "Ember"
        case .slateBlue:  return "Slate"
        case .forest:     return "Forest"
        case .monochrome: return "Mono"
        }
    }
}

enum GrainStyle { case wood, subtle, none }

struct AppTheme {
    let id: ThemeID
    let base: Color
    let surface: Color
    let accent: Color
    let grain: GrainStyle

    static func current(for id: ThemeID) -> AppTheme {
        switch id {
        case .wood:
            return AppTheme(id: .wood,
                base:    Color(red: 0.14, green: 0.08, blue: 0.03),
                surface: Color(red: 0.20, green: 0.12, blue: 0.05),
                accent:  Color(red: 0.94, green: 0.70, blue: 0.26),
                grain:   .wood)
        case .warmDark:
            return AppTheme(id: .warmDark,
                base:    Color(red: 0.12, green: 0.09, blue: 0.08),
                surface: Color(red: 0.17, green: 0.13, blue: 0.11),
                accent:  Color(red: 0.92, green: 0.52, blue: 0.28),
                grain:   .subtle)
        case .slateBlue:
            return AppTheme(id: .slateBlue,
                base:    Color(red: 0.09, green: 0.11, blue: 0.18),
                surface: Color(red: 0.13, green: 0.16, blue: 0.24),
                accent:  Color(red: 0.45, green: 0.68, blue: 0.96),
                grain:   .none)
        case .forest:
            return AppTheme(id: .forest,
                base:    Color(red: 0.07, green: 0.12, blue: 0.08),
                surface: Color(red: 0.10, green: 0.17, blue: 0.11),
                accent:  Color(red: 0.38, green: 0.82, blue: 0.46),
                grain:   .subtle)
        case .monochrome:
            return AppTheme(id: .monochrome,
                base:    Color(red: 0.06, green: 0.06, blue: 0.06),
                surface: Color(red: 0.11, green: 0.11, blue: 0.11),
                accent:  Color(red: 0.82, green: 0.82, blue: 0.82),
                grain:   .none)
        }
    }
}
