import CoreText
import SwiftUI

/// Lumen design system tokens from `llumen-ai-frontend/src/styles/tokens.css`.
enum Theme {
    /// iOS dark elevated gray (`secondarySystemBackground`), in place of the navy wash.
    static let background = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let surfaceDeep = Color(hex: 0x0C0E10)
    static let neutral50 = Color(hex: 0xEAEBEC)
    static let neutral100 = Color(hex: 0xD4D5D7)
    static let neutral300 = Color(hex: 0x93979C)
    static let neutral500 = Color(hex: 0x51575F)
    static let neutral800 = Color(hex: 0x181C20)

    static let primary = Color(hex: 0x73ADF5)
    static let primarySoft = Color(hex: 0xABCEF9)
    static let positive = Color(hex: 0x25BA5D)
    static let warning = Color(hex: 0xFAB12A)
    static let negative = Color(hex: 0xED5151)
    static let chartTeal = Color(hex: 0x5EC4B0)
    static let chartViolet = Color(hex: 0xA78BFA)
    static let chartPink = Color(hex: 0xF472B6)

    static let text = Color.white
    static let textSecondary = neutral100
    static let textTertiary = neutral300

    static let border = Color.white.opacity(0.1)
    static let borderStrong = Color.white.opacity(0.2)
    static let hairline = Color.white.opacity(0.16)
    static let fillQuiet = Color.white.opacity(0.06)

    static let radiusUI: CGFloat = 12
    static let radiusCard: CGFloat = 16
    static let radiusPanel: CGFloat = 20

    static let spaceSM: CGFloat = 6
    static let spaceMD: CGFloat = 8
    static let spaceLG: CGFloat = 12
    static let spaceXL: CGFloat = 16
    static let space2XL: CGFloat = 20
    static let space3XL: CGFloat = 24
    static let space4XL: CGFloat = 32

    static let motion = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.22)

    /// Floating tab bar: 58pt capsule, 8pt above the home indicator, plus a gap for copy.
    static let chromeClearance: CGFloat = 58 + 8 + 16
}

enum LumenFont {
    static func register() {
        for name in ["InnovatorGrotesk-Regular", "InnovatorGrotesk-Medium", "InnovatorGrotesk-SemiBold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "InnovatorGrotesk-Medium"
        case .semibold: name = "InnovatorGrotesk-SemiBold"
        case .regular: name = "InnovatorGrotesk-Regular"
        }
        return .custom(name, size: size)
    }

    enum Weight { case regular, medium, semibold }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
