//
//  ExerciseBlock.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 16/03/26.
//

import Foundation

/// Represents a block of 5 exercises that share the same table(s) in `app_database`.
///
/// Each block groups exercises by topic, showing which SQL keywords are introduced
/// and a brief description of the data being analyzed.
///
/// - `jsonFileName`: The name of the bundled JSON file (without `.json` extension)
///   whose SQL statements create and populate this block's required tables.
/// - `tableNames`: The exact table names that must exist in `app_database` before
///   the user may enter the block. Used to decide whether seeding is needed.
struct ExerciseBlock: Identifiable, Hashable {

    let id = UUID()

    /// Name of the image asset displayed on the card (square, small).
    let imageName: String

    /// SQL keywords introduced for the first time in this block.
    let sqlKeywords: [String]

    /// A short summary describing the data and queries in this block.
    let summary: String

    /// The exact table names that must exist in `app_database` before the user
    /// can enter this block. If any of these are missing, the JSON is re-executed.
    let tableNames: [String]

    /// The name of the bundled JSON file (without extension) containing the SQL
    /// statements to create and populate this block's tables.
    let jsonFileName: String

    /// The ordered list of exercises in this block. Typically 5 exercises.
    let exercises: [Exercise]

    /// Display title for the block (derived from the table names).
    var title: String {
        tableNames.joined(separator: ", ")
    }

    // MARK: - Hashable

    static func == (lhs: ExerciseBlock, rhs: ExerciseBlock) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
