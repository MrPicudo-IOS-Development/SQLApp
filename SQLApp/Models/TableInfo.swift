//
//  TableInfo.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Represents metadata about a database table, including its name and column definitions.
///
/// Used by the table browser to display the schema of a user-created table.
/// The ``id`` property is set to the table name to satisfy `Identifiable`,
/// enabling direct usage in SwiftUI `List` and `ForEach`.
///
/// Conforms to `Sendable` to allow safe transfer across actor boundaries.
struct TableInfo: Identifiable, Sendable {

    /// Unique identifier for the table, equal to the table ``name``.
    let id: String

    /// The name of the database table as defined in SQLite.
    let name: String

    /// An ordered list of column definitions for this table.
    let columns: [ColumnInfo]
}
