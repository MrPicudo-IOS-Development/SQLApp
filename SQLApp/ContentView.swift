import SwiftUI

/// The root view of the application, providing tab-based navigation between
/// the SQL editor and the table browser.
///
/// Acts as the composition root for the view layer: it receives a
/// ``DatabaseServiceProtocol`` instance via dependency injection and creates
/// the ViewModels for each tab. ViewModels are stored as `@State` properties
/// to preserve their state across tab switches and view re-evaluations.
///
/// Contains two tabs:
/// - **SQL Editor**: Powered by ``QueryEditorView`` and ``QueryEditorViewModel``.
/// - **Tables**: Powered by ``TableListView`` and ``TableBrowserViewModel``.
struct ContentView: View {

    /// The ViewModel for the SQL editor tab, preserved across tab switches.
    @State private var queryEditorVM: QueryEditorViewModel

    /// The ViewModel for the table browser tab, preserved across tab switches.
    @State private var tableBrowserVM: TableBrowserViewModel

    /// Creates the root view with both ViewModels initialized from the shared database service.
    ///
    /// - Parameter databaseService: The database service shared across both tabs
    ///   for executing SQL operations. Injected from ``SQLAppApp``.
    init(databaseService: any DatabaseServiceProtocol) {
        self._queryEditorVM = State(
            initialValue: QueryEditorViewModel(databaseService: databaseService)
        )
        self._tableBrowserVM = State(
            initialValue: TableBrowserViewModel(databaseService: databaseService)
        )
    }

    var body: some View {
        TabView {
            Tab("SQL Editor", systemImage: "terminal") {
                QueryEditorView(viewModel: queryEditorVM)
            }

            Tab("Tables", systemImage: "tablecells") {
                TableListView(viewModel: tableBrowserVM)
            }
        }
    }
}

#Preview {
    ContentView(databaseService: SQLiteDatabaseService(databaseName: "Preview.sqlite"))
}
