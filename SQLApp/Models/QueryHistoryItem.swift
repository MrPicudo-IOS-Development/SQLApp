import Foundation

struct QueryHistoryItem: Identifiable, Sendable {
    let id: UUID
    let sql: String
    let executedAt: Date
    let wasSuccessful: Bool
    let rowsAffected: Int?
    let errorMessage: String?

    init(
        sql: String,
        wasSuccessful: Bool,
        rowsAffected: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.id = UUID()
        self.sql = sql
        self.executedAt = Date()
        self.wasSuccessful = wasSuccessful
        self.rowsAffected = rowsAffected
        self.errorMessage = errorMessage
    }
}
