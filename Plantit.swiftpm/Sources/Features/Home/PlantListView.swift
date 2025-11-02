import SwiftUI
import SwiftData

struct PlantListView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]
    @Binding var selection: Plant?
    var village: Village?

    init(selection: Binding<Plant?>, village: Village?) {
        _selection = selection
        self.village = village
    }

    var body: some View {
        List(filteredPlants, selection: $selection) { plant in
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                Text(plant.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if filteredPlants.isEmpty {
                ContentUnavailableView(
                    "No Plants",
                    systemImage: "drop",
                    description: Text("Plants will appear here once added.")
                )
            }
        }
        .navigationTitle("Plants")
    }

    private var filteredPlants: [Plant] {
        guard let village else { return plants }
        return plants.filter { $0.village?.id == village.id }
    }
}
