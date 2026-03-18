//
//  TableBrowserViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// ViewModel that manages the state and business logic for the table browser screen.
///
/// Responsible for loading the list of user-created database tables and providing
/// on-demand access to table schema and data. Depends on ``DatabaseServiceProtocol``
/// for all database operations (Dependency Inversion Principle).
///
/// Uses the `@Observable` macro for automatic SwiftUI view tracking.
@Observable
@MainActor
final class TableBrowserViewModel {

    // MARK: - State

    /// The list of user-created table names currently in the database.
    var tables: [String] = []

    /// Summary information (name, column count, row count) for each user-created table.
    var tableSummaries: [TableSummary] = []

    /// Whether the table list is currently being loaded from the database.
    var isLoading: Bool = false

    /// The error message from the last failed load operation, or `nil` if loading succeeded.
    var errorMessage: String?

    // MARK: - Dependencies

    /// The database service used to query table metadata and data.
    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    /// Creates a new ViewModel with the given database service.
    ///
    /// - Parameter databaseService: The service used to query table information from the database.
    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Actions

    /// Loads the list of all user-created tables from the database.
    ///
    /// Updates ``tables`` on success, or sets ``errorMessage`` on failure.
    /// Toggles ``isLoading`` to drive the loading indicator in the UI.
    /// Called automatically when the table list view appears, and manually
    /// via the refresh button in the toolbar.
    func loadTables() async {
        isLoading = true
        errorMessage = nil
        do {
            tables = try await databaseService.listTables()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Loads summary information (column count and row count) for every table in ``tables``.
    ///
    /// Should be called after ``loadTables()`` so that the table names are available.
    /// For each table, uses `getTableInfo` for the column count and a `SELECT COUNT(*)`
    /// query for the row count.
    func loadTableSummaries() async {
        var summaries: [TableSummary] = []
        for tableName in tables {
            do {
                let info = try await databaseService.getTableInfo(tableName)
                let countResult = try await databaseService.executeQuery("SELECT COUNT(*) FROM \(tableName)")
                let rowCount = Int(countResult.rows.first?.first ?? "0") ?? 0
                summaries.append(TableSummary(
                    id: tableName,
                    name: tableName,
                    columnCount: info.columns.count,
                    rowCount: rowCount
                ))
            } catch {
                summaries.append(TableSummary(
                    id: tableName,
                    name: tableName,
                    columnCount: 0,
                    rowCount: 0
                ))
            }
        }
        tableSummaries = summaries
    }

    /// Retrieves the schema information for a specific table.
    ///
    /// This is a pass-through to the database service, allowing
    /// ``TableDetailView`` to load schema data on demand.
    ///
    /// - Parameter tableName: The name of the table to inspect.
    /// - Returns: A ``TableInfo`` instance with the table's column definitions.
    /// - Throws: ``DatabaseError`` if the query fails.
    func getTableInfo(_ tableName: String) async throws -> TableInfo {
        try await databaseService.getTableInfo(tableName)
    }

    /// Retrieves the row data for a specific table, limited to 200 rows.
    ///
    /// This is a pass-through to the database service, allowing
    /// ``TableDetailView`` to load table data on demand.
    ///
    /// - Parameter tableName: The name of the table to query.
    /// - Returns: A ``QueryResult`` containing the table's column names and row data.
    /// - Throws: ``DatabaseError`` if the query fails.
    func getTableData(_ tableName: String) async throws -> QueryResult {
        try await databaseService.getTableData(tableName, limit: 200)
    }
}
