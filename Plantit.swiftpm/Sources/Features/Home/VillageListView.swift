import SwiftUI
import SwiftData

struct VillageListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @Query(sort: \Village.name) private var villages: [Village]

    @Binding var selection: Village?
    @State private var isPresentingForm = false
    @State private var formMode: FormMode = .create
    @State private var formState = VillageFormState()
    @State private var alertMessage: String?

    var body: some View {
        List(selection: $selection) {
            ForEach(villages) { village in
                VStack(alignment: .leading, spacing: 4) {
                    Text(village.name)
                        .font(.headline)
                    Text(village.climate.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .tag(village)
                .onTapGesture { selection = village }
                .contextMenu { editMenu(for: village) }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        removeVillage(village)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        beginEditing(village)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
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
        .toolbar { toolbar }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                VillageFormView(state: $formState)
                    .navigationTitle(formMode.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isPresentingForm = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { persistVillage() }
                                .disabled(!formState.isValid)
                        }
                    }
            }
        }
        .alert(
            "Unable to save village",
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

    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                beginCreatingVillage()
            } label: {
                Label("Add Village", systemImage: "plus")
            }
        }
    }

    private var repository: VillageRepository {
        VillageRepository(context: modelContext)
    }

    private func beginCreatingVillage() {
        formMode = .create
        formState = VillageFormState(
            name: suggestedVillageName(),
            climate: .temperate
        )
        isPresentingForm = true
    }

    private func beginEditing(_ village: Village) {
        formMode = .edit(village)
        formState = VillageFormState(name: village.name, climate: village.climate)
        isPresentingForm = true
    }

    private func persistVillage() {
        Task {
            do {
                switch formMode {
                case .create:
                    let village = try await repository.createVillage(name: formState.name, climate: formState.climate)
                    selection = village
                    loggingService.log("Created village: \(village.name)", category: .data)
                case let .edit(village):
                    try await repository.updateVillage(village, name: formState.name, climate: formState.climate)
                    selection = village
                    loggingService.log("Updated village: \(village.name)", category: .data)
                }
                isPresentingForm = false
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to persist village: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func removeVillage(_ village: Village) {
        Task {
            do {
                try await repository.deleteVillage(village)
                if selection?.id == village.id {
                    selection = nil
                }
                loggingService.log("Deleted village: \(village.name)", category: .data)
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to delete village: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func editMenu(for village: Village) -> some View {
        Group {
            Button {
                beginEditing(village)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                removeVillage(village)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func suggestedVillageName() -> String {
        let base = "Village"
        let existingNames = Set(villages.map { $0.name })
        if !existingNames.contains(base) {
            return base
        }

        var index = villages.count + 1
        while existingNames.contains("\(base) \(index)") {
            index += 1
        }
        return "\(base) \(index)"
    }
}

private enum FormMode {
    case create
    case edit(Village)

    var title: String {
        switch self {
        case .create: return "New Village"
        case .edit: return "Edit Village"
        }
    }
}

private struct VillageFormState {
    var name: String = ""
    var climate: Village.Climate = .temperate

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct VillageFormView: View {
    @Binding var state: VillageFormState

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $state.name)
                Picker("Climate", selection: $state.climate) {
                    ForEach(Village.Climate.allCases, id: \._self) { climate in
                        Text(climate.rawValue.capitalized)
                            .tag(climate)
                    }
                }
            }
        }
    }
}

