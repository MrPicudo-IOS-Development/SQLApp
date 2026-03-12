import Foundation

@Observable
final class QueryEditorViewModel {

    // MARK: - State

    var sqlText: String = ""
    var queryResult: QueryResult?
    var errorMessage: String?
    var isExecuting: Bool = false
    var executionMessage: String?
    var queryHistory: [QueryHistoryItem] = []
    var executionStatus: ExecutionStatus = .idle

    // MARK: - Dependencies

    private let databaseService: any DatabaseServiceProtocol
    private var feedbackCounter = 0

    // MARK: - Initialization

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Actions

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

    func clearResults() {
        queryResult = nil
        errorMessage = nil
        executionMessage = nil
    }

    func loadHistoryItem(_ item: QueryHistoryItem) {
        sqlText = item.sql
    }

    // MARK: - Private

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
