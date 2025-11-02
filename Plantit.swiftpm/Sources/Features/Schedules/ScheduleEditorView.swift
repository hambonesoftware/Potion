import SwiftUI
import SwiftData

struct ScheduleDraft: Identifiable, Hashable {
    var id: UUID
    var kind: Schedule.Kind
    var cadenceKind: Schedule.CadenceKind
    var frequencyInDays: Int
    var weekday: Int
    var dayOfMonth: Int
    var lastCompletedAt: Date?
    var nextDueAt: Date?

    init(schedule: Schedule) {
        let calendar = Calendar.current
        id = schedule.id
        kind = schedule.kind
        cadenceKind = schedule.cadenceKind
        frequencyInDays = max(1, schedule.frequencyInDays)
        weekday = schedule.weekday ?? calendar.firstWeekday
        dayOfMonth = schedule.dayOfMonth ?? calendar.component(.day, from: .now)
        lastCompletedAt = schedule.lastCompletedAt
        nextDueAt = schedule.nextDueAt ?? Schedule.computeNextDueDate(
            cadenceKind: schedule.cadenceKind,
            frequencyInDays: schedule.frequencyInDays,
            weekday: schedule.weekday,
            dayOfMonth: schedule.dayOfMonth,
            lastCompletedAt: schedule.lastCompletedAt
        )
    }

    init(kind: Schedule.Kind, referenceDate: Date = .now) {
        let calendar = Calendar.current
        id = UUID()
        self.kind = kind
        cadenceKind = .everyNDays
        frequencyInDays = 7
        weekday = calendar.firstWeekday
        dayOfMonth = calendar.component(.day, from: referenceDate)
        lastCompletedAt = nil
        nextDueAt = Schedule.computeNextDueDate(
            cadenceKind: .everyNDays,
            frequencyInDays: frequencyInDays,
            weekday: weekday,
            dayOfMonth: dayOfMonth,
            lastCompletedAt: nil,
            referenceDate: referenceDate
        )
    }

    mutating func recompute(referenceDate: Date = .now) {
        frequencyInDays = max(1, frequencyInDays)
        let calendar = Calendar.current
        weekday = (1...7).contains(weekday) ? weekday : calendar.firstWeekday
        dayOfMonth = min(max(dayOfMonth, 1), 31)
        nextDueAt = Schedule.computeNextDueDate(
            cadenceKind: cadenceKind,
            frequencyInDays: frequencyInDays,
            weekday: cadenceKind == .dayOfWeek ? weekday : nil,
            dayOfMonth: cadenceKind == .dayOfMonth ? dayOfMonth : nil,
            lastCompletedAt: lastCompletedAt,
            referenceDate: referenceDate
        )
    }
}

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @EnvironmentObject private var notificationService: NotificationService

    @ObservedObject private var plant: Plant

    @State private var drafts: [ScheduleDraft] = []
    @State private var newScheduleKind: Schedule.Kind = .watering
    @State private var errorMessage: String?

    init(plant: Plant) {
        self._plant = ObservedObject(initialValue: plant)
    }

    var body: some View {
        Form {
            if drafts.isEmpty {
                Section("Schedules") {
                    Text("No schedules configured")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach($drafts) { $draft in
                    ScheduleDraftEditor(draft: $draft)
                }
                .onDelete(perform: removeDrafts)
            }

            Section("Add Schedule") {
                Picker("Type", selection: $newScheduleKind) {
                    ForEach(Schedule.Kind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                Button {
                    addDraft()
                } label: {
                    Label("Add Schedule", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { persistChanges() }
            }
        }
        .onAppear(perform: configureDrafts)
        .alert(
            "Unable to Save",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            presenting: errorMessage
        ) { _ in
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func configureDrafts() {
        drafts = plant.schedules
            .sorted(by: { $0.kind.displayName < $1.kind.displayName })
            .map(ScheduleDraft.init)
    }

    private func addDraft() {
        var draft = ScheduleDraft(kind: newScheduleKind)
        draft.recompute()
        drafts.append(draft)
    }

    private func removeDrafts(at offsets: IndexSet) {
        drafts.remove(atOffsets: offsets)
    }

    private func persistChanges() {
        do {
            let draftIDs = Set(drafts.map { $0.id })
            var schedulesToSchedule: [Schedule] = []

            for schedule in plant.schedules where !draftIDs.contains(schedule.id) {
                notificationService.cancelReminder(for: schedule)
                modelContext.delete(schedule)
            }

            for draft in drafts {
                if let schedule = plant.schedules.first(where: { $0.id == draft.id }) {
                    schedule.kind = draft.kind
                    schedule.cadenceKind = draft.cadenceKind
                    schedule.frequencyInDays = draft.frequencyInDays
                    schedule.weekday = draft.cadenceKind == .dayOfWeek ? draft.weekday : nil
                    schedule.dayOfMonth = draft.cadenceKind == .dayOfMonth ? draft.dayOfMonth : nil
                    schedule.lastCompletedAt = draft.lastCompletedAt
                    schedule.nextDueAt = draft.nextDueAt
                    schedule.recomputeNextDue()
                    schedulesToSchedule.append(schedule)
                } else {
                    let schedule = Schedule(
                        id: draft.id,
                        kind: draft.kind,
                        cadenceKind: draft.cadenceKind,
                        frequencyInDays: draft.frequencyInDays,
                        weekday: draft.cadenceKind == .dayOfWeek ? draft.weekday : nil,
                        dayOfMonth: draft.cadenceKind == .dayOfMonth ? draft.dayOfMonth : nil,
                        lastCompletedAt: draft.lastCompletedAt,
                        nextDueAt: draft.nextDueAt,
                        plant: plant
                    )
                    schedule.recomputeNextDue()
                    plant.schedules.append(schedule)
                    schedulesToSchedule.append(schedule)
                }
            }

            try modelContext.save()
            loggingService.log("Updated schedules for \(plant.name)", category: .data)

            for schedule in schedulesToSchedule {
                Task { @MainActor in
                    await notificationService.scheduleReminder(for: schedule)
                }
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            loggingService.log("Failed to save schedules: \(error.localizedDescription)", category: .data)
        }
    }
}

private struct ScheduleDraftEditor: View {
    @Binding var draft: ScheduleDraft

    private let calendar = Calendar.current

    var body: some View {
        Section(draft.kind.displayName) {
            Picker("Task", selection: $draft.kind) {
                ForEach(Schedule.Kind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }

            Picker("Cadence", selection: $draft.cadenceKind) {
                ForEach(Schedule.CadenceKind.allCases) { cadence in
                    Text(cadence.displayName).tag(cadence)
                }
            }

            switch draft.cadenceKind {
            case .everyNDays:
                Stepper(value: $draft.frequencyInDays, in: 1...120) {
                    Text("Every \(draft.frequencyInDays) day\(draft.frequencyInDays == 1 ? "" : "s")")
                }
            case .dayOfWeek:
                Picker("Weekday", selection: $draft.weekday) {
                    ForEach(Array(calendar.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol).tag(index + 1)
                    }
                }
            case .dayOfMonth:
                Stepper(value: $draft.dayOfMonth, in: 1...31) {
                    Text("Day \(draft.dayOfMonth) of month")
                }
            }

            if let next = draft.nextDueAt {
                LabeledContent("Next Due", value: next.formatted(date: .abbreviated, time: .shortened))
            }

            if let last = draft.lastCompletedAt {
                LabeledContent("Last Done", value: last.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .onChange(of: draft.cadenceKind) { _ in
            draft.recompute()
        }
        .onChange(of: draft.frequencyInDays) { _ in
            draft.recompute()
        }
        .onChange(of: draft.weekday) { _ in
            draft.recompute()
        }
        .onChange(of: draft.dayOfMonth) { _ in
            draft.recompute()
        }
    }
}
