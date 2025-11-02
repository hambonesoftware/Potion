import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appConfig: AppConfig
    @EnvironmentObject private var loggingService: LoggingService

    @State private var selectedVillage: Village?
    @State private var selectedPlant: Plant?

    init(initialVillage: Village? = nil, initialPlant: Plant? = nil) {
        _selectedVillage = State(initialValue: initialVillage)
        _selectedPlant = State(initialValue: initialPlant)
    }

    var body: some View {
        TabView {
            NavigationSplitView {
                VillageListView(selection: $selectedVillage)
                    .environmentObject(loggingService)
            } content: {
                PlantListView(selection: $selectedPlant, village: selectedVillage)
            } detail: {
                PlantDetailView(plant: selectedPlant)
            }
            .tabItem {
                Label("Home", systemImage: "leaf")
            }
            .navigationTitle(appConfig.appDisplayName)

            if appConfig.enableDeveloperPanel {
                DevPanelView()
                    .tabItem {
                        Label("Dev", systemImage: "hammer")
                    }
            }
        }
        .task {
            loggingService.log("ContentView appeared", category: .lifecycle)
        }
    }
}

#Preview("Content") {
    ContentPreviewBuilder.make()
}
