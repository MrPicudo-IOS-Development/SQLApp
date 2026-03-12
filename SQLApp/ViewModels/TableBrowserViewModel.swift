import Foundation

@Observable
final class TableBrowserViewModel {

    // MARK: - State

    var tables: [String] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Actions

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

    func getTableInfo(_ tableName: String) async throws -> TableInfo {
        try await databaseService.getTableInfo(tableName)
    }

    func getTableData(_ tableName: String) async throws -> QueryResult {
        try await databaseService.getTableData(tableName, limit: 200)
    }
}
