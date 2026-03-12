import SwiftUI

/// Provides conversion utilities between hex color strings and SwiftUI/UIKit colors.
///
/// Used by ``SettingsViewModel`` to persist color preferences in `UserDefaults`
/// as hex strings (e.g., `"#7B1FA2"`) and convert them back to `Color` or
/// `UIColor` for use in the UI and syntax highlighting.
///
/// This is a caseless enum used as a namespace to prevent instantiation.
enum HexColor {

    /// The default keyword color hex string, corresponding to dark violet.
    static let defaultKeywordHex = "#7B1FA2"

    /// Creates a SwiftUI `Color` from a hex string.
    ///
    /// Supports formats with or without a leading `#` character.
    /// Falls back to the default dark violet if the string cannot be parsed.
    ///
    /// - Parameter hex: A hex color string such as `"#7B1FA2"` or `"7B1FA2"`.
    /// - Returns: The corresponding SwiftUI `Color`.
    static func color(from hex: String) -> Color {
        Color(uiColor: uiColor(from: hex))
    }

    /// Creates a `UIColor` from a hex string.
    ///
    /// Supports formats with or without a leading `#` character.
    /// Falls back to the default dark violet if the string cannot be parsed.
    ///
    /// - Parameter hex: A hex color string such as `"#7B1FA2"` or `"7B1FA2"`.
    /// - Returns: The corresponding `UIColor`.
    static func uiColor(from hex: String) -> UIColor {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard sanitized.count == 6,
              let rgbValue = UInt64(sanitized, radix: 16) else {
            return UIColor(red: 0x7B / 255.0, green: 0x1F / 255.0, blue: 0xA2 / 255.0, alpha: 1)
        }

        let red   = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgbValue >> 8)  & 0xFF) / 255.0
        let blue  = CGFloat(rgbValue         & 0xFF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    /// Converts a SwiftUI `Color` to a hex string in `"#RRGGBB"` format.
    ///
    /// Uses `UIColor` as an intermediate representation to extract RGB components.
    /// Falls back to ``defaultKeywordHex`` if the color cannot be decomposed.
    ///
    /// - Parameter color: The SwiftUI `Color` to convert.
    /// - Returns: A hex string such as `"#7B1FA2"`.
    static func hex(from color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return defaultKeywordHex
        }

        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
