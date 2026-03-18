//
//  ContentView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// The root view of the application, providing tab-based navigation between
/// the SQL editor, the database browser, exercises, and the settings screen.
///
/// Acts as the composition root for the view layer: it receives two
/// ``DatabaseServiceProtocol`` instances via dependency injection — one for the
/// user's sandbox database and one for the app-controlled exercise database —
/// and creates the ViewModels for each tab. ViewModels are stored as `@State`
/// properties to preserve their state across tab switches and view re-evaluations.
///
/// Contains four tabs:
/// - **SQL Editor**: Powered by ``QueryEditorView`` and ``QueryEditorViewModel`` (user database).
/// - **Database**: Powered by ``DatabaseView``, ``DatabaseViewModel``, and ``TableBrowserViewModel`` (user database).
/// - **Exercises**: Powered by ``ExercisesView`` with its own ``QueryEditorViewModel`` and ``ExercisesViewModel`` (app database).
/// - **Settings**: Powered by ``SettingsView`` and ``SettingsViewModel``.
///
/// The ``SettingsViewModel`` is shared across all tabs so that keyword color
/// changes are reflected immediately everywhere.
struct ContentView: View {

    // MARK: - User Database ViewModels

    /// The ViewModel for the SQL editor tab, preserved across tab switches.
    @State private var queryEditorVM: QueryEditorViewModel

    /// The ViewModel for the table browser, used inside the Database tab.
    @State private var tableBrowserVM: TableBrowserViewModel

    /// The ViewModel for the persistent query history, used inside the Database tab.
    @State private var databaseVM: DatabaseViewModel

    // MARK: - App Database ViewModels

    /// The ViewModel for the exercises SQL editor, connected to the app database.
    @State private var exercisesEditorVM: QueryEditorViewModel

    /// Manages per-block table seeding for the Exercises tab.
    @State private var exercisesVM: ExercisesViewModel

    // MARK: - Shared

    /// The ViewModel for settings, shared across all tabs for keyword color.
    @State private var settingsVM = SettingsViewModel()

    // MARK: - Initialization

    /// Creates the root view with all ViewModels initialized from both database services.
    ///
    /// - Parameters:
    ///   - userDatabaseService: The user's sandbox database service, used by SQL Editor and Database tabs.
    ///   - appDatabaseService: The app-controlled exercise database, used by the Exercises tab.
    init(
        userDatabaseService: any DatabaseServiceProtocol,
        appDatabaseService: any DatabaseServiceProtocol
    ) {
        // User database ViewModels
        self._queryEditorVM = State(initialValue: QueryEditorViewModel(databaseService: userDatabaseService))
        self._tableBrowserVM = State(initialValue: TableBrowserViewModel(databaseService: userDatabaseService))
        self._databaseVM = State(initialValue: DatabaseViewModel(databaseService: userDatabaseService))

        // App database ViewModels
        self._exercisesEditorVM = State(initialValue: QueryEditorViewModel(databaseService: appDatabaseService))
        self._exercisesVM = State(initialValue: ExercisesViewModel(databaseService: appDatabaseService))
    }

    var body: some View {
        TabView {
            Tab("SQL Editor", systemImage: "terminal") {
                QueryEditorView(
                    viewModel: queryEditorVM,
                    settingsViewModel: settingsVM
                )
            }

            Tab("Database", systemImage: "cylinder") {
                DatabaseView(
                    databaseViewModel: databaseVM,
                    tableBrowserViewModel: tableBrowserVM,
                    settingsViewModel: settingsVM
                )
            }

            Tab("Exercises", systemImage: "book") {
                ExercisesView(
                    queryEditorViewModel: exercisesEditorVM,
                    settingsViewModel: settingsVM,
                    exercisesViewModel: exercisesVM
                )
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView(viewModel: settingsVM)
            }
        }
    }
}

#Preview {
    ContentView(
        userDatabaseService: SQLiteDatabaseService(databaseName: "Preview.sqlite"),
        appDatabaseService: SQLiteDatabaseService(databaseName: "PreviewApp.sqlite", enableHistory: false)
    )
}
