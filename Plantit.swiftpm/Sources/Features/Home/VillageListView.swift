import SwiftUI
import SwiftData

struct VillageListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @Query(sort: \Village.name) private var villages: [Village]

    @Binding var selection: Village?

    var body: some View {
        List(villages, selection: $selection) { village in
            VStack(alignment: .leading, spacing: 4) {
                Text(village.name)
                    .font(.headline)
                Text(village.climate.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if villages.isEmpty {
                ContentUnavailableView(
                    "No Villages",
                    systemImage: "leaf.circle",
                    description: Text("Add a village to start tracking plants.")
                )
            }
        }
        .navigationTitle("Villages")
        .toolbar { addButton }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                addVillage()
            } label: {
                Label("Add Village", systemImage: "plus")
            }
        }
    }

    private func addVillage() {
        let newVillage = Village(name: "Village \(villages.count + 1)", climate: .temperate)
        modelContext.insert(newVillage)
        do {
            try modelContext.save()
            loggingService.log("Created village: \(newVillage.name)", category: .data)
        } catch {
            loggingService.log("Failed to create village: \(error.localizedDescription)", category: .data)
        }
    }
}
