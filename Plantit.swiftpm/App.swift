import SwiftUI
import SwiftData

@main
struct PlantitApp: App {
    @StateObject private var appConfig = AppConfig()
    @StateObject private var loggingService = LoggingService()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appConfig)
                .environmentObject(loggingService)
                .modelContainer(persistenceController.container)
        }
    }
}
