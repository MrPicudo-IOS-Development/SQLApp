import SwiftUI

/// The root view of the application, providing tab-based navigation between
/// the SQL editor, the table browser, and the settings screen.
///
/// Acts as the composition root for the view layer: it receives a
/// ``DatabaseServiceProtocol`` instance via dependency injection and creates
/// the ViewModels for each tab. ViewModels are stored as `@State` properties
/// to preserve their state across tab switches and view re-evaluations.
///
/// Contains three tabs:
/// - **SQL Editor**: Powered by ``QueryEditorView`` and ``QueryEditorViewModel``.
/// - **Tables**: Powered by ``TableListView`` and ``TableBrowserViewModel``.
/// - **Settings**: Powered by ``SettingsView`` and ``SettingsViewModel``.
///
/// The ``SettingsViewModel`` is shared between the Settings tab and the SQL Editor
/// tab so that keyword color changes are reflected immediately in the editor.
struct ContentView: View {

    /// The ViewModel for the SQL editor tab, preserved across tab switches.
    @State private var queryEditorVM: QueryEditorViewModel

    /// The ViewModel for the table browser tab, preserved across tab switches.
    @State private var tableBrowserVM: TableBrowserViewModel

    /// The ViewModel for settings, shared with the SQL editor for keyword color.
    @State private var settingsVM = SettingsViewModel()

    /// Creates the root view with all ViewModels initialized from the shared database service.
    ///
    /// - Parameter databaseService: The database service shared across tabs
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
                QueryEditorView(
                    viewModel: queryEditorVM,
                    settingsViewModel: settingsVM
                )
            }

            Tab("Tables", systemImage: "tablecells") {
                TableListView(viewModel: tableBrowserVM)
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView(viewModel: settingsVM)
            }
        }
    }
}

#Preview {
    ContentView(databaseService: SQLiteDatabaseService(databaseName: "Preview.sqlite"))
}
