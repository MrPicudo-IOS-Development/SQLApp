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
            } else {
                let affected = try await databaseService.executeNonQuery(trimmed)
                executionMessage = "\(affected) row(s) affected"
                addToHistory(sql: trimmed, success: true, rows: affected)
            }
            feedbackCounter += 1
            executionStatus = .success(feedbackCounter)
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

    /// Loads a previously executed query from history into the SQL editor.
    ///
    /// - Parameter item: The history item whose SQL text should be loaded into the editor.
    func loadHistoryItem(_ item: QueryHistoryItem) {
        sqlText = item.sql
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
