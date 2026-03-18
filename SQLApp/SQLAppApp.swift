//
//  SQLAppApp.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// The entry point of the SQLApp application.
///
/// Creates two shared ``SQLiteDatabaseService`` instances and injects them
/// into the view hierarchy through ``ContentView``:
/// - **userDatabaseService** (`user_database.sqlite`): The user's sandbox database
///   where all user-created tables, queries, and history are stored.
/// - **appDatabaseService** (`app_database.sqlite`): An app-controlled database
///   reserved for exercise data. Does not include query history.
///
/// Both database files are stored in the app's Documents directory and persist
/// across app launches.
@main
struct SQLAppApp: App {

    /// The database service for the user's sandbox — all existing functionality uses this.
    private let userDatabaseService: any DatabaseServiceProtocol

    /// The database service for app-controlled exercise data.
    /// Created here but not yet wired to any UI — reserved for future exercise features.
    private let appDatabaseService: any DatabaseServiceProtocol

    init() {
        Self.migrateLegacyDatabaseIfNeeded()

        self.userDatabaseService = SQLiteDatabaseService(
            databaseName: "user_database.sqlite",
            enableHistory: true
        )
        self.appDatabaseService = SQLiteDatabaseService(
            databaseName: "app_database.sqlite",
            enableHistory: false
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                userDatabaseService: userDatabaseService,
                appDatabaseService: appDatabaseService
            )
        }
    }

    // MARK: - Migration

    /// Renames the legacy `SQLApp.sqlite` file to `user_database.sqlite` if it exists
    /// and the new name does not already exist. This preserves user data across the update.
    private static func migrateLegacyDatabaseIfNeeded() {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let legacyURL = documentsURL.appendingPathComponent("SQLApp.sqlite")
        let newURL = documentsURL.appendingPathComponent("user_database.sqlite")

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: legacyURL.path),
           !fileManager.fileExists(atPath: newURL.path) {
            try? fileManager.moveItem(at: legacyURL, to: newURL)
        }
    }
}
