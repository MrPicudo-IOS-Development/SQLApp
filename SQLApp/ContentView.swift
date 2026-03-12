import SwiftUI

struct ContentView: View {
    @State private var queryEditorVM: QueryEditorViewModel
    @State private var tableBrowserVM: TableBrowserViewModel

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
