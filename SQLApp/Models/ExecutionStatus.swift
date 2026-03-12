import Foundation

enum ExecutionStatus: Equatable {
    case idle
    case success(Int)
    case error(Int)
}
