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

    /// The available options for the maximum number of rows displayed in pinned tables.
    static let rowLimitOptions = [5, 10, 20, 50, 100, 200]

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

    /// Creates a new settings ViewModel, loading the persisted keyword color
    /// from `UserDefaults` or falling back to the default dark violet.
    init() {
        let hex = UserDefaults.standard.string(forKey: Self.keywordColorKey)
            ?? HexColor.defaultKeywordHex
        self.keywordColorHex = hex
        self.keywordUIColor = HexColor.uiColor(from: hex)

        let modeRaw = UserDefaults.standard.string(forKey: Self.pinnedDisplayModeKey) ?? ""
        self.pinnedTableDisplayMode = PinnedTableDisplayMode(rawValue: modeRaw) ?? .data

        let savedLimit = UserDefaults.standard.integer(forKey: Self.pinnedRowLimitKey)
        self.pinnedTableRowLimit = savedLimit > 0 ? savedLimit : 10
    }
}
