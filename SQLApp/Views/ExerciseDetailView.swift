//
//  ExerciseDetailView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 16/03/26.
//

import SwiftUI

/// Detail view for an exercise block, letting the user practice SQL against
/// the block's pre-seeded tables one exercise at a time.
///
/// ## Editor lock rules
/// - The editor is editable until the user taps **Run**.
/// - After a **valid execution** (SELECT with rows, or non-query success) the editor
///   locks — the user can no longer edit or re-run.
/// - After a **SQL error** the editor stays editable so the user can fix their query.
/// - The dismiss button on the result card is hidden once the editor is locked.
///
/// ## Control bar states
/// - **Idle / SQL error** → full-width **Run**
/// - **Correct answer** → full-width **Next** (or **Show Results** on the last exercise)
/// - **Incorrect answer** → **Show Result** + **Next** side by side
/// - **Solution revealed** → full-width **Next** / **Show Results**
///
/// ## Completion
/// After the last exercise the user taps **Show Results**, which navigates to
/// ``BlockResultsView`` via the parent `NavigationStack` in ``ExercisesView``.
struct ExerciseDetailView: View {

    // MARK: - Dependencies

    let block: ExerciseBlock
    @Bindable var queryEditorViewModel: QueryEditorViewModel
    let settingsViewModel: SettingsViewModel
    @Bindable var exercisesViewModel: ExercisesViewModel

    // MARK: - State

    /// Index of the exercise currently being shown (0-based).
    @State private var currentIndex: Int = 0

    /// Whether the solution has been revealed for the current exercise.
    @State private var solutionRevealed: Bool = false

    /// Whether the editor is locked after a valid execution.
    /// True after any SELECT that returns rows OR any non-query success.
    @State private var editorLocked: Bool = false

    /// Accumulated per-exercise attempt records for the final summary.
    @State private var attempts: [ExerciseAttemptRecord] = []

    /// Tracks whether the user submitted at least one incorrect answer for the
    /// current exercise. Used to keep the "Incorrect" verdict card visible even
    /// after `solutionRevealed` flips `isIncorrect` to false.
    @State private var hadIncorrectAttempt: Bool = false

    @State private var isEditorFocused = false
    @State private var showClearButton = false

    // MARK: - Computed Properties

    private var currentExercise: Exercise {
        block.exercises[currentIndex]
    }

    private var isLastExercise: Bool { currentIndex == block.exercises.count - 1 }

    /// True only when the user (without help) produced a SELECT result that passes validation.
    /// Explicitly `false` when the solution has been revealed — the user didn't solve it alone.
    private var isCorrect: Bool {
        guard !solutionRevealed else { return false }
        guard let result = queryEditorViewModel.queryResult else { return false }
        return exercisesViewModel.validate(result, for: currentExercise) == true
    }

    /// True when a result exists but fails validation (wrong answer), and the solution
    /// has not been revealed yet.
    private var isIncorrect: Bool {
        guard !solutionRevealed else { return false }
        guard let result = queryEditorViewModel.queryResult else { return false }
        return exercisesViewModel.validate(result, for: currentExercise) == false
    }

    // MARK: - Body

    var body: some View {
        Group {
            if exercisesViewModel.isSeeding(block) {
                loadingScreen
            } else if let error = exercisesViewModel.seedingError(for: block) {
                errorScreen(message: error)
            } else {
                editorScreen
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(currentExercise.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exerciseCounter
            }
        }
        .onAppear {
            currentIndex = 0
            attempts = []
            resetExerciseState()
        }
        .task {
            await exercisesViewModel.seedTablesIfNeeded(for: block)
        }
        .onChange(of: currentIndex) {
            resetExerciseState()
        }
    }

    // MARK: - Loading / Error Screens

    private var loadingScreen: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().controlSize(.large)
            Text("Preparing tables…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorScreen(message: String) -> some View {
        ContentUnavailableView(
            "Could Not Load Tables",
            systemImage: "exclamationmark.triangle.fill",
            description: Text(message)
        )
    }

    // MARK: - Editor Screen

    private var editorScreen: some View {
        VStack(spacing: 0) {
            sqlInputSection
            controlBar
            resultsArea
        }
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
    }

    // MARK: - SQL Input

    private var sqlInputSection: some View {
        SQLTextEditorView(
            text: $queryEditorViewModel.sqlText,
            isFocused: $isEditorFocused,
            keywordColor: settingsViewModel.keywordUIColor
        )
        .frame(minHeight: 120, maxHeight: 200)
        .opacity(editorLocked ? 0.6 : 1.0)
        .allowsHitTesting(!editorLocked)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            if showClearButton && !editorLocked {
                Button {
                    queryEditorViewModel.sqlText = ""
                    showClearButton = false
                } label: {
                    Text("Clear")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(8)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showClearButton)
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: isEditorFocused) { _, focused in
            if focused && !queryEditorViewModel.sqlText.isEmpty && !editorLocked {
                showClearButton = true
            } else {
                showClearButton = false
            }
        }
        .onChange(of: queryEditorViewModel.sqlText) {
            if showClearButton { showClearButton = false }
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: 6) {
            controlButtons

            if let message = queryEditorViewModel.executionMessage,
               !isCorrect, !editorLocked {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(executionMessageColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .sensoryFeedback(.success, trigger: queryEditorViewModel.executionStatus) { _, new in
            if case .success = new { return true }
            return false
        }
        .sensoryFeedback(.error, trigger: queryEditorViewModel.executionStatus) { _, new in
            if case .error = new { return true }
            return false
        }
        .animation(.easeInOut(duration: 0.2), value: editorLocked)
        .animation(.easeInOut(duration: 0.2), value: isCorrect)
        .animation(.easeInOut(duration: 0.2), value: solutionRevealed)
    }

    /// The appropriate button(s) for the current exercise state.
    @ViewBuilder
    private var controlButtons: some View {
        if isCorrect || solutionRevealed {
            // Correct answer or solution shown — advance
            advanceButton
        } else if isIncorrect {
            // Wrong answer — offer show result + advance (respects last-exercise boundary)
            HStack(spacing: 10) {
                showResultButton
                incorrectAdvanceButton
            }
        } else {
            // Idle or SQL error — allow (re-)running
            runButton
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button {
            dismissKeyboard()
            Task {
                await queryEditorViewModel.executeSQL()
                // Lock the editor if the execution produced a real result.
                // Rule: lock on SELECT rows OR non-query success; keep open on SQL error.
                if queryEditorViewModel.queryResult != nil {
                    editorLocked = true
                    // Record that the user got this one wrong before any reveal
                    if isIncorrect { hadIncorrectAttempt = true }
                } else if queryEditorViewModel.executionMessage != nil,
                          queryEditorViewModel.errorMessage == nil {
                    // Non-query success (INSERT/UPDATE/DELETE etc.) — also lock
                    editorLocked = true
                }
            }
        } label: {
            Group {
                if queryEditorViewModel.isExecuting {
                    ProgressView().tint(.white)
                } else {
                    Label("Run", systemImage: "play.fill")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(
            queryEditorViewModel.sqlText
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || queryEditorViewModel.isExecuting
        )
    }

    // MARK: - Advance Button (Correct / Solution Revealed)

    /// "Next" on non-last exercises; "Show Results" on the last exercise.
    @ViewBuilder
    private var advanceButton: some View {
        if isLastExercise {
            // Record the current exercise then navigate to summary
            NavigationLink(
                value: ExercisesView.Destination.blockResults(
                    block,
                    attemptsWithCurrentExercise()
                )
            ) {
                Label("Show Results", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .simultaneousGesture(TapGesture().onEnded {
                recordCurrentExercise()
                exercisesViewModel.recordCompletion(
                    for: block,
                    attempts: attemptsWithCurrentExercise()
                )
            })
        } else {
            nextStepButton(label: "Next", icon: "chevron.right")
        }
    }

    // MARK: - Show Result Button (reveals the correct answer, marks attempt as incorrect)

    private var showResultButton: some View {
        Button {
            revealSolution()
        } label: {
            Text("See Answer")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(settingsViewModel.keywordColor)
    }

    // MARK: - Incorrect Advance Button

    /// When the user is wrong: "Next" on non-last exercises, "Show Results" on the last.
    /// Uses a NavigationLink for the last exercise to match `advanceButton` behavior.
    @ViewBuilder
    private var incorrectAdvanceButton: some View {
        if isLastExercise {
            NavigationLink(
                value: ExercisesView.Destination.blockResults(
                    block,
                    attemptsWithCurrentExercise()
                )
            ) {
                Label("Show Results", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .simultaneousGesture(TapGesture().onEnded {
                recordCurrentExercise()
                exercisesViewModel.recordCompletion(
                    for: block,
                    attempts: attemptsWithCurrentExercise()
                )
            })
        } else {
            nextStepButton(label: "Next", icon: "chevron.right")
        }
    }

    // MARK: - Next Step Button

    private func nextStepButton(label: String, icon: String) -> some View {
        Button {
            recordCurrentExercise()
            // Clear results and state atomically with the index change so that
            // `isIncorrect`/`isCorrect` are false before the new index is evaluated,
            // preventing the button label from flickering to "Show Results" mid-transition.
            queryEditorViewModel.clearResults()
            queryEditorViewModel.sqlText = ""
            solutionRevealed = false
            editorLocked = false
            showClearButton = false
            currentIndex += 1
        } label: {
            Label(label, systemImage: icon)
                .labelStyle(.titleAndIcon)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Solution Reveal

    private func revealSolution() {
        guard let expected = exercisesViewModel.expectedResult(for: currentExercise) else { return }
        queryEditorViewModel.sqlText = currentExercise.solutionSQL
        queryEditorViewModel.clearResults()
        queryEditorViewModel.setResult(expected)
        solutionRevealed = true
        editorLocked = true
        showClearButton = false
        dismissKeyboard()
    }

    // MARK: - Attempt Recording

    /// Records the current exercise outcome into `attempts`.
    /// Call this before advancing to the next exercise or showing results.
    private func recordCurrentExercise() {
        // Avoid double-recording if already recorded (e.g., both tap paths)
        guard !attempts.contains(where: { $0.exerciseTitle == currentExercise.title }) else { return }
        let record = ExerciseAttemptRecord(
            exerciseTitle: currentExercise.title,
            queryUsed: queryEditorViewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines),
            wasCorrect: isCorrect
        )
        attempts.append(record)
    }

    /// Returns `attempts` with the current exercise appended (without mutating state).
    /// Used when navigating directly to results from the last exercise.
    private func attemptsWithCurrentExercise() -> [ExerciseAttemptRecord] {
        if attempts.contains(where: { $0.exerciseTitle == currentExercise.title }) {
            return attempts
        }
        let record = ExerciseAttemptRecord(
            exerciseTitle: currentExercise.title,
            queryUsed: queryEditorViewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines),
            wasCorrect: isCorrect
        )
        return attempts + [record]
    }

    // MARK: - Results Area

    private var resultsArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                instructionsCard
                if let error = queryEditorViewModel.errorMessage {
                    errorCard(message: error)
                } else if let result = queryEditorViewModel.queryResult {
                    userResultCard(result: result)
                } else {
                    tablePreviewSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        // Dismiss button is only shown before the editor locks.
        .overlay(alignment: .topTrailing) {
            if hasUserResult && !editorLocked {
                Button {
                    queryEditorViewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                .padding(.trailing, 20)
            }
        }
    }

    // MARK: - Instructions Card
    // Shows exercise instructions at rest; switches to a full-card verdict
    // (green / red) once the user has executed a query. The card's minimum
    // height is fixed so the layout does not shift on the transition.

    private var instructionsCard: some View {
        // Outer frame is always the same size regardless of which content is shown.
        // Both the instruction HStack and the verdict Text share the same
        // padding(12) + minHeight(60) container so the card never resizes.
        ZStack {
            if verdictLabel != nil {
                verdictBackground
            } else {
                Color(.secondarySystemGroupedBackground)
            }

            Group {
                if let label = verdictLabel, let color = verdictColor {
                    Text(label)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        // Use a subtle color overlay so background stays visible
                        .environment(\.colorScheme, .dark)
                        // Silence unused — color is used in ZStack background above
                        .id(color)
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(settingsViewModel.keywordColor)
                            .font(.subheadline)
                            .padding(.top, 1)
                        Text(currentExercise.instructions)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.2), value: verdictLabel)
    }

    /// Non-nil when a verdict (Correct / Incorrect) should be shown in the card.
    /// Remains set even after `solutionRevealed` so the label persists until the
    /// user advances to the next exercise.
    private var verdictLabel: String? {
        if isCorrect { return "Correct" }
        // isIncorrect becomes false after solutionRevealed, so check the
        // stored attempt to keep showing "Incorrect" even after See Answer.
        if isIncorrect || hadIncorrectAttempt { return "Incorrect" }
        return nil
    }

    private var verdictColor: Color? {
        if isCorrect { return .green }
        if isIncorrect || hadIncorrectAttempt { return .red }
        return nil
    }

    @ViewBuilder
    private var verdictBackground: some View {
        if isCorrect {
            Color.green
        } else {
            // isIncorrect or hadIncorrectAttempt — always red
            Color.red
        }
    }

    // MARK: - User Result Card (with verdict)

    private func userResultCard(result: QueryResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            verdictBanner(for: result)
            ResultsTableView(result: result, headerColor: settingsViewModel.keywordColor)
                .frame(minHeight: 150, maxHeight: 400)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Small header shown above the result table. Only appears when the solution
    /// has been revealed (to distinguish it from a user-submitted result).
    @ViewBuilder
    private func verdictBanner(for result: QueryResult) -> some View {
        if solutionRevealed {
            HStack(spacing: 6) {
                Image(systemName: "eye.fill")
                Text("Solution").fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(settingsViewModel.keywordColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Error Card

    private func errorCard(message: String) -> some View {
        Label(message, systemImage: "xmark.circle.fill")
            .foregroundStyle(.red)
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Table Preview Section

    private var tablePreviewSection: some View {
        ForEach(block.tableNames, id: \.self) { tableName in
            tablePreviewCard(tableName: tableName)
        }
    }

    private func tablePreviewCard(tableName: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(tableName, systemImage: "tablecells")
                .font(.headline)
                .foregroundStyle(settingsViewModel.keywordColor)
                .padding(.horizontal)
                .padding(.vertical, 8)

            if let data = exercisesViewModel.previewData(for: tableName) {
                ResultsTableView(result: data, headerColor: settingsViewModel.keywordColor)
                    .frame(minHeight: 150, maxHeight: 300)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Navigation Bar Accessories

    private var exerciseCounter: some View {
        Text("\(currentIndex + 1) / \(block.exercises.count)")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var hasUserResult: Bool {
        queryEditorViewModel.queryResult != nil
        || queryEditorViewModel.errorMessage != nil
    }

    private var executionMessageColor: Color {
        switch queryEditorViewModel.executionStatus {
        case .error:   return .red
        case .success: return .green
        case .idle:    return .secondary
        }
    }

    /// Resets all per-exercise state. Called on appear and on every index change.
    private func resetExerciseState() {
        queryEditorViewModel.sqlText = ""
        queryEditorViewModel.clearResults()
        showClearButton = false
        solutionRevealed = false
        editorLocked = false
        hadIncorrectAttempt = false
        // Reset attempts and index only on fresh appear (not on index change)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
