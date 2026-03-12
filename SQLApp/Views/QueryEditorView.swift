import SwiftUI

/// The main SQL editor view where users write and execute SQL queries.
///
/// Composed of three vertical sections:
/// 1. **SQL Input** - A `TextEditor` with monospaced font for writing SQL,
///    featuring a floating "Clear" button that appears when the editor receives
///    focus and already contains text.
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

    /// Tracks whether the SQL text editor currently has keyboard focus.
    @FocusState private var isEditorFocused: Bool

    /// Controls the visibility of the floating "Clear" button inside the text editor.
    /// Shows when the editor gains focus with existing text; hides on any text change.
    @State private var showClearButton = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sqlInputSection
                Divider()
                controlBar
                Divider()
                resultsSection
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isEditorFocused = false
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

    /// The SQL text editor area with a floating "Clear" button overlay.
    ///
    /// The "Clear" button appears in the top-right corner when the editor gains
    /// focus and already contains text. It disappears as soon as the user types
    /// or deletes any character, or when the editor loses focus.
    private var sqlInputSection: some View {
        TextEditor(text: $viewModel.sqlText)
            .font(.system(.body, design: .monospaced))
            .focused($isEditorFocused)
            .frame(minHeight: 120, maxHeight: 200)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Color(.systemGray6))
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
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

    /// The toolbar containing the "Run" button, execution progress, and status message.
    ///
    /// The "Run" button is disabled when the SQL text is empty or a query is already
    /// executing. Tapping "Run" dismisses the keyboard before starting execution.
    /// The execution message is color-coded: green for success, red for errors.
    private var controlBar: some View {
        HStack {
            Button {
                isEditorFocused = false
                Task { await viewModel.executeSQL() }
            } label: {
                Label("Run", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                viewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.isExecuting
            )

            if viewModel.isExecuting {
                ProgressView()
                    .padding(.leading, 8)
            }

            Spacer()

            if let message = viewModel.executionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(executionMessageColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
    /// A dismiss button (×) appears in the top-right corner when any result or
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
                ResultsTableView(result: result)
            } else if viewModel.executionMessage != nil {
                ContentUnavailableView(
                    "Done",
                    systemImage: "checkmark.circle",
                    description: Text(viewModel.executionMessage ?? "")
                )
            } else {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "text.page",
                    description: Text("Write a SQL query and tap Run")
                )
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
}
