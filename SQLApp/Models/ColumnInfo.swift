//
//  ColumnInfo.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Represents the schema definition of a single column within a database table.
///
/// The values correspond to the output of SQLite's `PRAGMA table_info()` command.
/// Used within ``TableInfo`` to describe the structure of a table
/// in the table browser detail view.
///
/// Conforms to `Sendable` to allow safe transfer across actor boundaries.
struct ColumnInfo: Identifiable, Sendable {

    /// Unique identifier for the column, derived from its ``name``.
    var id: String { name }

    /// The column name as defined in the `CREATE TABLE` statement.
    let name: String

    /// The declared data type of the column (e.g., `TEXT`, `INTEGER`, `REAL`).
    let type: String

    /// Whether the column has a `NOT NULL` constraint.
    let isNotNull: Bool

    /// Whether the column is part of the table's primary key.
    let isPrimaryKey: Bool

    /// The default value for the column, or `nil` if none is defined.
    let defaultValue: String?
}
