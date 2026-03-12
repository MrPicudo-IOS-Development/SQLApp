import Foundation

enum DatabaseError: Error, LocalizedError {
    case connectionFailed(String)
    case queryFailed(String)
    case prepareFailed(String)
    case databaseNotOpen

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
