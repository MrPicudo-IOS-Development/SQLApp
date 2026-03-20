//
//  TableDetailViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 19/03/26.
//

import Foundation

/// ViewModel that manages state and data loading for the table detail screen.
///
/// Encapsulates the asynchronous loading of table schema (``TableInfo``) and
/// row data (``QueryResult``) that was previously embedded in ``TableDetailView``.
/// Depends on ``DatabaseServiceProtocol`` for all database operations.
@Observable
@MainActor
final class TableDetailViewModel {

    // MARK: - Configuration

    /// The name of the table whose details are displayed.
    let tableName: String

    // MARK: - State

    /// The table's column definitions, loaded asynchronously on appearance.
    var tableInfo: TableInfo?

    /// The table's row data, loaded asynchronously on appearance.
    var tableData: QueryResult?

    /// An error message if loading the table details failed.
    var errorMessage: String?

    // MARK: - Dependencies

    /// The database service used to fetch schema and data.
    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    /// Creates a new ViewModel for a specific table.
    ///
    /// - Parameters:
    ///   - tableName: The name of the table to display.
    ///   - databaseService: The service used to query table information.
    init(tableName: String, databaseService: any DatabaseServiceProtocol) {
        self.tableName = tableName
        self.databaseService = databaseService
    }

    // MARK: - Actions

    /// Loads both the table schema and row data from the database.
    ///
    /// On failure, sets ``errorMessage`` to display an error state in the view.
    func loadDetails() async {
        do {
            tableInfo = try await databaseService.getTableInfo(tableName)
            tableData = try await databaseService.getTableData(tableName, limit: 200)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
