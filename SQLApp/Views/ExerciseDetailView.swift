//
//  ExerciseDetailView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 16/03/26.
//

import SwiftUI

/// Detail view for an exercise block, letting the user practice SQL against
/// the block's pre-seeded tables one exercise at a time.
///
/// ## Layout (top to bottom)
/// 1. **Instructions** — plain text with a lightbulb icon.
/// 2. **SQL Editor** — editable until a valid execution locks it.
/// 3. **Run button** — always visible; disabled (gray) once the editor is locked.
/// 4. **Results area** — error card, user result table, or table previews.
///
/// ## Verdict Modal (Duolingo-style)
/// After a valid execution a bottom modal (~25% of the screen) slides up:
/// - **Green** background for a correct answer, **red** for incorrect.
/// - Contains the verdict title and action buttons (**Next**, **See Answer**,
///   **Show Results**).
/// - The modal cannot be dragged or dismissed by the user.
///
/// ## Completion
/// After the last exercise the user taps **Show Results**, which navigates to
/// ``BlockResultsView`` via the parent `NavigationStack` in ``ExercisesView``.
struct ExerciseDetailView: View {

    // MARK: - Dependencies

    /// The ViewModel managing exercise state, progression, and business logic.
    @Bindable var viewModel: ExerciseDetailViewModel

    /// The settings ViewModel providing the keyword highlight color.
    let settingsViewModel: SettingsViewModel

    // MARK: - UI State

    @State private var isEditorFocused = false
    @State private var showClearButton = false

    /// Tracks which table previews are expanded (by table name).
    @State private var expandedTables: Set<String> = []

    /// Tracks whether each table shows structure (`true`) or data (`false`), keyed by table name.
    @State private var showStructure: [String: Bool] = [:]

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.exercisesViewModel.isSeeding(viewModel.block) {
                loadingScreen
            } else if let error = viewModel.exercisesViewModel.seedingError(for: viewModel.block) {
                errorScreen(message: error)
            } else {
                editorScreen
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(viewModel.currentExercise.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exerciseCounter
            }
        }
        .onAppear {
            viewModel.restoreEditorState()
        }
        .onDisappear {
            viewModel.saveStateBeforeDisappearing()
        }
        .task {
            await viewModel.seedTablesIfNeeded()
        }
        .onChange(of: viewModel.currentIndex) {
            viewModel.resetExerciseState()
            showClearButton = false
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
            instructionsSection
            sqlInputSection
            controlBar
            resultsArea
        }
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        .overlay(alignment: .bottom) {
            if viewModel.showVerdict {
                verdictModal
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showVerdict)
        .sensoryFeedback(.success, trigger: viewModel.isCorrect) { _, isCorrect in
            isCorrect
        }
        .sensoryFeedback(.error, trigger: viewModel.isIncorrect) { _, isIncorrect in
            isIncorrect
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        Text(viewModel.currentExercise.instructions)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    // MARK: - SQL Input

    private var sqlInputSection: some View {
        SQLTextEditorView(
            text: $viewModel.queryEditorViewModel.sqlText,
            isFocused: $isEditorFocused,
            keywordColor: settingsViewModel.keywordUIColor
        )
        .frame(minHeight: 120, maxHeight: 200)
        .opacity(viewModel.editorLocked ? 0.6 : 1.0)
        .allowsHitTesting(!viewModel.editorLocked)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            if showClearButton && !viewModel.editorLocked {
                Button {
                    viewModel.queryEditorViewModel.sqlText = ""
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
            if focused && !viewModel.queryEditorViewModel.sqlText.isEmpty && !viewModel.editorLocked {
                showClearButton = true
            } else {
                showClearButton = false
            }
        }
        .onChange(of: viewModel.queryEditorViewModel.sqlText) {
            if showClearButton { showClearButton = false }
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: 6) {
            runButton

            if let message = viewModel.queryEditorViewModel.executionMessage,
               !viewModel.showVerdict {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(executionMessageColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button {
            dismissKeyboard()
            Task { await viewModel.runQuery() }
        } label: {
            Group {
                if viewModel.queryEditorViewModel.isExecuting {
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
            viewModel.editorLocked
            || viewModel.queryEditorViewModel.sqlText
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || viewModel.queryEditorViewModel.isExecuting
        )
    }

    // MARK: - Verdict Modal

    /// A Duolingo-style bottom modal that shows the verdict (Correct / Incorrect)
    /// and action buttons. Covers the bottom of the screen edge-to-edge,
    /// ignoring safe areas so the color extends to all edges.
    private var verdictModal: some View {
        let isCorrect = viewModel.isCorrect
        let bgColor: Color = isCorrect ? .green : .red

        return VStack(spacing: 16) {
            // Verdict title
            Text(isCorrect ? "Correct" : "Incorrect")
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons
            verdictModalButtons
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .safeAreaPadding(.bottom)
        .frame(maxWidth: .infinity)
        .background(
            bgColor
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// The buttons shown inside the verdict modal.
    @ViewBuilder
    private var verdictModalButtons: some View {
        if viewModel.isCorrect || viewModel.solutionRevealed {
            // Correct answer or solution revealed — show advance button
            if viewModel.isLastExercise {
                NavigationLink(
                    value: ExercisesView.Destination.blockResults(
                        viewModel.block,
                        viewModel.attemptsWithCurrentExercise()
                    )
                ) {
                    Label("Show Results", systemImage: "chart.bar.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(viewModel.isCorrect ? .green : .red)
                .controlSize(.large)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.completeBlock()
                })
            } else {
                Button {
                    viewModel.advanceToNextExercise()
                    showClearButton = false
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .environment(\.layoutDirection, .rightToLeft)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(viewModel.isCorrect ? .green : .red)
                .controlSize(.large)
            }
        } else if viewModel.isIncorrect {
            // Incorrect — See Answer + advance.
            // Last exercise: stack vertically so "Show Results" doesn't wrap.
            // Other exercises: side by side since "Next" is short enough.
            let layout = viewModel.isLastExercise
                ? AnyLayout(VStackLayout(spacing: 12))
                : AnyLayout(HStackLayout(spacing: 12))

            layout {
                Button {
                    viewModel.revealSolution()
                    showClearButton = false
                    dismissKeyboard()
                } label: {
                    Text("See Answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .controlSize(.large)

                if viewModel.isLastExercise {
                    NavigationLink(
                        value: ExercisesView.Destination.blockResults(
                            viewModel.block,
                            viewModel.attemptsWithCurrentExercise()
                        )
                    ) {
                        Label("Show Results", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.red)
                    .controlSize(.large)
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.completeBlock()
                    })
                } else {
                    Button {
                        viewModel.advanceToNextExercise()
                        showClearButton = false
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                            .environment(\.layoutDirection, .rightToLeft)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.red)
                    .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Results Area

    private var resultsArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let error = viewModel.queryEditorViewModel.errorMessage {
                    errorCard(message: error)
                } else if let result = viewModel.queryEditorViewModel.queryResult {
                    userResultCard(result: result)
                } else {
                    tablePreviewSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, viewModel.showVerdict ? 220 : 16)
        }
        // Dismiss button is only shown before the editor locks.
        .overlay(alignment: .topTrailing) {
            if hasUserResult && !viewModel.editorLocked {
                Button {
                    viewModel.queryEditorViewModel.clearResults()
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

    // MARK: - User Result Card

    private func userResultCard(result: QueryResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.solutionRevealed {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                    Text("Solution").fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(settingsViewModel.keywordColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            ResultsTableView(result: result, headerColor: settingsViewModel.keywordColor)
                .frame(minHeight: 150, maxHeight: 400)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        ForEach(viewModel.block.tableNames, id: \.self) { tableName in
            tablePreviewCard(tableName: tableName)
        }
    }

    private func tablePreviewCard(tableName: String) -> some View {
        let isExpanded = expandedTables.contains(tableName)
        let isStructure = showStructure[tableName] ?? false

        return VStack(alignment: .leading, spacing: 0) {
            // Header row: chevron + table name + (toggle when expanded)
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedTables.remove(tableName)
                        } else {
                            expandedTables.insert(tableName)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Label(tableName, systemImage: "tablecells")
                            .font(.headline)
                            .foregroundStyle(settingsViewModel.keywordColor)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if isExpanded {
                    Picker("View", selection: Binding(
                        get: { showStructure[tableName] ?? false },
                        set: { showStructure[tableName] = $0 }
                    )) {
                        Text("Data").tag(false)
                        Text("Structure").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .controlSize(.mini)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Expandable content
            if isExpanded {
                if isStructure {
                    tableStructureContent(tableName: tableName)
                } else {
                    tableDataContent(tableName: tableName)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Table Data Content

    private func tableDataContent(tableName: String) -> some View {
        Group {
            if let data = viewModel.exercisesViewModel.previewData(for: tableName) {
                ResultsTableView(result: data, headerColor: settingsViewModel.keywordColor)
                    .frame(minHeight: 150, maxHeight: 300)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
    }

    // MARK: - Table Structure Content

    private func tableStructureContent(tableName: String) -> some View {
        Group {
            if let info = viewModel.exercisesViewModel.structureInfo(for: tableName) {
                VStack(spacing: 0) {
                    ForEach(Array(info.columns.enumerated()), id: \.offset) { index, column in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(column.name)
                                    .font(.system(.caption, design: .monospaced).bold())
                                Spacer()
                                Text(column.type)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 8) {
                                if column.isPrimaryKey {
                                    Label("PK", systemImage: "key.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                                if column.isNotNull {
                                    Text("NOT NULL")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                                if let defaultVal = column.defaultValue {
                                    Text("DEFAULT: \(defaultVal)")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(index.isMultiple(of: 2) ? Color.clear : Color(.systemGray6))
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
    }

    // MARK: - Navigation Bar Accessories

    private var exerciseCounter: some View {
        let total = viewModel.block.exercises.count
        let current = viewModel.currentIndex + 1
        let progress = CGFloat(current) / CGFloat(total)

        return ZStack {
            // Track
            Circle()
                .stroke(settingsViewModel.keywordColor.opacity(0.15), lineWidth: 3)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    settingsViewModel.keywordColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Counter label
            Text("\(current)/\(total)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(width: 36, height: 36)
        .animation(.easeOut(duration: 0.4), value: viewModel.currentIndex)
    }

    // MARK: - Helpers

    private var hasUserResult: Bool {
        viewModel.queryEditorViewModel.queryResult != nil
        || viewModel.queryEditorViewModel.errorMessage != nil
    }

    private var executionMessageColor: Color {
        switch viewModel.queryEditorViewModel.executionStatus {
        case .error:   return .red
        case .success: return .green
        case .idle:    return .secondary
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
