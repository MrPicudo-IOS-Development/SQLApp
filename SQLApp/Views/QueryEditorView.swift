import SwiftUI

struct QueryEditorView: View {
    @Bindable var viewModel: QueryEditorViewModel
    @FocusState private var isEditorFocused: Bool
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

    private var hasResults: Bool {
        viewModel.queryResult != nil || viewModel.errorMessage != nil || viewModel.executionMessage != nil
    }

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
