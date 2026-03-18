//
//  ExercisesViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 18/03/26.
//

import Foundation

/// Manages the seeding state, exercise validation, and block score persistence
/// for all exercise blocks in `app_database`.
///
/// Responsibilities:
/// - Check whether the tables required by a block already exist.
/// - Run the block's bundled JSON statements only if any required table is missing.
/// - Pre-compute the expected ``QueryResult`` for each exercise by running its
///   `solutionSQL` once against the live database after seeding completes.
/// - Expose per-block loading state so ``ExercisesView`` can block navigation
///   while seeding is in progress.
/// - Provide table data snapshots for the read-only preview inside exercises.
/// - Persist and expose the best score (0–100) achieved per block across sessions.
///
/// A single shared instance is created at app startup and injected into
/// ``ExercisesView`` and ``ExerciseDetailView``.
@Observable
@MainActor
final class ExercisesViewModel {

    // MARK: - Seeding State

    /// IDs of blocks whose tables are currently being seeded.
    private(set) var seedingBlockIDs: Set<UUID> = []

    /// IDs of blocks that have already been seeded (or verified) in this session.
    private(set) var seededBlockIDs: Set<UUID> = []

    /// Per-block error message, keyed by block ID, for UI display.
    private(set) var seedingErrors: [UUID: String] = [:]

    // MARK: - Exercise Expected Results

    /// Expected `QueryResult` keyed by exercise ID.
    /// Populated after the parent block's tables are seeded.
    private(set) var expectedResults: [UUID: QueryResult] = [:]

    // MARK: - Table Previews

    /// Table data snapshots for read-only display inside exercises, keyed by table name.
    private(set) var tablePreviewData: [String: QueryResult] = [:]

    // MARK: - Block Scores

    /// Best score (0–100) ever achieved for each block, keyed by block ID string.
    /// Loaded from and persisted to `UserDefaults`.
    private(set) var bestScores: [String: Int] = [:]

    private static let bestScoresKey = "exerciseBlockBestScores"

    // MARK: - Dependencies

    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
        self.bestScores = (UserDefaults.standard.dictionary(forKey: Self.bestScoresKey) as? [String: Int]) ?? [:]
    }

    // MARK: - Public Interface — Seeding

    /// Returns `true` while the given block's tables are being seeded.
    func isSeeding(_ block: ExerciseBlock) -> Bool {
        seedingBlockIDs.contains(block.id)
    }

    /// Returns `true` once the given block has been seeded (or verified) in this session.
    func isSeeded(_ block: ExerciseBlock) -> Bool {
        seededBlockIDs.contains(block.id)
    }

    /// Returns the seeding error for the given block, if any.
    func seedingError(for block: ExerciseBlock) -> String? {
        seedingErrors[block.id]
    }

    /// Returns the pre-computed expected result for the given exercise, if available.
    func expectedResult(for exercise: Exercise) -> QueryResult? {
        expectedResults[exercise.id]
    }

    /// Returns the cached table preview data for the given table name, if available.
    func previewData(for tableName: String) -> QueryResult? {
        tablePreviewData[tableName]
    }

    /// Ensures all tables required by `block` exist in `app_database`, then
    /// pre-computes expected results for every exercise and loads table previews.
    ///
    /// Safe to call multiple times — already-seeded blocks are skipped instantly.
    func seedTablesIfNeeded(for block: ExerciseBlock) async {
        guard !seededBlockIDs.contains(block.id),
              !seedingBlockIDs.contains(block.id) else { return }

        seedingBlockIDs.insert(block.id)
        seedingErrors.removeValue(forKey: block.id)

        do {
            let missingTables = try await findMissingTables(for: block)
            if !missingTables.isEmpty {
                try await runJSON(for: block)
            }
            await computeExpectedResults(for: block)
            await loadTablePreviews(for: block)
            seededBlockIDs.insert(block.id)
        } catch {
            seedingErrors[block.id] = error.localizedDescription
        }

        seedingBlockIDs.remove(block.id)
    }

    // MARK: - Public Interface — Validation

    /// Compares a user-submitted `QueryResult` against the pre-computed expected result
    /// for the given exercise.
    ///
    /// Comparison is structural: same column names (in order) and same rows (in order).
    /// Returns `nil` if the expected result has not been computed yet.
    func validate(_ userResult: QueryResult, for exercise: Exercise) -> Bool? {
        guard let expected = expectedResults[exercise.id] else { return nil }
        guard userResult.columns == expected.columns else { return false }
        guard userResult.rows.count == expected.rows.count else { return false }
        return zip(userResult.rows, expected.rows).allSatisfy { $0 == $1 }
    }

    // MARK: - Public Interface — Scores

    /// Returns the best score (0–100) ever recorded for the given block, or `nil`
    /// if the block has never been completed.
    func bestScore(for block: ExerciseBlock) -> Int? {
        bestScores[block.id.uuidString]
    }

    /// Records the result of a completed block attempt.
    ///
    /// Computes the score as the percentage of correct answers, then updates
    /// ``bestScores`` if this attempt beats the previous best.
    ///
    /// - Parameters:
    ///   - block: The block that was just completed.
    ///   - attempts: The ordered list of attempt records, one per exercise.
    func recordCompletion(for block: ExerciseBlock, attempts: [ExerciseAttemptRecord]) {
        let correct = attempts.filter(\.wasCorrect).count
        let total = attempts.count
        guard total > 0 else { return }

        let score = Int((Double(correct) / Double(total)) * 100)
        let key = block.id.uuidString
        let previous = bestScores[key] ?? -1

        if score > previous {
            bestScores[key] = score
            UserDefaults.standard.set(bestScores, forKey: Self.bestScoresKey)
        }
    }

    // MARK: - Private Helpers

    private func findMissingTables(for block: ExerciseBlock) async throws -> [String] {
        let existingTables = try await databaseService.listTables()
        let existingSet = Set(existingTables.map { $0.lowercased() })
        return block.tableNames.filter { !existingSet.contains($0.lowercased()) }
    }

    private func runJSON(for block: ExerciseBlock) async throws {
        guard let url = Bundle.main.url(
            forResource: block.jsonFileName,
            withExtension: "json"
        ) else {
            throw SeedingError.jsonFileNotFound(block.jsonFileName)
        }

        let data = try Data(contentsOf: url)
        let statements = try JSONDecoder().decode([String].self, from: data)

        for sql in statements {
            let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let upper = trimmed.uppercased()
            if upper.hasPrefix("SELECT") || upper.hasPrefix("PRAGMA") {
                _ = try await databaseService.executeQuery(trimmed)
            } else {
                _ = try await databaseService.executeNonQuery(trimmed)
            }
        }
    }

    private func computeExpectedResults(for block: ExerciseBlock) async {
        for exercise in block.exercises {
            guard expectedResults[exercise.id] == nil else { continue }
            do {
                let result = try await databaseService.executeQuery(exercise.solutionSQL)
                expectedResults[exercise.id] = result
            } catch {
                // Leave nil so validation returns nil — UI shows no verdict
            }
        }
    }

    private func loadTablePreviews(for block: ExerciseBlock) async {
        for tableName in block.tableNames {
            guard tablePreviewData[tableName] == nil else { continue }
            do {
                let data = try await databaseService.getTableData(tableName, limit: 200)
                tablePreviewData[tableName] = data
            } catch {
                // Non-fatal
            }
        }
    }

    // MARK: - Errors

    enum SeedingError: LocalizedError {
        case jsonFileNotFound(String)

        var errorDescription: String? {
            switch self {
            case .jsonFileNotFound(let name):
                return "Bundled file '\(name).json' not found."
            }
        }
    }
}
