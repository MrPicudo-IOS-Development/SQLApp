import SwiftUI

@main
struct SQLAppApp: App {
    private let databaseService: any DatabaseServiceProtocol = SQLiteDatabaseService()

    var body: some Scene {
        WindowGroup {
            ContentView(databaseService: databaseService)
        }
    }
}
