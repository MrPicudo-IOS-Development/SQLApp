//
//  QueryEditorViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// ViewModel that manages the state and business logic for the SQL editor screen.
///
/// Handles SQL text input, query execution (distinguishing between `SELECT` queries
/// and non-query statements), result management, execution history, and feedback
/// status for haptic triggers. Depends on ``DatabaseServiceProtocol`` for all
/// database operations (Dependency Inversion Principle).
///
/// Uses the `@Observable` macro for automatic SwiftUI view tracking without
/// requiring `@Published` property wrappers.
@Observable
@MainActor
final class QueryEditorViewModel {

    // MARK: - State

    /// The current SQL text entered by the user in the editor.
    var sqlText: String = ""

    /// The result of the last `SELECT` query, or `nil` if no query result is available.
    var queryResult: QueryResult?

    /// The error message from the last failed execution, or `nil` if the last execution succeeded.
    var errorMessage: String?

    /// Whether a query is currently being executed. Drives the progress indicator in the UI.
    var isExecuting: Bool = false

    /// A human-readable summary of the last execution (e.g., "3 row(s) returned").
    var executionMessage: String?

    /// An in-memory history of all queries executed during the current session, newest first.
    var queryHistory: [QueryHistoryItem] = []

    /// The outcome of the last execution, used as a trigger for haptic feedback.
    /// The associated counter ensures the trigger fires on consecutive same-type outcomes.
    var executionStatus: ExecutionStatus = .idle

    /// The tables the user has pinned to the editor's empty state for quick reference.
    /// Each entry contains the table name and a snapshot of its data at the time of pinning.
    var pinnedTables: [PinnedTable] = []

    /// The list of available table names for pinning, excluding already-pinned tables.
    /// Loaded on demand each time the user opens the table picker.
    var availableTablesForPinning: [String] = []

    /// Whether the table selection sheet is currently presented.
    var isShowingTablePicker: Bool = false

    /// Whether the available tables list is currently being loaded from the database.
    var isLoadingTables: Bool = false

    // MARK: - Dependencies

    /// The database service used to execute all SQL operations.
    private let databaseService: any DatabaseServiceProtocol

    /// Monotonically increasing counter to ensure ``executionStatus`` changes
    /// are detected by SwiftUI's `.sensoryFeedback` modifier on every execution.
    private var feedbackCounter = 0

    // MARK: - Initialization

    /// Creates a new ViewModel with the given database service.
    ///
    /// - Parameter databaseService: The service used to execute SQL statements against the database.
    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Actions

    /// Executes the current SQL text against the database.
    ///
    /// Determines whether the statement is a query (`SELECT` / `PRAGMA`) or a non-query
    /// (`CREATE`, `INSERT`, `UPDATE`, `DELETE`, `DROP`) by checking the uppercased prefix.
    /// Updates ``queryResult``, ``executionMessage``, ``errorMessage``, and ``executionStatus``
    /// based on the outcome, and appends the result to ``queryHistory``.
    ///
    /// This method is safe to call from SwiftUI button actions wrapped in a `Task`.
    func executeSQL() async {
        let trimmed = sqlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isExecuting = true
        errorMessage = nil
        queryResult = nil
        executionMessage = nil

        do {
            let uppercased = trimmed.uppercased()
            let isQuery = uppercased.hasPrefix("SELECT") || uppercased.hasPrefix("PRAGMA")

            if isQuery {
                let result = try await databaseService.executeQuery(trimmed)
                queryResult = result
                executionMessage = "\(result.rowCount) row(s) returned"
                addToHistory(sql: trimmed, success: true, rows: result.rowCount)
                try? await databaseService.saveHistoryItem(
                    QueryHistoryItem(sql: trimmed, wasSuccessful: true, rowsAffected: result.rowCount)
                )
            } else {
                let affected = try await databaseService.executeNonQuery(trimmed)
                executionMessage = "\(affected) row(s) affected"
                addToHistory(sql: trimmed, success: true, rows: affected)
                try? await databaseService.saveHistoryItem(
                    QueryHistoryItem(sql: trimmed, wasSuccessful: true, rowsAffected: affected)
                )
            }
            feedbackCounter += 1
            executionStatus = .success(feedbackCounter)
            pinnedTables.removeAll()
        } catch {
            errorMessage = error.localizedDescription
            addToHistory(sql: trimmed, success: false, errorMsg: error.localizedDescription)
            feedbackCounter += 1
            executionStatus = .error(feedbackCounter)
        }

        isExecuting = false
    }

    /// Clears the current query result, error message, and execution message.
    ///
    /// Resets the results section to the empty "No Results" state without
    /// affecting the SQL text or query history.
    func clearResults() {
        queryResult = nil
        errorMessage = nil
        executionMessage = nil
    }

    /// Directly sets the displayed query result without executing any SQL.
    ///
    /// Used to show the pre-computed solution result when the user taps
    /// "Show Result" in ``ExerciseDetailView``. Does not affect query history.
    ///
    /// - Parameter result: The ``QueryResult`` to display.
    func setResult(_ result: QueryResult) {
        queryResult = result
        errorMessage = nil
        executionMessage = nil
    }

    /// Loads a previously executed query from history into the SQL editor.
    ///
    /// - Parameter item: The history item whose SQL text should be loaded into the editor.
    func loadHistoryItem(_ item: QueryHistoryItem) {
        sqlText = item.sql
    }

    /// Loads the list of available tables from the database, excluding already-pinned tables.
    ///
    /// Called when the user taps the "Pin Table" button, just before presenting the
    /// table picker sheet. Filters out any table names already present in ``pinnedTables``.
    func loadAvailableTables() async {
        isLoadingTables = true
        do {
            let allTables = try await databaseService.listTables()
            let pinnedNames = Set(pinnedTables.map(\.name))
            availableTablesForPinning = allTables.filter { !pinnedNames.contains($0) }
        } catch {
            availableTablesForPinning = []
        }
        isLoadingTables = false
    }

    /// Pins a table by loading its data and adding it to ``pinnedTables``.
    ///
    /// After pinning, the table is removed from ``availableTablesForPinning`` so it
    /// cannot be pinned a second time. The table picker sheet is dismissed automatically.
    ///
    /// - Parameters:
    ///   - tableName: The name of the table to pin.
    ///   - rowLimit: The maximum number of rows to load for the pinned table preview.
    func pinTable(_ tableName: String, rowLimit: Int) async {
        do {
            let data = try await databaseService.getTableData(tableName, limit: rowLimit)
            let info = try await databaseService.getTableInfo(tableName)
            let pinned = PinnedTable(name: tableName, data: data, info: info)
            pinnedTables.append(pinned)
            availableTablesForPinning.removeAll { $0 == tableName }
        } catch {
            // The table picker remains open for retry
        }
        isShowingTablePicker = false
    }

    /// Removes a pinned table from the display without affecting the database.
    ///
    /// - Parameter pinnedTable: The pinned table to remove.
    func unpinTable(_ pinnedTable: PinnedTable) {
        pinnedTables.removeAll { $0.id == pinnedTable.id }
    }

    // MARK: - Direct Execution

    /// Executes a SELECT/PRAGMA query directly without updating the editor's UI state.
    ///
    /// Used for batch operations (e.g., loading tables from JSON) where the caller
    /// manages its own progress and error display.
    ///
    /// - Parameter sql: The SQL query to execute.
    /// - Returns: The ``QueryResult`` from the query.
    @discardableResult
    func executeDirect(_ sql: String) async throws -> QueryResult {
        try await databaseService.executeQuery(sql)
    }

    /// Executes a non-query SQL statement directly without updating the editor's UI state.
    ///
    /// Used for batch operations (e.g., loading tables from JSON) where the caller
    /// manages its own progress and error display.
    ///
    /// - Parameter sql: The SQL statement to execute.
    /// - Returns: The number of rows affected.
    @discardableResult
    func executeNonQueryDirect(_ sql: String) async throws -> Int {
        try await databaseService.executeNonQuery(sql)
    }

    // MARK: - Private

    /// Creates a ``QueryHistoryItem`` and inserts it at the beginning of the history array.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement that was executed.
    ///   - success: Whether the execution completed without errors.
    ///   - rows: The number of rows affected or returned. Defaults to `nil`.
    ///   - errorMsg: The error description if execution failed. Defaults to `nil`.
    private func addToHistory(sql: String, success: Bool, rows: Int? = nil, errorMsg: String? = nil) {
        let item = QueryHistoryItem(
            sql: sql,
            wasSuccessful: success,
            rowsAffected: rows,
            errorMessage: errorMsg
        )
        queryHistory.insert(item, at: 0)
    }
}
