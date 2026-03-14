//
//  PinnedTable.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import Foundation

/// Represents a database table that the user has pinned to the SQL editor's
/// empty state for quick reference.
///
/// Each pinned table stores its name and a snapshot of its data at the time
/// it was pinned. The data is read-only and does not modify the underlying
/// database table. Conforms to `Identifiable` for use in SwiftUI `ForEach`.
struct PinnedTable: Identifiable {

    /// Unique identifier derived from the table ``name``.
    let id: String

    /// The name of the database table.
    let name: String

    /// A snapshot of the table's row data at the time it was pinned.
    let data: QueryResult

    /// The table's column schema at the time it was pinned.
    let info: TableInfo

    /// Creates a new pinned table with the given name, data snapshot, and schema info.
    ///
    /// - Parameters:
    ///   - name: The name of the database table.
    ///   - data: The table's row data at the time of pinning.
    ///   - info: The table's column schema at the time of pinning.
    init(name: String, data: QueryResult, info: TableInfo) {
        self.id = name
        self.name = name
        self.data = data
        self.info = info
    }
}
