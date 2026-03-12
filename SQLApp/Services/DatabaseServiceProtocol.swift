import Foundation

protocol DatabaseServiceProtocol: Sendable {
    /// Execute a non-query statement (CREATE, INSERT, UPDATE, DELETE, DROP).
    /// Returns the number of rows affected.
    func executeNonQuery(_ sql: String) async throws -> Int

    /// Execute a SELECT query and return structured results.
    func executeQuery(_ sql: String) async throws -> QueryResult

    /// List all user-created tables in the database.
    func listTables() async throws -> [String]

    /// Get detailed info about a specific table (columns, types, constraints).
    func getTableInfo(_ tableName: String) async throws -> TableInfo

    /// Get all rows from a table with an optional row limit.
    func getTableData(_ tableName: String, limit: Int) async throws -> QueryResult
}
