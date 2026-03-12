import SwiftUI

/// ViewModel that manages user preferences for the SQL editor appearance.
///
/// Persists the SQL keyword highlight color as a hex string in `UserDefaults`,
/// allowing the setting to survive app launches. Provides computed properties
/// to convert between the stored hex string and `SwiftUI.Color` / `UIColor`
/// for use in the UI and syntax highlighter respectively.
///
/// Uses the `@Observable` macro for automatic SwiftUI view tracking.
@Observable
final class SettingsViewModel {

    // MARK: - Constants

    /// The `UserDefaults` key used to store the keyword color hex string.
    private static let keywordColorKey = "sqlKeywordColorHex"

    // MARK: - State

    /// The keyword highlight color as a SwiftUI `Color`.
    ///
    /// Reading this property converts the persisted hex string to a `Color`.
    /// Writing this property converts the `Color` back to a hex string and
    /// persists it to `UserDefaults`.
    var keywordColor: Color {
        get { HexColor.color(from: keywordColorHex) }
        set { keywordColorHex = HexColor.hex(from: newValue) }
    }

    /// The keyword highlight color as a `UIColor`, for use by ``SQLSyntaxHighlighter``.
    ///
    /// Cached to avoid creating a new `UIColor` instance on every access,
    /// which would cause `UIViewRepresentable.updateUIView` to see a
    /// different reference each SwiftUI pass and trigger infinite update cycles.
    private(set) var keywordUIColor: UIColor

    // MARK: - Persistence

    /// The hex string representation of the keyword color, persisted in `UserDefaults`.
    ///
    /// Defaults to ``HexColor/defaultKeywordHex`` (`"#7B1FA2"`, dark violet)
    /// when no value has been saved previously. The `didSet` observer writes
    /// the new value to `UserDefaults` immediately on every change.
    private(set) var keywordColorHex: String {
        didSet {
            UserDefaults.standard.set(keywordColorHex, forKey: Self.keywordColorKey)
            keywordUIColor = HexColor.uiColor(from: keywordColorHex)
        }
    }

    // MARK: - Initialization

    /// Creates a new settings ViewModel, loading the persisted keyword color
    /// from `UserDefaults` or falling back to the default dark violet.
    init() {
        let hex = UserDefaults.standard.string(forKey: Self.keywordColorKey)
            ?? HexColor.defaultKeywordHex
        self.keywordColorHex = hex
        self.keywordUIColor = HexColor.uiColor(from: hex)
    }
}
