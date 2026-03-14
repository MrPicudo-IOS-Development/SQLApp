//
//  QueryEditorView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// The main SQL editor view where users write and execute SQL queries.
///
/// Composed of three vertical sections:
/// 1. **SQL Input** - A ``SQLTextEditorView`` (UITextView-backed) with syntax
///    highlighting, auto-uppercase of SQL keywords, and a floating "Clear"
///    button that appears when the editor receives focus and already contains text.
/// 2. **Control Bar** - A "Run" button to execute the query, a progress indicator
///    during execution, and a color-coded execution summary message.
/// 3. **Results Section** - Displays query results via ``ResultsTableView``,
///    error messages, or an empty state placeholder. Includes a dismiss button
///    to clear results when present.
///
/// Provides haptic feedback via `.sensoryFeedback` modifiers that respond
/// to changes in ``QueryEditorViewModel/executionStatus``.
/// Dismisses the keyboard when the user taps outside the text editor
/// or presses the "Run" button.
struct QueryEditorView: View {

    /// The ViewModel that manages the editor's state and SQL execution logic.
    @Bindable var viewModel: QueryEditorViewModel

    /// The settings ViewModel providing the keyword highlight color.
    let settingsViewModel: SettingsViewModel

    /// Tracks whether the SQL text editor currently has keyboard focus.
    ///
    /// Uses a plain `@State` Bool instead of `@FocusState` because the editor
    /// is a `UIViewRepresentable` that manages focus through its coordinator.
    /// The ``SQLTextEditorCoordinator`` updates this binding via
    /// `textViewDidBeginEditing` and `textViewDidEndEditing`.
    @State private var isEditorFocused = false

    /// Controls the visibility of the floating "Clear" button inside the text editor.
    /// Shows when the editor gains focus with existing text; hides on any text change.
    @State private var showClearButton = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sqlInputSection
                controlBar
                resultsSection
            }
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .navigationTitle("SQL Editor")
            .sensoryFeedback(.success, trigger: viewModel.executionStatus) { old, new in
                if case .success = new { return true }
                return false
            }
            .sensoryFeedback(.error, trigger: viewModel.executionStatus) { old, new in
                if case .error = new { return true }
                return false
            }
        }
    }

    // MARK: - SQL Input

    /// The SQL text editor area with syntax highlighting and a floating "Clear" button overlay.
    ///
    /// Uses ``SQLTextEditorView`` (a `UIViewRepresentable` wrapping `UITextView`) to
    /// support `NSAttributedString`-based syntax highlighting. SQL keywords are displayed
    /// in the color configured via ``SettingsViewModel`` and with semibold weight.
    ///
    /// The "Clear" button appears in the top-right corner when the editor gains
    /// focus and already contains text. It disappears as soon as the user types
    /// or deletes any character, or when the editor loses focus.
    private var sqlInputSection: some View {
        SQLTextEditorView(
            text: $viewModel.sqlText,
            isFocused: $isEditorFocused,
            keywordColor: settingsViewModel.keywordUIColor
        )
        .frame(minHeight: 120, maxHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            if showClearButton {
                Button {
                    viewModel.sqlText = ""
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
            if focused && !viewModel.sqlText.isEmpty {
                showClearButton = true
            } else {
                showClearButton = false
            }
        }
        .onChange(of: viewModel.sqlText) {
            if showClearButton {
                showClearButton = false
            }
        }
    }

    // MARK: - Control Bar

    /// The control area containing a full-width "Run" button and execution status.
    ///
    /// The "Run" button spans the available width following HIG emphasis
    /// guidelines for primary actions. Disabled when the SQL text is empty
    /// or a query is already executing. Tapping "Run" dismisses the keyboard
    /// before starting execution. A color-coded status message appears
    /// beneath the button after execution completes.
    private var controlBar: some View {
        VStack(spacing: 6) {
            Button {
                dismissKeyboard()
                Task { await viewModel.executeSQL() }
            } label: {
                Group {
                    if viewModel.isExecuting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Run", systemImage: "play.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(
                viewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.isExecuting
            )

            if let message = viewModel.executionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(executionMessageColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Results

    /// The output area displaying query results, errors, or an empty state.
    ///
    /// Shows one of four states:
    /// - **Error**: A red-tinted error message with an icon.
    /// - **Query result**: A ``ResultsTableView`` grid with the returned data.
    /// - **Non-query success**: A "Done" confirmation with the execution summary.
    /// - **Empty**: A placeholder prompting the user to write and run a query.
    ///
    /// A dismiss button (x) appears in the top-right corner when any result or
    /// error is present, allowing the user to clear the output area.
    private var resultsSection: some View {
        Group {
            if let error = viewModel.errorMessage {
                ScrollView {
                    Label(error, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let result = viewModel.queryResult {
                ResultsTableView(result: result, headerColor: settingsViewModel.keywordColor)
            } else if viewModel.executionMessage != nil {
                ContentUnavailableView(
                    "Done",
                    systemImage: "checkmark.circle",
                    description: Text(viewModel.executionMessage ?? "")
                )
            } else {
                ContentUnavailableView {
                    Label("No Results", systemImage: "text.page")
                        .foregroundStyle(settingsViewModel.keywordColor)
                } description: {
                    Text("Write a SQL query and tap Run")
                        .padding(.top)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if hasResults {
                Button(role: .destructive) {
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(8)
            }
        }
    }

    // MARK: - Helpers

    /// Whether any result, error, or execution message is currently displayed.
    private var hasResults: Bool {
        viewModel.queryResult != nil || viewModel.errorMessage != nil || viewModel.executionMessage != nil
    }

    /// Returns the appropriate color for the execution message based on the current status.
    private var executionMessageColor: Color {
        switch viewModel.executionStatus {
        case .error:
            return .red
        case .success:
            return .green
        case .idle:
            return .secondary
        }
    }

    /// Dismisses the keyboard by resigning the current first responder.
    ///
    /// Uses `UIApplication.sendAction` to safely resign first responder
    /// without directly manipulating `UITextView` from `updateUIView`,
    /// which would cause delegate callbacks and SwiftUI update cycles.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
