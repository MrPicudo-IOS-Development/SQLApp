//
//  HistoryViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import Foundation

/// ViewModel that manages the persistent query history loaded from the database.
///
/// Provides loading and clearing of the `_query_history` table. Works alongside
/// ``TableBrowserViewModel`` (which handles the tables section) inside ``HistoryView``.
///
/// Uses the `@Observable` macro for automatic SwiftUI view tracking.
@Observable
@MainActor
final class HistoryViewModel {

    // MARK: - State

    /// The list of persisted query history items, ordered newest first.
    var history: [QueryHistoryItem] = []

    /// Whether the history is currently being loaded from the database.
    var isLoadingHistory: Bool = false

    /// The error message from the last failed load operation, or `nil` if loading succeeded.
    var historyError: String?

    // MARK: - Dependencies

    /// The database service used to read and write the `_query_history` table.
    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    /// Creates a new ViewModel with the given database service.
    ///
    /// - Parameter databaseService: The service used to persist and retrieve query history.
    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Actions

    /// Loads all persisted history items from the database, ordered by execution date (newest first).
    ///
    /// Updates ``history`` on success, or sets ``historyError`` on failure.
    /// Toggles ``isLoadingHistory`` to drive the loading indicator in the UI.
    func loadHistory() async {
        isLoadingHistory = true
        historyError = nil
        do {
            history = try await databaseService.loadHistory()
        } catch {
            historyError = error.localizedDescription
        }
        isLoadingHistory = false
    }

    /// Deletes all persisted history items from the database and clears the in-memory array.
    func clearHistory() async {
        do {
            try await databaseService.clearHistory()
            history = []
        } catch {
            historyError = error.localizedDescription
        }
    }
}
