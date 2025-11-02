import SwiftUI

struct PlantDetailView: View {
    var plant: Plant?

    private var lastWateredDescription: String {
        guard let date = plant?.lastWateredAt else {
            return "Never"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let plant {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plant.name)
                        .font(.largeTitle)
                        .bold()
                    Text(plant.species)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Grid(alignment: .leading) {
                    GridRow {
                        Text("Village")
                        Spacer()
                        Text(plant.village?.name ?? "Unassigned")
                    }
                    GridRow {
                        Text("Last Watered")
                        Spacer()
                        Text(lastWateredDescription)
                    }
                }

                if !plant.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(plant.notes)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a Plant",
                    systemImage: "leaf",
                    description: Text("Choose a plant from the list to view details.")
                )
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Plant Detail") {
    ContentPreviewBuilder.make(selectedPlant: true)
}
