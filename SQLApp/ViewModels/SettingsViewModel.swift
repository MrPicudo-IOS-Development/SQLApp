//
//  SettingsViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

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
@MainActor
final class SettingsViewModel {

    // MARK: - Constants

    /// The `UserDefaults` key used to store the keyword color hex string.
    private static let keywordColorKey = "sqlKeywordColorHex"

    /// The `UserDefaults` key used to store the pinned table display mode.
    private static let pinnedDisplayModeKey = "pinnedTableDisplayMode"

    /// The `UserDefaults` key used to store the maximum number of rows shown for pinned tables.
    private static let pinnedRowLimitKey = "pinnedTableRowLimit"

    /// The `UserDefaults` key used to store the selected app style.
    private static let selectedStyleKey = "selectedAppStyle"

    /// The available options for the maximum number of rows displayed in pinned tables.
    static let rowLimitOptions = [5, 10, 20, 50, 100, 200]

    // MARK: - State

    /// The currently selected app style, determining the entire color palette.
    ///
    /// Changing this value persists the selection to `UserDefaults` and
    /// updates the keyword color hex to match the new style's accent color.
    var selectedStyle: AppStyle {
        didSet {
            UserDefaults.standard.set(selectedStyle.rawValue, forKey: Self.selectedStyleKey)
            keywordColorHex = HexColor.hex(from: selectedStyle.accentColor)
        }
    }

    /// The keyword highlight color as a SwiftUI `Color`.
    ///
    /// Derived from the persisted hex string. The setter is kept for backward
    /// compatibility but the primary way to change colors is via ``selectedStyle``.
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

    /// How pinned tables are displayed in the SQL editor: row data or column schema.
    ///
    /// Persisted immediately to `UserDefaults` on every change via the `didSet` observer.
    /// Defaults to ``PinnedTableDisplayMode/data`` when no value has been saved previously.
    var pinnedTableDisplayMode: PinnedTableDisplayMode {
        didSet {
            UserDefaults.standard.set(pinnedTableDisplayMode.rawValue, forKey: Self.pinnedDisplayModeKey)
        }
    }

    /// The maximum number of rows displayed for each pinned table when in data mode.
    ///
    /// Persisted immediately to `UserDefaults` on every change via the `didSet` observer.
    /// Defaults to `10` when no value has been saved previously.
    var pinnedTableRowLimit: Int {
        didSet {
            UserDefaults.standard.set(pinnedTableRowLimit, forKey: Self.pinnedRowLimitKey)
        }
    }

    // MARK: - Initialization

    /// Creates a new settings ViewModel, loading persisted values from `UserDefaults`.
    ///
    /// Restores the selected app style (defaulting to `.vibrant`) and derives
    /// the keyword color from it. Also loads pinned table preferences.
    init() {
        // Load selected style
        let styleRaw = UserDefaults.standard.string(forKey: Self.selectedStyleKey) ?? ""
        let style = AppStyle(rawValue: styleRaw) ?? .vibrant
        self.selectedStyle = style

        // Derive keyword color from the selected style's accent
        let hex = HexColor.hex(from: style.accentColor)
        self.keywordColorHex = hex
        self.keywordUIColor = HexColor.uiColor(from: hex)

        let modeRaw = UserDefaults.standard.string(forKey: Self.pinnedDisplayModeKey) ?? ""
        self.pinnedTableDisplayMode = PinnedTableDisplayMode(rawValue: modeRaw) ?? .data

        let savedLimit = UserDefaults.standard.integer(forKey: Self.pinnedRowLimitKey)
        self.pinnedTableRowLimit = savedLimit > 0 ? savedLimit : 10
    }
}
