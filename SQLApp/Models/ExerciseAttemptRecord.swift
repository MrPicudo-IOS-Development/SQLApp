//
//  ExerciseAttemptRecord.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 18/03/26.
//

import Foundation

/// A single exercise attempt recorded during one pass through an ``ExerciseBlock``.
///
/// Collected in ``ExerciseDetailView`` as the user completes each exercise,
/// then passed to ``BlockResultsView`` to display the final summary.
struct ExerciseAttemptRecord: Identifiable, Hashable {

    let id = UUID()

    /// Display title of the exercise (e.g., "Dinosaurs 1").
    let exerciseTitle: String

    /// The last SQL query the user submitted (or the solution SQL if they used "Show Result").
    let queryUsed: String

    /// Whether the user's own answer was correct (`true`), or whether they had to
    /// use "Show Result" / skip (`false`).
    let wasCorrect: Bool
}
