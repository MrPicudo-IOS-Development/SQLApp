//
//  TableSummary.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 15/03/26.
//

import Foundation

/// A lightweight summary of a database table used for display in the table card list.
///
/// Contains the table name along with its column and row counts, avoiding the need
/// to load full schema or data when browsing tables in ``DatabaseView``.
struct TableSummary: Identifiable, Sendable {
    /// The unique identifier for this summary, equal to the table name.
    let id: String
    /// The name of the database table.
    let name: String
    /// The number of columns defined in the table schema.
    let columnCount: Int
    /// The total number of rows currently stored in the table.
    let rowCount: Int
}
