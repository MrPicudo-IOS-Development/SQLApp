import SwiftUI

/// Displays a navigable list of all user-created tables in the database.
///
/// Shows one of four states depending on the ViewModel's data:
/// - **Loading**: A progress indicator while tables are being fetched.
/// - **Error**: An error message if the table list could not be loaded.
/// - **Empty**: A placeholder prompting the user to create tables via the SQL Editor.
/// - **Table list**: A `List` of table names, each navigating to ``TableDetailView``.
///
/// The table list is loaded automatically when the view appears (via `.task`)
/// and can be manually refreshed using the toolbar refresh button.
///
/// Uses `NavigationStack` with value-based `NavigationLink` and
/// `.navigationDestination` for type-safe programmatic navigation.
struct TableListView: View {

    /// The ViewModel that manages the table list state and provides data access.
    @Bindable var viewModel: TableBrowserViewModel

    /// The settings ViewModel providing the accent color for table icons.
    let settingsViewModel: SettingsViewModel

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
                            Label {
                                Text(tableName)
                            } icon: {
                                Image(systemName: "tablecells")
                                    .foregroundStyle(settingsViewModel.keywordColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tables")
            .navigationDestination(for: String.self) { tableName in
                TableDetailView(tableName: tableName, viewModel: viewModel, settingsViewModel: settingsViewModel)
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
