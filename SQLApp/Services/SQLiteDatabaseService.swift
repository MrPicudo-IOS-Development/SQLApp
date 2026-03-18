//
//  SQLiteDatabaseService.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation
import SQLite3

/// Concrete implementation of ``DatabaseServiceProtocol`` using the SQLite3 C API.
///
/// This service manages a single SQLite database connection and provides
/// thread-safe access through a private serial `DispatchQueue`. All database
/// operations are dispatched to this queue and bridged to Swift's `async/await`
/// concurrency model via `withCheckedThrowingContinuation`.
///
/// The database file is stored in the app's Documents directory and persists
/// across app launches.
///
/// - Important: Marked as `@unchecked Sendable` because thread safety is
///   manually guaranteed through the serial dispatch queue. The `db` pointer
///   is only accessed within the serial queue or during initialization/deinitialization.
final class SQLiteDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// The SQLite database connection pointer. Accessed only from the serial ``queue``.
    private nonisolated(unsafe) var db: OpaquePointer?

    /// Serial dispatch queue that serializes all SQLite operations for thread safety.
    /// The label includes the database filename for debugging clarity when multiple instances exist.
    private let queue: DispatchQueue

    // MARK: - Initialization

    /// Creates a new database service and opens (or creates) the SQLite database file.
    ///
    /// The database file is placed in the app's Documents directory. If the file
    /// does not exist, SQLite creates it automatically.
    ///
    /// - Parameters:
    ///   - databaseName: The filename for the SQLite database. Defaults to `"user_database.sqlite"`.
    ///   - enableHistory: Whether to create the internal `_query_history` table.
    ///     Pass `false` for databases that don't need query history (e.g. the app exercise database).
    nonisolated init(databaseName: String = "user_database.sqlite", enableHistory: Bool = true) {
        self.queue = DispatchQueue(label: "com.sqlapp.database.\(databaseName)", qos: .userInitiated)

        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let databasePath = documentsURL.appendingPathComponent(databaseName).path

        if sqlite3_open(databasePath, &db) != SQLITE_OK {
            let errorMessage = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            print("Error opening database: \(errorMessage)")
            db = nil
        }

        // Create the internal history table only for user-facing databases.
        if enableHistory, let db {
            let createHistorySQL = """
                CREATE TABLE IF NOT EXISTS _query_history (
                    id TEXT PRIMARY KEY,
                    sql TEXT NOT NULL,
                    executed_at REAL NOT NULL,
                    was_successful INTEGER NOT NULL,
                    rows_affected INTEGER,
                    error_message TEXT
                )
                """
            sqlite3_exec(db, createHistorySQL, nil, nil, nil)
        }
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    // MARK: - Private Helpers

    /// Bridges a synchronous closure to `async/await` by dispatching it on the serial queue.
    ///
    /// This method ensures all SQLite operations run on the same serial queue,
    /// preventing concurrent access to the database pointer. The closure receives
    /// the database pointer as a parameter to avoid `Sendable` capture issues
    /// with `OpaquePointer`.
    ///
    /// - Parameter work: A closure that receives the SQLite database pointer
    ///   and performs a database operation. The closure runs on the serial queue.
    /// - Returns: The value produced by the closure.
    /// - Throws: Any error thrown by the closure.
    private nonisolated func performOnQueue<T: Sendable>(
        _ work: @escaping (OpaquePointer?) throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                do {
                    let result = try work(self.db)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - DatabaseServiceProtocol

    /// Executes a non-query SQL statement using `sqlite3_exec`.
    ///
    /// Suitable for `CREATE`, `INSERT`, `UPDATE`, `DELETE`, and `DROP` statements.
    /// Uses `sqlite3_exec` for simplicity since no result rows are expected.
    ///
    /// - Parameter sql: The SQL statement to execute.
    /// - Returns: The number of rows affected by the statement, as reported by `sqlite3_changes`.
    /// - Throws: ``DatabaseError/databaseNotOpen`` if the connection is `nil`,
    ///   or ``DatabaseError/queryFailed(_:)`` if `sqlite3_exec` returns an error.
    nonisolated func executeNonQuery(_ sql: String) async throws -> Int {
        try await performOnQueue { db in
            guard let db else { throw DatabaseError.databaseNotOpen }

            var errorPointer: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(db, sql, nil, nil, &errorPointer)

            if result != SQLITE_OK {
                let message = errorPointer.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorPointer)
                throw DatabaseError.queryFailed(message)
            }

            return Int(sqlite3_changes(db))
        }
    }

    /// Executes a `SELECT` query using the prepare/step/finalize pattern.
    ///
    /// The method compiles the SQL into a prepared statement, extracts column names,
    /// then iterates through result rows converting all values to their string representation.
    /// `NULL` values are represented as the string `"NULL"`.
    ///
    /// - Parameter sql: The SQL `SELECT` statement or `PRAGMA` command to execute.
    /// - Returns: A ``QueryResult`` containing the column names and all result rows.
    /// - Throws: ``DatabaseError/databaseNotOpen`` if the connection is `nil`,
    ///   or ``DatabaseError/prepareFailed(_:)`` if the statement cannot be compiled.
    nonisolated func executeQuery(_ sql: String) async throws -> QueryResult {
        try await performOnQueue { db in
            guard let db else { throw DatabaseError.databaseNotOpen }

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.prepareFailed(message)
            }
            defer { sqlite3_finalize(statement) }

            let columnCount = sqlite3_column_count(statement)
            var columns: [String] = []
            for i in 0..<columnCount {
                let name = sqlite3_column_name(statement, i)
                    .map { String(cString: $0) } ?? "column_\(i)"
                columns.append(name)
            }

            var rows: [[String]] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String] = []
                for i in 0..<columnCount {
                    if let text = sqlite3_column_text(statement, i) {
                        row.append(String(cString: text))
                    } else {
                        row.append("NULL")
                    }
                }
                rows.append(row)
            }

            return QueryResult(columns: columns, rows: rows)
        }
    }

    /// Lists all user-created tables by querying `sqlite_master`.
    ///
    /// Filters out internal SQLite tables (those prefixed with `sqlite_`)
    /// and returns the results sorted alphabetically.
    ///
    /// - Returns: An array of table name strings.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    nonisolated func listTables() async throws -> [String] {
        let result = try await executeQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '\\_%' ESCAPE '\\' ORDER BY name"
        )
        return result.rows.map { $0[0] }
    }

    /// Retrieves schema information for a table using `PRAGMA table_info`.
    ///
    /// The PRAGMA returns columns: `cid`, `name`, `type`, `notnull`, `dflt_value`, `pk`.
    /// These are mapped to a ``TableInfo`` instance with ``ColumnInfo`` entries.
    ///
    /// - Parameter tableName: The name of the table to inspect.
    /// - Returns: A ``TableInfo`` instance describing the table's columns and constraints.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    nonisolated func getTableInfo(_ tableName: String) async throws -> TableInfo {
        let result = try await executeQuery("PRAGMA table_info(\(tableName))")
        let columns = result.rows.map { row in
            ColumnInfo(
                name: row[1],
                type: row[2],
                isNotNull: row[3] == "1",
                isPrimaryKey: row[5] == "1",
                defaultValue: row[4] == "NULL" ? nil : row[4]
            )
        }
        return TableInfo(id: tableName, name: tableName, columns: columns)
    }

    /// Retrieves row data from a table with a configurable row limit.
    ///
    /// Executes `SELECT * FROM <tableName> LIMIT <limit>` to fetch a bounded
    /// number of rows for the table browser.
    ///
    /// - Parameters:
    ///   - tableName: The name of the table to query.
    ///   - limit: The maximum number of rows to return. Defaults to `100`.
    /// - Returns: A ``QueryResult`` containing column names and row data.
    /// - Throws: ``DatabaseError`` if the underlying query fails.
    nonisolated func getTableData(_ tableName: String, limit: Int = 100) async throws -> QueryResult {
        try await executeQuery("SELECT * FROM \(tableName) LIMIT \(limit)")
    }

    // MARK: - Query History Persistence

    /// Inserts a query history item into the `_query_history` table.
    nonisolated func saveHistoryItem(_ item: QueryHistoryItem) async throws {
        try await performOnQueue { db in
            guard let db else { throw DatabaseError.databaseNotOpen }

            let sql = """
                INSERT INTO _query_history (id, sql, executed_at, was_successful, rows_affected, error_message)
                VALUES (?, ?, ?, ?, ?, ?)
                """

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.prepareFailed(message)
            }
            defer { sqlite3_finalize(statement) }

            // SQLITE_TRANSIENT tells SQLite to copy the string immediately,
            // so the pointer does not need to outlive the bind call.
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

            let idString = item.id.uuidString
            sqlite3_bind_text(statement, 1, idString, -1, transient)
            sqlite3_bind_text(statement, 2, item.sql, -1, transient)
            sqlite3_bind_double(statement, 3, item.executedAt.timeIntervalSince1970)
            sqlite3_bind_int(statement, 4, item.wasSuccessful ? 1 : 0)

            if let rows = item.rowsAffected {
                sqlite3_bind_int(statement, 5, Int32(rows))
            } else {
                sqlite3_bind_null(statement, 5)
            }

            if let error = item.errorMessage {
                sqlite3_bind_text(statement, 6, error, -1, transient)
            } else {
                sqlite3_bind_null(statement, 6)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                let message = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.queryFailed(message)
            }
        }
    }

    /// Loads all history items from the `_query_history` table, newest first.
    nonisolated func loadHistory() async throws -> [QueryHistoryItem] {
        try await performOnQueue { db in
            guard let db else { throw DatabaseError.databaseNotOpen }

            let sql = "SELECT id, sql, executed_at, was_successful, rows_affected, error_message FROM _query_history ORDER BY executed_at DESC"

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.prepareFailed(message)
            }
            defer { sqlite3_finalize(statement) }

            var items: [QueryHistoryItem] = []

            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? ""
                let sqlText = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                let executedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
                let wasSuccessful = sqlite3_column_int(statement, 3) == 1

                let rowsAffected: Int? = sqlite3_column_type(statement, 4) != SQLITE_NULL
                    ? Int(sqlite3_column_int(statement, 4))
                    : nil

                let errorMessage: String? = sqlite3_column_type(statement, 5) != SQLITE_NULL
                    ? sqlite3_column_text(statement, 5).map { String(cString: $0) }
                    : nil

                if let uuid = UUID(uuidString: idString) {
                    let item = QueryHistoryItem(
                        id: uuid,
                        sql: sqlText,
                        executedAt: executedAt,
                        wasSuccessful: wasSuccessful,
                        rowsAffected: rowsAffected,
                        errorMessage: errorMessage
                    )
                    items.append(item)
                }
            }

            return items
        }
    }

    /// Deletes all rows from the `_query_history` table.
    nonisolated func clearHistory() async throws {
        _ = try await performOnQueue { db in
            guard let db else { throw DatabaseError.databaseNotOpen }

            var errorPointer: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(db, "DELETE FROM _query_history", nil, nil, &errorPointer)

            if result != SQLITE_OK {
                let message = errorPointer.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorPointer)
                throw DatabaseError.queryFailed(message)
            }
        }
    }
}
