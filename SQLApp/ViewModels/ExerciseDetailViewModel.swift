//
//  ExerciseDetailViewModel.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 19/03/26.
//

import Foundation

/// ViewModel that manages state and business logic for a single exercise block session.
///
/// Encapsulates exercise progression, query execution orchestration, solution reveal,
/// attempt recording, and score persistence that were previously embedded in
/// ``ExerciseDetailView``.
///
/// The query editor and exercises view model are received as dependencies so this
/// ViewModel can coordinate SQL execution and table seeding without owning them.
@Observable
@MainActor
final class ExerciseDetailViewModel {

    // MARK: - Dependencies

    /// The exercise block being practiced.
    let block: ExerciseBlock

    /// The query editor ViewModel for SQL execution and result display.
    var queryEditorViewModel: QueryEditorViewModel

    /// The exercises ViewModel for seeding, validation, and score persistence.
    var exercisesViewModel: ExercisesViewModel

    // MARK: - Exercise State

    /// Index of the exercise currently being shown (0-based).
    var currentIndex: Int = 0

    /// Whether the solution has been revealed for the current exercise.
    var solutionRevealed: Bool = false

    /// Whether the editor is locked after a valid execution.
    /// True after any SELECT that returns rows OR any non-query success.
    var editorLocked: Bool = false

    /// Accumulated per-exercise attempt records for the final summary.
    var attempts: [ExerciseAttemptRecord] = []

    /// Tracks whether the user submitted at least one incorrect answer for the
    /// current exercise. Used to keep the "Incorrect" verdict card visible even
    /// after `solutionRevealed` flips `isIncorrect` to false.
    var hadIncorrectAttempt: Bool = false

    /// The SQL text the user actually wrote, captured before ``revealSolution()``
    /// replaces the editor content with the correct answer. Used by
    /// ``recordCurrentExercise()`` so the results screen shows the user's own query.
    private var userOriginalSQL: String?

    // MARK: - Saved Editor State

    /// Saved SQL text for each exercise index, so navigating away and back
    /// restores the editor content the user had typed.
    private var savedSQLText: [Int: String] = [:]

    /// Saved query result per exercise index, so the result card is restored.
    private var savedQueryResult: [Int: QueryResult] = [:]

    /// Saved per-exercise state flags keyed by exercise index.
    private var savedSolutionRevealed: [Int: Bool] = [:]
    private var savedEditorLocked: [Int: Bool] = [:]
    private var savedHadIncorrectAttempt: [Int: Bool] = [:]
    private var savedUserOriginalSQL: [Int: String] = [:]

    // MARK: - Computed Properties

    /// The exercise at the current index.
    var currentExercise: Exercise {
        block.exercises[currentIndex]
    }

    /// Whether this is the last exercise in the block.
    var isLastExercise: Bool {
        currentIndex == block.exercises.count - 1
    }

    /// True only when the user (without help) produced a SELECT result that passes validation.
    /// Explicitly `false` when the solution has been revealed — the user didn't solve it alone.
    var isCorrect: Bool {
        guard !solutionRevealed else { return false }
        guard let result = queryEditorViewModel.queryResult else { return false }
        return exercisesViewModel.validate(result, for: currentExercise) == true
    }

    /// True when a result exists but fails validation (wrong answer), and the solution
    /// has not been revealed yet.
    var isIncorrect: Bool {
        guard !solutionRevealed else { return false }
        guard let result = queryEditorViewModel.queryResult else { return false }
        return exercisesViewModel.validate(result, for: currentExercise) == false
    }

    /// Whether the verdict modal should be shown. True when the user has
    /// submitted a valid query (correct or incorrect) or revealed the solution.
    var showVerdict: Bool {
        isCorrect || isIncorrect || solutionRevealed
    }

    // MARK: - Initialization

    init(block: ExerciseBlock, queryEditorViewModel: QueryEditorViewModel, exercisesViewModel: ExercisesViewModel) {
        self.block = block
        self.queryEditorViewModel = queryEditorViewModel
        self.exercisesViewModel = exercisesViewModel
    }

    // MARK: - Actions

    /// Executes the current SQL and locks the editor if a real result is produced.
    ///
    /// Lock rules:
    /// - Lock on SELECT rows OR non-query success.
    /// - Keep open on SQL error so the user can fix their query.
    func runQuery() async {
        await queryEditorViewModel.executeSQL()

        if queryEditorViewModel.queryResult != nil {
            editorLocked = true
            if isIncorrect { hadIncorrectAttempt = true }
        } else if queryEditorViewModel.executionMessage != nil,
                  queryEditorViewModel.errorMessage == nil {
            // Non-query success (INSERT/UPDATE/DELETE etc.) — also lock
            editorLocked = true
        }
    }

    /// Reveals the correct answer for the current exercise.
    ///
    /// Saves the user's current SQL text before overwriting the editor with the
    /// solution, so the results screen can show what the user actually wrote.
    func revealSolution() {
        guard let expected = exercisesViewModel.expectedResult(for: currentExercise) else { return }
        // Capture the user's own query before replacing editor content.
        userOriginalSQL = queryEditorViewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines)
        queryEditorViewModel.sqlText = currentExercise.solutionSQL
        queryEditorViewModel.clearResults()
        queryEditorViewModel.setResult(expected)
        solutionRevealed = true
        editorLocked = true
    }

    /// Records the current exercise outcome into `attempts`.
    /// Call this before advancing to the next exercise or showing results.
    func recordCurrentExercise() {
        // Avoid double-recording if already recorded (e.g., both tap paths)
        guard !attempts.contains(where: { $0.exerciseTitle == currentExercise.title }) else { return }
        let record = ExerciseAttemptRecord(
            exerciseTitle: currentExercise.title,
            queryUsed: userQueryText,
            wasCorrect: isCorrect
        )
        attempts.append(record)
    }

    /// Returns `attempts` with the current exercise appended (without mutating state).
    /// Used when navigating directly to results from the last exercise.
    func attemptsWithCurrentExercise() -> [ExerciseAttemptRecord] {
        if attempts.contains(where: { $0.exerciseTitle == currentExercise.title }) {
            return attempts
        }
        let record = ExerciseAttemptRecord(
            exerciseTitle: currentExercise.title,
            queryUsed: userQueryText,
            wasCorrect: isCorrect
        )
        return attempts + [record]
    }

    /// The SQL text the user actually typed. If the solution was revealed,
    /// returns the snapshot taken before the editor was overwritten.
    private var userQueryText: String {
        if let saved = userOriginalSQL, solutionRevealed {
            return saved
        }
        return queryEditorViewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Advances to the next exercise by recording the current one and resetting state.
    ///
    /// Saves the current exercise's editor state, then clears results and state
    /// atomically with the index change so that `isIncorrect`/`isCorrect` are
    /// false before the new index is evaluated, preventing button label flickering
    /// during the transition.
    func advanceToNextExercise() {
        recordCurrentExercise()
        saveCurrentExerciseState()
        queryEditorViewModel.clearResults()
        queryEditorViewModel.sqlText = ""
        solutionRevealed = false
        editorLocked = false
        userOriginalSQL = nil
        currentIndex += 1
    }

    /// Records the final exercise and persists the block score.
    func completeBlock() {
        recordCurrentExercise()
        exercisesViewModel.recordCompletion(
            for: block,
            attempts: attemptsWithCurrentExercise()
        )
    }

    /// Resets per-exercise state. Called on every index change to prepare
    /// for the next exercise.
    func resetExerciseState() {
        queryEditorViewModel.sqlText = ""
        queryEditorViewModel.clearResults()
        solutionRevealed = false
        editorLocked = false
        hadIncorrectAttempt = false
        userOriginalSQL = nil
    }

    /// Saves the current exercise's editor state so it can be restored later.
    private func saveCurrentExerciseState() {
        savedSQLText[currentIndex] = queryEditorViewModel.sqlText
        savedQueryResult[currentIndex] = queryEditorViewModel.queryResult
        savedSolutionRevealed[currentIndex] = solutionRevealed
        savedEditorLocked[currentIndex] = editorLocked
        savedHadIncorrectAttempt[currentIndex] = hadIncorrectAttempt
        if let sql = userOriginalSQL {
            savedUserOriginalSQL[currentIndex] = sql
        }
    }

    /// Restores the editor state for the current exercise index.
    /// Called when the view appears and the ViewModel already has progress.
    func restoreEditorState() {
        let idx = currentIndex
        queryEditorViewModel.sqlText = savedSQLText[idx] ?? ""
        queryEditorViewModel.clearResults()
        if let result = savedQueryResult[idx] {
            queryEditorViewModel.setResult(result)
        }
        solutionRevealed = savedSolutionRevealed[idx] ?? false
        editorLocked = savedEditorLocked[idx] ?? false
        hadIncorrectAttempt = savedHadIncorrectAttempt[idx] ?? false
        userOriginalSQL = savedUserOriginalSQL[idx]
    }

    /// Saves the current editor state before the view disappears, so it
    /// can be restored if the user navigates back.
    func saveStateBeforeDisappearing() {
        saveCurrentExerciseState()
    }

    /// Triggers table seeding for the block if needed.
    func seedTablesIfNeeded() async {
        await exercisesViewModel.seedTablesIfNeeded(for: block)
    }
}
