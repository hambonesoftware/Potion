import SwiftUI

struct PlantFormState {
    var name: String = ""
    var species: String = ""
    var notes: String = ""
    var village: Village?
    var hasWateringSchedule: Bool
    var wateringFrequency: Int

    init(
        name: String = "",
        species: String = "",
        notes: String = "",
        village: Village? = nil,
        wateringFrequency: Int? = nil
    ) {
        self.name = name
        self.species = species
        self.notes = notes
        self.village = village
        if let wateringFrequency {
            self.hasWateringSchedule = true
            self.wateringFrequency = max(1, wateringFrequency)
        } else {
            self.hasWateringSchedule = false
            self.wateringFrequency = 7
        }
    }

    init(plant: Plant) {
        let wateringSchedule = plant.schedules.first { $0.kind == .watering }
        self.init(
            name: plant.name,
            species: plant.species,
            notes: plant.notes,
            village: plant.village,
            wateringFrequency: wateringSchedule?.frequencyInDays
        )
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var wateringFrequencyInDays: Int? {
        hasWateringSchedule ? wateringFrequency : nil
    }
}

struct PlantEditorForm: View {
    @Binding var state: PlantFormState
    let villages: [Village]

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $state.name)
                TextField("Species", text: $state.species)
            }

            Section("Village") {
                Picker("Assign to", selection: bindingForVillage()) {
                    Text("Unassigned").tag(UUID?.none)
                    ForEach(villages) { village in
                        Text(village.name).tag(Optional(village.id))
                    }
                }
            }

            Section("Watering Schedule") {
                Toggle("Track watering", isOn: $state.hasWateringSchedule.animation())
                if state.hasWateringSchedule {
                    Stepper(value: $state.wateringFrequency, in: 1...60) {
                        Text("Every \(state.wateringFrequency) day\(state.wateringFrequency == 1 ? "" : "s")")
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $state.notes)
                    .frame(minHeight: 120)
            }
        }
    }

    private func bindingForVillage() -> Binding<UUID?> {
        Binding(
            get: { state.village?.id },
            set: { id in
                state.village = villages.first(where: { $0.id == id })
            }
        )
    }
}
