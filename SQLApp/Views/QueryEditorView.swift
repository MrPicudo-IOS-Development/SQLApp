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

    /// The title displayed at the top of the editor. Defaults to `"SQL Editor"`.
    /// Can be overridden when reusing this view in other flows.
    var title: String = "SQL Editor"

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
                titleHeader
                sqlInputSection
                resultsSection
            }
            .background(Color(.systemGroupedBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.success, trigger: viewModel.executionStatus) { old, new in
                if case .success = new { return true }
                return false
            }
            .sensoryFeedback(.error, trigger: viewModel.executionStatus) { old, new in
                if case .error = new { return true }
                return false
            }
            .sheet(isPresented: $viewModel.isShowingTablePicker) {
                tablePickerSheet
            }
        }
    }

    // MARK: - Title Header

    /// The inline title label displayed at the top of the editor,
    /// replacing the standard navigation title for reusability across flows.
    private var titleHeader: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // MARK: - SQL Input

    /// The SQL text editor area styled with a dark "Code Preview" theme.
    ///
    /// Features a terminal-style title bar (red/yellow/green dots), a dark background
    /// editor area with purple keyword highlighting, and a floating "Clear" button.
    /// Uses ``SQLTextEditorView`` (a `UIViewRepresentable` wrapping `UITextView`) to
    /// support `NSAttributedString`-based syntax highlighting.
    /// The current style from settings.
    private var style: AppStyle { settingsViewModel.selectedStyle }

    private var sqlInputSection: some View {
        VStack(spacing: 0) {
            // Terminal-style title bar
            HStack {
                Circle().fill(.red).frame(width: 10, height: 10)
                Circle().fill(.yellow).frame(width: 10, height: 10)
                Circle().fill(.green).frame(width: 10, height: 10)
                Spacer()
                Text("query.sql")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(style.editorSecondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.editorTitleBar)

            // SQL text editor
            ZStack(alignment: .topTrailing) {
                SQLTextEditorView(
                    text: $viewModel.sqlText,
                    isFocused: $isEditorFocused,
                    keywordColor: UIColor(style.editorKeywordColor)
                )
                .frame(minHeight: 120, maxHeight: 200)
                .colorScheme(style.editorColorScheme)

                if showClearButton {
                    Button {
                        viewModel.sqlText = ""
                        showClearButton = false
                    } label: {
                        Text("Clear")
                            .font(.caption.bold())
                            .foregroundStyle(style.editorTextColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(style.editorSecondaryText.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding(8)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .background(style.editorBackground)
            .animation(.easeInOut(duration: 0.2), value: showClearButton)

            // Control bar (attached to editor)
            controlBar
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    /// The control bar with a green "Run" button, execution status, and dismiss button,
    /// styled with the dark "Code Preview" theme.
    private var controlBar: some View {
        HStack(spacing: 12) {
            Button {
                dismissKeyboard()
                Task { await viewModel.executeSQL() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isExecuting {
                        ProgressView()
                            .tint(style.runButtonTextColor)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                    }
                    Text("Run")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(style.runButtonTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(style.runButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(
                viewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.isExecuting
            )
            .opacity(
                viewModel.sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? 0.5 : 1.0
            )

            if let message = viewModel.executionMessage {
                Text(message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(executionMessageColor)
            }

            Spacer()

            if hasResults {
                Button {
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(style.editorSecondaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(style.editorTitleBar)
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
                StyledResultsTableView(result: result, style: style)
            } else if viewModel.executionMessage != nil {
                ContentUnavailableView(
                    "Done",
                    systemImage: "checkmark.circle",
                    description: Text(viewModel.executionMessage ?? "")
                )
            } else {
                emptyStateWithPinnedTables
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State & Pinned Tables

    /// The empty state view that includes the "Pin Table" button and any pinned table data.
    ///
    /// When no pinned tables exist, shows the original "No Results" placeholder with an
    /// additional "Pin Table" button. When tables are pinned, shows each table's data
    /// in a scrollable list with the "Pin Table" button at the bottom for adding more.
    private var emptyStateWithPinnedTables: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.pinnedTables.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.page")
                            .font(.system(size: 40))
                            .foregroundStyle(style.accentColor)
                        Text("No Results")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Create, edit, or query your tables from the Tables section using SQL statements")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                }

                ForEach(viewModel.pinnedTables) { pinned in
                    pinnedTableCard(pinned)
                }

                pinTableButton
            }
            .padding(.bottom, 16)
        }
    }

    /// A card displaying a single pinned table with its name header and content.
    ///
    /// Shows row data or column schema depending on the current
    /// ``SettingsViewModel/pinnedTableDisplayMode``. Includes an "Unpin" button
    /// in the header so the user can remove the pinned table from the display.
    private func pinnedTableCard(_ pinned: PinnedTable) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(pinned.name, systemImage: "tablecells")
                    .font(.headline)
                    .foregroundStyle(style.accentColor)
                Spacer()
                Button {
                    viewModel.unpinTable(pinned)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch settingsViewModel.pinnedTableDisplayMode {
            case .data:
                StyledResultsTableView(result: pinned.data, style: style)
                    .frame(minHeight: 150, maxHeight: 300)
            case .structure:
                pinnedTableStructure(pinned.info)
                    .frame(minHeight: 100, maxHeight: 300)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal)
    }

    /// A two-column grid displaying a table's column names and types,
    /// styled consistently with ``ResultsTableView``.
    private func pinnedTableStructure(_ info: TableInfo) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Text("Column")
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                    Text("Type")
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                }

                ForEach(Array(info.columns.enumerated()), id: \.offset) { index, column in
                    GridRow {
                        Text(column.name)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                            .background(index.isMultiple(of: 2) ? Color.clear : Color(.systemGray6))
                        Text(column.type)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                            .background(index.isMultiple(of: 2) ? Color.clear : Color(.systemGray6))
                    }
                }
            }
        }
    }

    // MARK: - Pin Table Button

    /// A button that opens the table selection sheet for pinning a new table.
    private var pinTableButton: some View {
        Button {
            Task {
                await viewModel.loadAvailableTables()
                viewModel.isShowingTablePicker = true
            }
        } label: {
            Label("Pin Table", systemImage: "pin")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .padding(.top, 8)
    }

    // MARK: - Table Picker Sheet

    /// A modal sheet presenting the list of available tables for the user to pin.
    ///
    /// Follows Apple HIG for modal selection: includes a navigation bar with a
    /// "Cancel" button, a list of table names, and dismisses on selection.
    /// Tables already pinned are filtered out of the list.
    private var tablePickerSheet: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingTables {
                    ProgressView("Loading tables...")
                } else if viewModel.availableTablesForPinning.isEmpty {
                    ContentUnavailableView(
                        "No Tables Available",
                        systemImage: "tablecells.badge.ellipsis",
                        description: Text("All tables are already pinned, or no tables exist yet")
                    )
                } else {
                    List(viewModel.availableTablesForPinning, id: \.self) { tableName in
                        Button {
                            Task { await viewModel.pinTable(tableName, rowLimit: settingsViewModel.pinnedTableRowLimit) }
                        } label: {
                            Label {
                                Text(tableName)
                            } icon: {
                                Image(systemName: "tablecells")
                                    .foregroundStyle(style.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Pin a Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isShowingTablePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
