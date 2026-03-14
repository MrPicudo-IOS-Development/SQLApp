//
//  PinnedTableDisplayMode.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import Foundation

/// Defines how pinned tables are displayed in the SQL editor's empty state.
///
/// Used by ``SettingsViewModel`` to persist the user's preference and by
/// ``QueryEditorView`` to determine whether to show row data or column schema
/// for each pinned table.
enum PinnedTableDisplayMode: String, CaseIterable {

    /// Displays the first rows of the table's data.
    case data = "Data"

    /// Displays the table's column names and types.
    case structure = "Structure"
}
