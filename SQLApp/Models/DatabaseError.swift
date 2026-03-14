//
//  DatabaseError.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Represents all possible errors that can occur during database operations.
///
/// Each case carries a descriptive message from the SQLite engine when available,
/// providing context for debugging and user-facing error displays.
/// Conforms to `LocalizedError` so that `localizedDescription` returns
/// a human-readable message suitable for display in the UI.
enum DatabaseError: Error, LocalizedError {

    /// The database connection could not be established.
    /// - Parameter message: The underlying SQLite error message describing why the connection failed.
    case connectionFailed(String)

    /// A SQL statement execution failed at runtime.
    /// - Parameter message: The underlying SQLite error message describing the query failure.
    case queryFailed(String)

    /// A SQL statement could not be compiled (prepared) by SQLite.
    /// - Parameter message: The underlying SQLite error message describing the preparation failure.
    case prepareFailed(String)

    /// An operation was attempted on a database that is not currently open.
    case databaseNotOpen

    /// A localized description of the error suitable for display to the user.
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            "Connection failed: \(message)"
        case .queryFailed(let message):
            "Query failed: \(message)"
        case .prepareFailed(let message):
            "Prepare failed: \(message)"
        case .databaseNotOpen:
            "Database is not open."
        }
    }
}
