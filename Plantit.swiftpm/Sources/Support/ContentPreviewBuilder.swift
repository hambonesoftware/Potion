import SwiftUI
import SwiftData

enum ContentPreviewBuilder {
    static func make(showDevPanel: Bool = false, selectedPlant: Bool = false) -> some View {
        let config = AppConfig(enableDeveloperPanel: showDevPanel)
        let logging = LoggingService()
        let controller = PersistenceController.preview
        let container = controller.container
        let context = ModelContext(container)
        let villages = (try? context.fetch(FetchDescriptor<Village>())) ?? []
        let plants = (try? context.fetch(FetchDescriptor<Plant>())) ?? []

        let initialVillage = selectedPlant ? plants.first?.village ?? villages.first : villages.first
        let initialPlant = selectedPlant ? plants.first : nil

        return ContentView(initialVillage: initialVillage, initialPlant: initialPlant)
            .environmentObject(config)
            .environmentObject(logging)
            .modelContainer(container)
    }
}
