import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appConfig: AppConfig
    @EnvironmentObject private var loggingService: LoggingService
    @EnvironmentObject private var notificationService: NotificationService

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
                    .environmentObject(loggingService)
            } detail: {
                PlantDetailView(plant: selectedPlant)
                    .environmentObject(loggingService)
                    .environmentObject(notificationService)
            }
            .tabItem {
                Label("Home", systemImage: "leaf")
            }
            .navigationTitle(appConfig.appDisplayName)

            UpcomingView()
                .environmentObject(loggingService)
                .environmentObject(notificationService)
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                }

            if appConfig.enableDeveloperPanel {
                DevPanelView()
                    .tabItem {
                        Label("Dev", systemImage: "hammer")
                    }
            }
        }
        .task {
            loggingService.log("ContentView appeared", category: .lifecycle)
            await notificationService.refreshAuthorizationStatus()
            if notificationService.authorizationState == .notDetermined {
                await notificationService.requestAuthorization()
            }
        }
        .onChange(of: selectedVillage) { newVillage in
            guard let currentPlant = selectedPlant else { return }
            if let newVillage {
                if currentPlant.village?.id != newVillage.id {
                    selectedPlant = nil
                }
            } else {
                selectedPlant = nil
            }
        }
    }
}

#Preview("Content") {
    ContentPreviewBuilder.make()
}
