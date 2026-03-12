import SwiftUI

/// The entry point of the SQLApp application.
///
/// Creates a single shared ``SQLiteDatabaseService`` instance and injects it
/// into the view hierarchy through ``ContentView``. This ensures the entire
/// application shares one database connection, and all ViewModels operate
/// against the same underlying SQLite database.
///
/// The database file (`SQLApp.sqlite`) is stored in the app's Documents directory
/// and persists across app launches.
@main
struct SQLAppApp: App {

    /// The shared database service instance used throughout the application.
    /// Created once at app launch and injected into ``ContentView``.
    private let databaseService: any DatabaseServiceProtocol = SQLiteDatabaseService()

    var body: some Scene {
        WindowGroup {
            ContentView(databaseService: databaseService)
        }
    }
}
