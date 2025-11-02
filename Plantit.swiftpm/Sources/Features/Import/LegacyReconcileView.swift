import SwiftUI
import SwiftData

struct LegacyReconcileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var service: LegacyImportService
    @ObservedObject var loggingService: LoggingService

    @Query(sort: \Village.name) private var villages: [Village]

    var onComplete: (LegacyImportService.CommitResult) -> Void

    @State private var workingDraft: LegacyImportDraft?
    @State private var selectedVillageID: UUID?
    @State private var newVillageName: String = ""
    @State private var newVillageClimate: Village.Climate = .temperate
    @State private var includedActivityIDs: Set<UUID> = []
    @State private var includedScheduleIDs: Set<UUID> = []
    @State private var includeLastWateredAt: Bool = false
    @State private var lastWateredAt: Date = .now
    @State private var commitError: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if let draft = workingDraft {
                    Form {
                        plantSection(for: draft)
                        villageSection(for: draft)
                        activitiesSection(for: draft)
                        schedulesSection(for: draft)
                        unknownSection(for: draft)
                        metadataSection(for: draft)

                        if let commitError {
                            Section {
                                Text(commitError)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Draft",
                        systemImage: "tray",
                        description: Text("Import a legacy JSON file to review its contents.")
                    )
                }
            }
            .navigationTitle("Review Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { commitDraft() }
                        .disabled(workingDraft == nil)
                }
            }
        }
        .onAppear(perform: hydrateFromService)
        .onChange(of: service.draft?.sourceURL) { _ in
            hydrateFromService()
        }
    }

    private func hydrateFromService() {
        guard let draft = service.draft else {
            workingDraft = nil
            return
        }

        workingDraft = draft
        selectedVillageID = draft.plant.village?.id
        newVillageName = draft.pendingVillage?.name ?? ""
        newVillageClimate = draft.pendingVillage?.climate ?? .temperate
        includedActivityIDs = Set(draft.activities.map(\PlantActivity.id))
        includedScheduleIDs = Set(draft.schedules.map(\Schedule.id))
        includeLastWateredAt = draft.plant.lastWateredAt != nil
        lastWateredAt = draft.plant.lastWateredAt ?? .now
        commitError = nil
    }

    private func plantSection(for draft: LegacyImportDraft) -> some View {
        Section("Plant Details") {
            TextField("Name", text: Binding(
                get: { draft.plant.name },
                set: { value in updateDraft { $0.plant.name = value } }
            ))
            .textInputAutocapitalization(.words)

            TextField("Species", text: Binding(
                get: { draft.plant.species },
                set: { value in updateDraft { $0.plant.species = value } }
            ))
            .textInputAutocapitalization(.words)

            TextField("Notes", text: Binding(
                get: { draft.plant.notes },
                set: { value in updateDraft { $0.plant.notes = value } }
            ), axis: .vertical)
            .lineLimit(3...6)

            Toggle("Set Last Watered Date", isOn: Binding(
                get: { includeLastWateredAt },
                set: { newValue in
                    includeLastWateredAt = newValue
                    if !newValue {
                        updateDraft { $0.plant.lastWateredAt = nil }
                    }
                }
            ))

            if includeLastWateredAt {
                DatePicker("Last Watered", selection: Binding(
                    get: { lastWateredAt },
                    set: { value in
                        lastWateredAt = value
                        updateDraft { $0.plant.lastWateredAt = value }
                    }
                ), displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    private func villageSection(for _: LegacyImportDraft) -> some View {
        Section("Village") {
            Picker("Existing Village", selection: Binding(
                get: { selectedVillageID },
                set: { value in
                    selectedVillageID = value
                    if value != nil {
                        newVillageName = ""
                    }
                }
            )) {
                Text("None").tag(UUID?.none)
                ForEach(villages) { village in
                    Text(village.name).tag(Optional(village.id))
                }
            }

            TextField("New Village Name", text: $newVillageName)
                .textInputAutocapitalization(.words)
                .disabled(selectedVillageID != nil)

            Picker("Climate", selection: $newVillageClimate) {
                ForEach(Village.Climate.allCases, id: \.self) { climate in
                    Text(climate.rawValue.capitalized).tag(climate)
                }
            }
            .disabled(selectedVillageID != nil)
        }
    }

    private func activitiesSection(for draft: LegacyImportDraft) -> some View {
        Section("Activities") {
            if draft.activities.isEmpty {
                Text("No activities found in legacy data.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.activities) { activity in
                    Toggle(isOn: Binding(
                        get: { includedActivityIDs.contains(activity.id) },
                        set: { newValue in
                            if newValue {
                                includedActivityIDs.insert(activity.id)
                            } else {
                                includedActivityIDs.remove(activity.id)
                            }
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(activity.kind.description)
                                .font(.headline)
                            Text(dateFormatter.string(from: activity.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !activity.note.isEmpty {
                                Text(activity.note)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
    }

    private func schedulesSection(for draft: LegacyImportDraft) -> some View {
        Section("Schedules") {
            if draft.schedules.isEmpty {
                Text("No schedules found in legacy data.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.schedules) { schedule in
                    Toggle(isOn: Binding(
                        get: { includedScheduleIDs.contains(schedule.id) },
                        set: { newValue in
                            if newValue {
                                includedScheduleIDs.insert(schedule.id)
                            } else {
                                includedScheduleIDs.remove(schedule.id)
                            }
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(schedule.kind.displayName)
                                .font(.headline)
                            Text("Every \(schedule.frequencyInDays) day(s)")
                                .font(.subheadline)
                            if let lastCompletedAt = schedule.lastCompletedAt {
                                Text("Last completed: \(dateFormatter.string(from: lastCompletedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func unknownSection(for draft: LegacyImportDraft) -> some View {
        Section("Unknown Fields") {
            if draft.unknownFields.isEmpty {
                Text("All fields were mapped successfully.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.unknownFields.keys.sorted(), id: \.self) { key in
                    if let fields = draft.unknownFields[key] {
                        DisclosureGroup(key) {
                            ForEach(fields.keys.sorted(), id: \.self) { fieldKey in
                                if let value = fields[fieldKey] {
                                    LabeledContent(fieldKey, value: value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func metadataSection(for draft: LegacyImportDraft) -> some View {
        Section("Summary") {
            LabeledContent("Source", value: draft.sourceURL.lastPathComponent)
            if let legacyID = draft.metadata.legacyIdentifier {
                LabeledContent("Legacy ID", value: legacyID.uuidString)
                    .textSelection(.enabled)
            }
            LabeledContent("Activities", value: "\(draft.activities.count)")
            LabeledContent("Schedules", value: "\(draft.schedules.count)")
            if draft.totalUnknownFieldCount > 0 {
                LabeledContent("Unknown Fields", value: "\(draft.totalUnknownFieldCount)")
            }
        }
    }

    private func commitDraft() {
        guard var draft = workingDraft else {
            commitError = ServiceError.missingDraft.errorDescription
            return
        }

        if !includeLastWateredAt {
            draft.plant.lastWateredAt = nil
        } else {
            draft.plant.lastWateredAt = lastWateredAt
        }

        draft.activities = draft.activities.filter { includedActivityIDs.contains($0.id) }
        draft.schedules = draft.schedules.filter { includedScheduleIDs.contains($0.id) }

        if let selectedVillageID, let selectedVillage = villages.first(where: { $0.id == selectedVillageID }) {
            draft.plant.village = selectedVillage
            draft.pendingVillage = nil
        } else {
            draft.plant.village = nil
            let trimmedName = newVillageName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                draft.pendingVillage = .init(name: trimmedName, climate: newVillageClimate)
            } else {
                draft.pendingVillage = nil
            }
        }

        let selectedVillage = villages.first(where: { $0.id == selectedVillageID })

        do {
            let result = try service.commit(
                draft: draft,
                context: modelContext,
                selectedVillage: selectedVillage,
                newVillageName: newVillageName,
                newVillageClimate: newVillageClimate,
                existingVillages: villages
            )
            loggingService.log(
                "Imported legacy plant \(result.plant.name) with \(result.activityCount) activities and \(result.scheduleCount) schedules.",
                category: .importExport
            )
            onComplete(result)
            dismiss()
        } catch {
            commitError = error.localizedDescription
        }
    }

    private func updateDraft(_ mutate: (inout LegacyImportDraft) -> Void) {
        guard var draft = workingDraft else { return }
        mutate(&draft)
        workingDraft = draft
    }

    private enum ServiceError: LocalizedError {
        case missingDraft

        var errorDescription: String? {
            switch self {
            case .missingDraft:
                return "The draft could not be found."
            }
        }
    }
}

#Preview("Legacy Reconcile") {
    let service = LegacyImportService()
    let logging = LoggingService()
    return LegacyReconcileView(service: service, loggingService: logging) { _ in }
}
