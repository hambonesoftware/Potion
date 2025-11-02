import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loggingService: LoggingService
    @EnvironmentObject private var notificationService: NotificationService

    @Query(
        FetchDescriptor<Schedule>(
            sortBy: [SortDescriptor(\Schedule.nextDueAt, order: .forward)],
            animation: .default
        )
    ) private var schedules: [Schedule]

    @State private var alertMessage: String?

    private var calendar: Calendar { Calendar.current }
    private var startOfToday: Date { calendar.startOfDay(for: Date()) }
    private var endOfToday: Date { calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date().addingTimeInterval(86_400) }

    private var overdueSchedules: [Schedule] {
        schedules
            .filter { schedule in
                guard let due = schedule.nextDueAt else { return false }
                return due < startOfToday
            }
            .sorted { ($0.nextDueAt ?? .distantPast) < ($1.nextDueAt ?? .distantPast) }
    }

    private var dueTodaySchedules: [Schedule] {
        schedules
            .filter { schedule in
                guard let due = schedule.nextDueAt else { return false }
                return due >= startOfToday && due < endOfToday
            }
            .sorted { ($0.nextDueAt ?? .distantFuture) < ($1.nextDueAt ?? .distantFuture) }
    }

    private var completedTodaySchedules: [Schedule] {
        schedules
            .filter { schedule in
                guard let done = schedule.lastCompletedAt else { return false }
                return done >= startOfToday && done < endOfToday
            }
            .sorted { ($0.lastCompletedAt ?? .distantPast) > ($1.lastCompletedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                if overdueSchedules.isEmpty && dueTodaySchedules.isEmpty && completedTodaySchedules.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("You're all caught up today.")
                    )
                    .listRowInsets(EdgeInsets())
                }

                if !overdueSchedules.isEmpty {
                    Section("Overdue") {
                        ForEach(overdueSchedules) { schedule in
                            UpcomingScheduleRow(
                                schedule: schedule,
                                onComplete: { complete(schedule) },
                                onSnooze: { snooze(schedule) }
                            )
                        }
                    }
                }

                if !dueTodaySchedules.isEmpty {
                    Section("Due Today") {
                        ForEach(dueTodaySchedules) { schedule in
                            UpcomingScheduleRow(
                                schedule: schedule,
                                onComplete: { complete(schedule) },
                                onSnooze: { snooze(schedule) }
                            )
                        }
                    }
                }

                if !completedTodaySchedules.isEmpty {
                    Section("Completed Today") {
                        ForEach(completedTodaySchedules) { schedule in
                            UpcomingScheduleRow(
                                schedule: schedule,
                                onComplete: { complete(schedule) },
                                onSnooze: { snooze(schedule) },
                                showActions: false
                            )
                        }
                    }
                }
            }
            .navigationTitle("Upcoming")
        }
        .alert(
            "Action Failed",
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

    private func complete(_ schedule: Schedule) {
        Task { @MainActor in
            do {
                let repository = PlantRepository(context: modelContext)
                try await repository.complete(schedule: schedule)
                await notificationService.scheduleReminder(for: schedule)
                if let plantName = schedule.plant?.name {
                    loggingService.log("Completed \(schedule.kind.displayName.lowercased()) for \(plantName)", category: .data)
                }
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to complete schedule: \(error.localizedDescription)", category: .data)
            }
        }
    }

    private func snooze(_ schedule: Schedule) {
        Task { @MainActor in
            do {
                let repository = PlantRepository(context: modelContext)
                try repository.snooze(schedule: schedule)
                await notificationService.scheduleReminder(for: schedule)
                if let plantName = schedule.plant?.name {
                    loggingService.log("Snoozed \(schedule.kind.displayName.lowercased()) for \(plantName)", category: .data)
                }
            } catch {
                alertMessage = error.localizedDescription
                loggingService.log("Failed to snooze schedule: \(error.localizedDescription)", category: .data)
            }
        }
    }
}

private struct UpcomingScheduleRow: View {
    @Bindable var schedule: Schedule
    var onComplete: () -> Void
    var onSnooze: () -> Void
    var showActions: Bool = true

    init(schedule: Schedule, onComplete: @escaping () -> Void, onSnooze: @escaping () -> Void, showActions: Bool = true) {
        self._schedule = Bindable(schedule)
        self.onComplete = onComplete
        self.onSnooze = onSnooze
        self.showActions = showActions
    }

    private var dueDescription: String {
        if let due = schedule.nextDueAt {
            return due.formatted(date: .abbreviated, time: .shortened)
        }
        return "No due date"
    }

    var body: some View {
        NavigationLink {
            PlantDetailView(plant: schedule.plant)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(schedule.plant?.name ?? "Unknown Plant")
                    .font(.headline)
                Text(schedule.kind.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Next: \(dueDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if showActions {
                    HStack {
                        Button {
                            onComplete()
                        } label: {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            onSnooze()
                        } label: {
                            Label("Snooze", systemImage: "clock")
                        }
                        .buttonStyle(.bordered)
                    }
                    .buttonBorderShape(.capsule)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}
