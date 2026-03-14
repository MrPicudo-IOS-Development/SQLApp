//
//  QueryHistoryItem.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Records a previously executed SQL query along with its outcome.
///
/// Each item captures the SQL text, a timestamp, and whether the execution
/// succeeded or failed. Used by ``QueryEditorViewModel`` to maintain
/// an in-memory history of all queries executed during the session.
///
/// Conforms to `Sendable` to allow safe transfer across actor boundaries.
struct QueryHistoryItem: Identifiable, Sendable {

    /// A unique identifier for this history entry.
    let id: UUID

    /// The SQL statement that was executed.
    let sql: String

    /// The date and time when the query was executed.
    let executedAt: Date

    /// Whether the query executed without errors.
    let wasSuccessful: Bool

    /// The number of rows affected (for non-query statements) or returned (for queries).
    /// `nil` if the execution failed before a count could be determined.
    let rowsAffected: Int?

    /// The error message if the query failed, or `nil` if it succeeded.
    let errorMessage: String?

    /// Creates a new history item with the current timestamp and an auto-generated identifier.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement that was executed.
    ///   - wasSuccessful: Whether the query executed without errors.
    ///   - rowsAffected: The number of rows affected or returned. Defaults to `nil`.
    ///   - errorMessage: The error message if execution failed. Defaults to `nil`.
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
