import Foundation

/// Defines the contract for all database operations in the application.
///
/// This protocol abstracts the data access layer, allowing ViewModels
/// to depend on this interface rather than a concrete implementation
/// (Dependency Inversion Principle). This enables easy substitution
/// for testing (mock implementations) or alternative storage backends.
///
/// All methods are `async throws` because database operations run
/// off the main actor and may fail due to SQL errors or connection issues.
///
/// Conforms to `Sendable` because instances are shared across actor boundaries.
protocol DatabaseServiceProtocol: Sendable {

    /// Executes a non-query SQL statement such as `CREATE`, `INSERT`, `UPDATE`, `DELETE`, or `DROP`.
    ///
    /// - Parameter sql: The SQL statement to execute. Must not be a `SELECT` query.
    /// - Returns: The number of rows affected by the statement.
    /// - Throws: ``DatabaseError/queryFailed(_:)`` if execution fails,
    ///   or ``DatabaseError/databaseNotOpen`` if the connection is unavailable.
    func executeNonQuery(_ sql: String) async throws -> Int

    /// Executes a `SELECT` query and returns its results as a structured ``QueryResult``.
    ///
    /// - Parameter sql: The SQL `SELECT` statement (or `PRAGMA`) to execute.
    /// - Returns: A ``QueryResult`` containing column names and row data.
    /// - Throws: ``DatabaseError/prepareFailed(_:)`` if the statement cannot be compiled,
    ///   or ``DatabaseError/databaseNotOpen`` if the connection is unavailable.
    func executeQuery(_ sql: String) async throws -> QueryResult

    /// Lists all user-created tables in the database.
    ///
    /// Excludes internal SQLite system tables (those prefixed with `sqlite_`).
    ///
    /// - Returns: An alphabetically sorted array of table names.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    func listTables() async throws -> [String]

    /// Retrieves detailed schema information for a specific table.
    ///
    /// Uses SQLite's `PRAGMA table_info()` to obtain column definitions
    /// including names, types, constraints, and default values.
    ///
    /// - Parameter tableName: The name of the table to inspect.
    /// - Returns: A ``TableInfo`` instance containing the table's column definitions.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    func getTableInfo(_ tableName: String) async throws -> TableInfo

    /// Retrieves row data from a specific table with an optional row limit.
    ///
    /// Executes `SELECT * FROM <tableName> LIMIT <limit>` to fetch table contents
    /// for browsing purposes.
    ///
    /// - Parameters:
    ///   - tableName: The name of the table to query.
    ///   - limit: The maximum number of rows to return.
    /// - Returns: A ``QueryResult`` containing the table's column names and row data.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    func getTableData(_ tableName: String, limit: Int) async throws -> QueryResult
}
