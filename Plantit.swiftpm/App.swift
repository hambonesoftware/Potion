import SwiftUI
import SwiftData

@main
struct PlantitApp: App {
    @StateObject private var appConfig: AppConfig
    @StateObject private var loggingService: LoggingService
    @StateObject private var notificationService: NotificationService
    private let persistenceController: PersistenceController

    init() {
        let persistenceController = PersistenceController.shared
        let loggingService = LoggingService()
        let appConfig = AppConfig()
        _appConfig = StateObject(wrappedValue: appConfig)
        _loggingService = StateObject(wrappedValue: loggingService)
        _notificationService = StateObject(
            wrappedValue: NotificationService(
                modelContainer: persistenceController.container,
                loggingService: loggingService
            )
        )
        self.persistenceController = persistenceController
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appConfig)
                .environmentObject(loggingService)
                .environmentObject(notificationService)
                .modelContainer(persistenceController.container)
        }
    }
}
