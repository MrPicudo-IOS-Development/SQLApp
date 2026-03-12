import SwiftUI

struct TableListView: View {
    @Bindable var viewModel: TableBrowserViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tables...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.tables.isEmpty {
                    ContentUnavailableView(
                        "No Tables",
                        systemImage: "tablecells.badge.ellipsis",
                        description: Text("Create tables using the SQL Editor tab")
                    )
                } else {
                    List(viewModel.tables, id: \.self) { tableName in
                        NavigationLink(value: tableName) {
                            Label(tableName, systemImage: "tablecells")
                        }
                    }
                }
            }
            .navigationTitle("Tables")
            .navigationDestination(for: String.self) { tableName in
                TableDetailView(tableName: tableName, viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadTables() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadTables()
            }
        }
    }
}
