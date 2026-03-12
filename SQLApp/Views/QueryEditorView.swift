import SwiftUI

struct QueryEditorView: View {
    @Bindable var viewModel: QueryEditorViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sqlInputSection
                Divider()
                controlBar
                Divider()
                resultsSection
            }
            .navigationTitle("SQL Editor")
        }
    }

    // MARK: - SQL Input

    private var sqlInputSection: some View {
        TextEditor(text: $viewModel.sqlText)
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 120, maxHeight: 200)
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack {
            Button {
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
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.clearResults()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Results

    private var resultsSection: some View {
        Group {
            if let error = viewModel.errorMessage {
                ScrollView {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let result = viewModel.queryResult {
                ResultsTableView(result: result)
            } else {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "text.page",
                    description: Text("Write a SQL query and tap Run")
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
}
