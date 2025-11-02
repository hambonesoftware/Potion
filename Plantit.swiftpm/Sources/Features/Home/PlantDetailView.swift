import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @EnvironmentObject private var notificationService: NotificationService
    @Query(sort: \Village.name) private var villages: [Village]

    var plant: Plant?

    @State private var isPresentingEditor = false
    @State private var isPresentingScheduleEditor = false
    @State private var isPresentingNote = false
    @State private var formState = PlantFormState()
    @State private var noteText = ""
    @State private var alertMessage: String?

    private var repository: PlantRepository {
        PlantRepository(context: modelContext)
    }

    private var lastWateredDescription: String {
        guard let date = plant?.lastWateredAt else {
            return "Never"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var wateringScheduleDescription: String {
        guard let schedule = plant?.schedules.first(where: { $0.kind == .watering }) else {
            return "No schedule"
        }
        var components: [String] = [schedule.cadenceDescription]
        if let next = schedule.nextDueAt {
            components.append("Next due \(next.formatted(date: .abbreviated, time: .shortened))")
        }
        if let last = schedule.lastCompletedAt {
            components.append("Last done \(last.formatted(date: .abbreviated, time: .shortened))")
        }
        return components.joined(separator: " • ")
    }

    var body: some View {
        Group {
            if let plant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(for: plant)
                        schedule(for: plant)
                        quickActions
                        photosSection(for: plant)
                        activitiesSection(for: plant)
                        notesSection(for: plant)
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    "Select a Plant",
                    systemImage: "leaf",
                    description: Text("Choose a plant from the list to view details.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle(plant?.name ?? "Plant")
        .toolbar { toolbar }
        .sheet(isPresented: $isPresentingEditor) {
            NavigationStack {
                PlantEditorForm(state: $formState, villages: villages)
                    .navigationTitle("Edit Plant")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isPresentingEditor = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { persistEdits() }
                                .disabled(!formState.isValid)
                        }
                    }
            }
        }
        .sheet(isPresented: Binding(
            get: { isPresentingScheduleEditor && plant != nil },
            set: { isPresentingScheduleEditor = $0 }
        )) {
            if let plant {
                NavigationStack {
                    ScheduleEditorView(plant: plant)
                        .environmentObject(loggingService)
                        .environmentObject(notificationService)
                }
            }
        }
        .sheet(isPresented: $isPresentingNote) {
            NavigationStack {
                Form {
                    Section("Quick Note") {
                        TextEditor(text: $noteText)
                            .frame(minHeight: 160)
                    }
                }
                .navigationTitle("Add Note")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresentingNote = false
                            noteText = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveNote() }
                            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert(
            "Action failed",
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
            if plant != nil {
                Button("Edit") { beginEditing() }
            }
        }
    }

    private func header(for plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.name)
                    .font(.largeTitle)
                    .bold()
                Text(plant.species)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if let village = plant.village {
                    Label(village.name, systemImage: "map")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label("Last watered: \(lastWateredDescription)", systemImage: "drop")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func schedule(for plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schedules")
                    .font(.headline)
                Spacer()
                Button("Manage") {
                    isPresentingScheduleEditor = true
                }
                .font(.subheadline)
            }

            if plant.schedules.isEmpty {
                Text("No schedules configured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(plant.schedules.sorted(by: { $0.nextDueAt ?? .distantFuture < $1.nextDueAt ?? .distantFuture })) { schedule in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(schedule.kind.displayName)
                                .font(.subheadline)
                                .bold()
                            Text(schedule.cadenceDescription)
                                .font(.subheadline)
                            if let next = schedule.nextDueAt {
                                Text("Next due \(next.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let last = schedule.lastCompletedAt {
                                Text("Last done \(last.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .quaternarySystemFill))
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemBackground))
        )
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            HStack(spacing: 12) {
                quickActionButton(title: "Water", systemImage: "drop.fill", tint: .blue) {
                    recordActivity(.water)
                }
                quickActionButton(title: "Fertilize", systemImage: "leaf.fill", tint: .green) {
                    recordActivity(.fertilize)
                }
                quickActionButton(title: "Note", systemImage: "square.and.pencil", tint: .orange) {
                    noteText = ""
                    isPresentingNote = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func photosSection(for plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)
                Spacer()
                Button {
                    addPlaceholderPhoto()
                } label: {
                    Label("Add Placeholder", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
            PlantPhotoPlaceholderGrid(photos: plant.photos)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activitiesSection(for plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Timeline")
                .font(.headline)
            if plant.activities.isEmpty {
                ContentUnavailableView(
                    "No Activity",
                    systemImage: "calendar.badge.clock",
                    description: Text("Use the quick actions to log care events.")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(plant.activities.sorted(by: { $0.createdAt > $1.createdAt })) { activity in
                        ActivityTimelineRow(activity: activity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notesSection(for plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            if plant.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No notes yet.")
                    .foregroundStyle(.secondary)
            } else {
                Text(plant.notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func quickActionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    private func beginEditing() {
        guard let plant else { return }
        formState = PlantFormState(plant: plant)
        isPresentingEditor = true
    }

    private func persistEdits() {
        guard let plant else { return }
        Task {
            do {
                try await repository.updatePlant(
                    plant,
                    name: formState.name,
                    species: formState.species,
                    notes: formState.notes,
                    village: formState.village,
                    wateringFrequencyInDays: formState.wateringFrequencyInDays
                )
                loggingService.log("Updated plant: \(plant.name)", category: .data)
                isPresentingEditor = false
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to update plant: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func recordActivity(_ kind: PlantActivity.ActivityKind) {
        guard let plant else { return }
        Task {
            do {
                _ = try await repository.recordActivity(for: plant, kind: kind)
                await scheduleNotifications(for: kind)
                loggingService.log("Added \(kind.description.lowercased()) activity for \(plant.name)", category: .data)
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to record activity: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let plant, !trimmed.isEmpty else { return }
        Task {
            do {
                _ = try await repository.recordActivity(for: plant, kind: .note, note: trimmed)
                await scheduleNotifications(for: .note)
                loggingService.log("Added note to \(plant.name)", category: .data)
                noteText = ""
                isPresentingNote = false
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to add note: \(error.localizedDescription)", category: .data)
            }
        }
    }

    @MainActor
    private func scheduleNotifications(for kind: PlantActivity.ActivityKind) async {
        guard let plant else { return }
        let relevantSchedules = plant.schedules.filter { schedule in
            schedule.kind.defaultActivityKind == kind
        }
        for schedule in relevantSchedules {
            await notificationService.scheduleReminder(for: schedule)
        }
    }

    private func addPlaceholderPhoto() {
        guard let plant else { return }
        Task {
            do {
                _ = try await repository.addPlaceholderPhoto(to: plant)
                loggingService.log("Added placeholder photo to \(plant.name)", category: .data)
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to add photo: \(error.localizedDescription)", category: .data)
            }
        }
    }
}

private struct PlantPhotoPlaceholderGrid: View {
    let photos: [PlantPhoto]

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]

    var body: some View {
        if photos.isEmpty {
            ContentUnavailableView(
                "No Photos",
                systemImage: "photo",
                description: Text("Placeholder photos will appear here.")
            )
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(photos) { photo in
                    PhotoPlaceholderCell(photo: photo)
                }
            }
        }
    }
}

private struct PhotoPlaceholderCell: View {
    @Bindable var photo: PlantPhoto

    init(photo: PlantPhoto) {
        self._photo = Bindable(photo)
    }

    private var tintColor: Color {
        let palette: [Color] = [.green.opacity(0.7), .blue.opacity(0.7), .teal.opacity(0.7), .orange.opacity(0.7), .purple.opacity(0.7)]
        let index = abs(photo.colorSeed) % palette.count
        return palette[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tintColor)
                    .frame(height: 120)
                Image(systemName: photo.placeholderSymbolName)
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.9))
            }
            if !photo.caption.isEmpty {
                Text(photo.caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ActivityTimelineRow: View {
    @Bindable var activity: PlantActivity

    init(activity: PlantActivity) {
        self._activity = Bindable(activity)
    }

    private var timestamp: String {
        activity.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.kind.iconName)
                .foregroundStyle(.accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.kind.description)
                    .font(.headline)
                Text(timestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !activity.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(activity.note)
                        .font(.subheadline)
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#Preview("Plant Detail") {
    ContentPreviewBuilder.make(selectedPlant: true)
}
