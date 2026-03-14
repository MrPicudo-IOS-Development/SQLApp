//
//  ExecutionStatus.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Represents the outcome of the most recent SQL query execution.
///
/// Used as a trigger for SwiftUI's `.sensoryFeedback` modifier to provide
/// haptic feedback after query execution. The associated `Int` value is
/// a monotonically increasing counter that ensures the trigger fires
/// even on consecutive executions with the same outcome type.
enum ExecutionStatus: Equatable {

    /// No query has been executed yet.
    case idle

    /// The last query executed successfully.
    /// - Parameter counter: An incrementing value to guarantee trigger uniqueness.
    case success(Int)

    /// The last query execution failed.
    /// - Parameter counter: An incrementing value to guarantee trigger uniqueness.
    case error(Int)
}
