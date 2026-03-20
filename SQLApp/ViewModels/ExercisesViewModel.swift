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
/// - Persist and expose the best star count (0–5) achieved per block across sessions.
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

    /// Table structure (column definitions) for exercises, keyed by table name.
    private(set) var tableStructureData: [String: TableInfo] = [:]

    // MARK: - In-Progress ViewModels

    /// Cached ``ExerciseDetailViewModel`` instances keyed by block ID.
    /// Preserves in-progress exercise state when the user navigates back
    /// to the block list without finishing all exercises.
    private var cachedDetailViewModels: [UUID: ExerciseDetailViewModel] = [:]

    // MARK: - Block Scores

    /// Best star count (0–5) ever achieved for each block, keyed by block `stableID`.
    /// Each star represents one correct exercise out of 5.
    /// Loaded from and persisted to the `_exercise_scores` table in `app_database`.
    private(set) var bestScores: [String: Int] = [:]

    /// Whether scores have been loaded from the database at least once.
    private var scoresLoaded = false

    // MARK: - Dependencies

    private let databaseService: any DatabaseServiceProtocol

    // MARK: - Initialization

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    /// Loads persisted scores from the database. Called once when the Exercises tab appears.
    func loadScoresIfNeeded() async {
        guard !scoresLoaded else { return }
        do {
            bestScores = try await databaseService.loadScores()
        } catch {
            // Non-fatal: scores default to empty, user can still play.
        }
        scoresLoaded = true
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

    /// Returns the cached table structure for the given table name, if available.
    func structureInfo(for tableName: String) -> TableInfo? {
        tableStructureData[tableName]
    }

    /// Ensures all tables required by `block` exist in `app_database` and contain
    /// data, then pre-computes expected results for every exercise and loads table
    /// previews.
    ///
    /// Safe to call multiple times — already-seeded blocks are skipped instantly.
    /// If a required table exists but is empty (e.g. interrupted seeding), it is
    /// dropped and the JSON is re-executed.
    func seedTablesIfNeeded(for block: ExerciseBlock) async {
        guard !seededBlockIDs.contains(block.id),
              !seedingBlockIDs.contains(block.id) else { return }

        seedingBlockIDs.insert(block.id)
        seedingErrors.removeValue(forKey: block.id)

        do {
            let needsSeeding = try await tablesNeedSeeding(for: block)
            if needsSeeding {
                try await runJSON(for: block)
            }
            await computeExpectedResults(for: block)
            await loadTablePreviews(for: block)
            await loadTableStructures(for: block)
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

    /// Returns the best star count (0–5) ever recorded for the given block, or `nil`
    /// if the block has never been completed.
    func bestStars(for block: ExerciseBlock) -> Int? {
        bestScores[block.stableID]
    }

    /// Records the result of a completed block attempt.
    ///
    /// Counts the number of correct answers (0–5) as the star count, then updates
    /// ``bestScores`` only if this attempt beats the previous best (or if there was
    /// no previous score). Also clears the cached ViewModel for the block so
    /// that subsequent entries start fresh.
    ///
    /// - Parameters:
    ///   - block: The block that was just completed.
    ///   - attempts: The ordered list of attempt records, one per exercise.
    func recordCompletion(for block: ExerciseBlock, attempts: [ExerciseAttemptRecord]) {
        let correct = attempts.filter(\.wasCorrect).count
        guard !attempts.isEmpty else { return }

        let key = block.stableID
        let previous = bestScores[key] ?? -1

        if correct > previous {
            bestScores[key] = correct
            Task {
                try? await databaseService.saveScore(blockID: key, stars: correct)
            }
        }

        // Clear cached ViewModel so the next entry starts fresh.
        cachedDetailViewModels.removeValue(forKey: block.id)
    }

    /// Returns a cached ``ExerciseDetailViewModel`` for the given block,
    /// creating one if it doesn't exist yet. This preserves in-progress
    /// exercise state when the user navigates away and back.
    func detailViewModel(
        for block: ExerciseBlock,
        queryEditorViewModel: QueryEditorViewModel
    ) -> ExerciseDetailViewModel {
        if let existing = cachedDetailViewModels[block.id] {
            return existing
        }
        let vm = ExerciseDetailViewModel(
            block: block,
            queryEditorViewModel: queryEditorViewModel,
            exercisesViewModel: self
        )
        cachedDetailViewModels[block.id] = vm
        return vm
    }

    // MARK: - Private Helpers

    /// Returns `true` if any required table is missing or empty, meaning the
    /// block's JSON must be executed. Empty tables are dropped first so the
    /// JSON's `CREATE TABLE` statements succeed on re-seed.
    private func tablesNeedSeeding(for block: ExerciseBlock) async throws -> Bool {
        let existingTables = try await databaseService.listTables()
        let existingSet = Set(existingTables.map { $0.lowercased() })

        var needsSeeding = false
        for tableName in block.tableNames {
            if !existingSet.contains(tableName.lowercased()) {
                needsSeeding = true
            } else {
                // Table exists — verify it has rows.
                let result = try await databaseService.executeQuery(
                    "SELECT COUNT(*) FROM \(tableName)"
                )
                let count = result.rows.first.flatMap { Int($0[0]) } ?? 0
                if count == 0 {
                    // Empty table from an interrupted seed — drop so JSON can recreate it.
                    _ = try await databaseService.executeNonQuery("DROP TABLE IF EXISTS \(tableName)")
                    needsSeeding = true
                }
            }
        }
        return needsSeeding
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

    private func loadTableStructures(for block: ExerciseBlock) async {
        for tableName in block.tableNames {
            guard tableStructureData[tableName] == nil else { continue }
            do {
                let info = try await databaseService.getTableInfo(tableName)
                tableStructureData[tableName] = info
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
