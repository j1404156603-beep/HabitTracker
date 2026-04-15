import SwiftUI

enum TeslaTheme {
    // Dark
    static let darkBackground = UIColor(red: 0, green: 0, blue: 0, alpha: 1) // #000000
    static let darkCardBackground = UIColor(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255, alpha: 1) // #1A1A1A
    static let darkPrimaryText = UIColor(red: 1, green: 1, blue: 1, alpha: 1) // #FFFFFF
    static let darkSecondaryText = UIColor(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255, alpha: 1) // #8E8E93
    static let darkDivider = UIColor(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255, alpha: 1) // #2C2C2E

    // Light
    static let lightBackground = UIColor(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255, alpha: 1) // #F2F2F7
    static let lightCardBackground = UIColor(red: 1, green: 1, blue: 1, alpha: 1) // #FFFFFF
    static let lightPrimaryText = UIColor(red: 0, green: 0, blue: 0, alpha: 1) // #000000
    static let lightSecondaryText = UIColor(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255, alpha: 1) // #8E8E93
    static let lightDivider = UIColor(red: 0xE5 / 255, green: 0xE5 / 255, blue: 0xEA / 255, alpha: 1) // #E5E5EA

    // Shared accents
    static let accent = UIColor(red: 0x3D / 255, green: 0x5A / 255, blue: 0xFE / 255, alpha: 1) // Tesla blue
    static let danger = UIColor(red: 0xE8 / 255, green: 0x19 / 255, blue: 0x2C / 255, alpha: 1) // Tesla red
    static let success = UIColor(red: 0x4C / 255, green: 0xAF / 255, blue: 0x50 / 255, alpha: 0.9) // #4CAF50 (low-sat)
}

extension Color {
    /// Dynamic color: light ↔ dark without duplicating UI code.
    init(light: UInt32, dark: UInt32, alpha: Double = 1.0) {
        self = Color(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                let r = CGFloat((hex >> 16) & 0xFF) / 255.0
                let g = CGFloat((hex >> 8) & 0xFF) / 255.0
                let b = CGFloat(hex & 0xFF) / 255.0
                return UIColor(red: r, green: g, blue: b, alpha: alpha)
            }
        )
    }

    enum theme {
        // Global mapping
        static let background = Color(light: 0xF2F2F7, dark: 0x000000)
        static let cardBackground = Color(light: 0xFFFFFF, dark: 0x1A1A1A)
        static let primaryText = Color(light: 0x000000, dark: 0xFFFFFF)
        static let secondaryText = Color(light: 0x8E8E93, dark: 0x8E8E93)
        static let divider = Color(light: 0xE5E5EA, dark: 0x2C2C2E)

        // Accents / status
        static let accent = Color(light: 0x3D5AFE, dark: 0x3D5AFE)
        static let danger = Color(light: 0xE8192C, dark: 0xE8192C)
        static let success = Color(light: 0x4CAF50, dark: 0x4CAF50, alpha: 0.9)

        // Components
        static let checkInButtonBackground = Color(light: 0xFFFFFF, dark: 0x000000)
        static let scrim = Color(light: 0x000000, dark: 0x000000, alpha: 0.35)
    }
}
