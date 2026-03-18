//
//  Exercise.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 18/03/26.
//

import Foundation

/// A single exercise within an ``ExerciseBlock``.
///
/// Each exercise presents one task to the user. The user writes a SQL query
/// whose output is compared against ``solutionSQL``'s output — if they match
/// row-for-row and column-for-column, the exercise is marked correct.
///
/// The `solutionSQL` is executed once (after the block's tables are seeded)
/// to pre-compute the expected ``QueryResult``, which is then cached by
/// ``ExercisesViewModel``.
struct Exercise: Identifiable {

    /// Unique identifier.
    let id = UUID()

    /// The display title shown in the navigation bar (e.g., "Dinosaurs 1").
    let title: String

    /// Short instructional text shown below the Run button,
    /// describing what the user must write.
    let instructions: String

    /// A canonical SQL query whose output defines the correct answer.
    /// Executed once against the live database to produce the expected result.
    let solutionSQL: String
}
