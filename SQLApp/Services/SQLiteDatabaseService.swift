import Foundation
import SQLite3

final class SQLiteDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private nonisolated(unsafe) var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.sqlapp.database", qos: .userInitiated)

    // MARK: - Initialization

    nonisolated init(databaseName: String = "SQLApp.sqlite") {
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
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    // MARK: - Private Helpers

    /// Runs a closure on the serial queue, bridged to async/await.
    /// The closure receives the database pointer directly, avoiding Sendable capture issues.
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

    nonisolated func listTables() async throws -> [String] {
        let result = try await executeQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
        return result.rows.map { $0[0] }
    }

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

    nonisolated func getTableData(_ tableName: String, limit: Int = 100) async throws -> QueryResult {
        try await executeQuery("SELECT * FROM \(tableName) LIMIT \(limit)")
    }
}
