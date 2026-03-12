import Foundation

/// Represents the result of a SQL `SELECT` query execution.
///
/// Contains the column names returned by the query and each row's values
/// as string representations. All values are stored as `String` since
/// SQLite returns text-based results and this type is used primarily
/// for display purposes.
///
/// Conforms to `Sendable` to allow safe transfer across actor boundaries
/// (from the background database queue to the main actor).
struct QueryResult: Sendable {

    /// The names of the columns returned by the query, in order.
    let columns: [String]

    /// The row data returned by the query. Each inner array corresponds
    /// to one row, with values aligned to the ``columns`` array by index.
    let rows: [[String]]

    /// Whether the query returned zero rows.
    var isEmpty: Bool { rows.isEmpty }

    /// The total number of rows returned by the query.
    var rowCount: Int { rows.count }

    /// The total number of columns returned by the query.
    var columnCount: Int { columns.count }
}
