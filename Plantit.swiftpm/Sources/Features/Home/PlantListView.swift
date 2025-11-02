import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @Query(sort: \Plant.name) private var plants: [Plant]
    @Query(sort: \Village.name) private var villages: [Village]

    @Binding var selection: Plant?
    var village: Village?

    @State private var isPresentingEditor = false
    @State private var editorMode: EditorMode = .create
    @State private var formState = PlantFormState()
    @State private var alertMessage: String?

    private var repository: PlantRepository {
        PlantRepository(context: modelContext)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 16)]
    }

    init(selection: Binding<Plant?>, village: Village?) {
        _selection = selection
        self.village = village
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredPlants) { plant in
                    PlantTileView(plant: plant, isSelected: selection?.id == plant.id)
                        .contextMenu { contextMenu(for: plant) }
                        .onTapGesture {
                            selection = plant
                        }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
        .toolbar { toolbar }
        .sheet(isPresented: $isPresentingEditor) {
            NavigationStack {
                PlantEditorForm(state: $formState, villages: villages)
                    .navigationTitle(editorMode.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isPresentingEditor = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { persistPlant() }
                                .disabled(!formState.isValid)
                        }
                    }
            }
        }
        .alert(
            "Unable to update plant",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            ),
            presenting: alertMessage
        ) { _ in
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private var filteredPlants: [Plant] {
        guard let village else { return plants }
        return plants.filter { $0.village?.id == village.id }
    }

    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                beginCreatingPlant()
            } label: {
                Label("Add Plant", systemImage: "plus")
            }
        }
    }

    private func beginCreatingPlant() {
        editorMode = .create
        let defaultVillage = village ?? selection?.village ?? villages.first
        formState = PlantFormState(village: defaultVillage)
        isPresentingEditor = true
    }

    private func beginEditing(_ plant: Plant) {
        editorMode = .edit(plant)
        formState = PlantFormState(plant: plant)
        isPresentingEditor = true
    }

    private func persistPlant() {
        Task {
            do {
                switch editorMode {
                case .create:
                    let plant = try await repository.createPlant(
                        name: formState.name,
                        species: formState.species,
                        notes: formState.notes,
                        village: formState.village,
                        wateringFrequencyInDays: formState.wateringFrequencyInDays
                    )
                    selection = plant
                    loggingService.log("Created plant: \(plant.name)", category: .data)
                case let .edit(plant):
                    try await repository.updatePlant(
                        plant,
                        name: formState.name,
                        species: formState.species,
                        notes: formState.notes,
                        village: formState.village,
                        wateringFrequencyInDays: formState.wateringFrequencyInDays
                    )
                    selection = plant
                    loggingService.log("Updated plant: \(plant.name)", category: .data)
                }
                isPresentingEditor = false
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to persist plant: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func removePlant(_ plant: Plant) {
        Task {
            do {
                try await repository.deletePlant(plant)
                if selection?.id == plant.id {
                    selection = nil
                }
                loggingService.log("Deleted plant: \(plant.name)", category: .data)
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to delete plant: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func contextMenu(for plant: Plant) -> some View {
        Group {
            Button {
                beginEditing(plant)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                removePlant(plant)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private enum EditorMode {
        case create
        case edit(Plant)

        var title: String {
            switch self {
            case .create: return "New Plant"
            case .edit: return "Edit Plant"
            }
        }
    }
}

private struct PlantTileView: View {
    @Bindable var plant: Plant
    let isSelected: Bool

    init(plant: Plant, isSelected: Bool) {
        self._plant = Bindable(plant)
        self.isSelected = isSelected
    }

    private var lastWateredDescription: String {
        guard let date = plant.lastWateredAt else { return "Never" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var wateringScheduleDescription: String {
        guard let schedule = plant.schedules.first(where: { $0.kind == .watering }) else { return "" }
        var parts: [String] = [schedule.cadenceDescription]
        if let next = schedule.nextDueAt {
            parts.append("Next due \(next.formatted(date: .abbreviated, time: .shortened))")
        }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(plant.species)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let village = plant.village {
                    Text(village.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("Last watered: \(lastWateredDescription)", systemImage: "drop")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !wateringScheduleDescription.isEmpty {
                    Label(wateringScheduleDescription, systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
