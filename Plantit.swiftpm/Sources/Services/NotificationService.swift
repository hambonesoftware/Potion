import Foundation
import SwiftData

#if canImport(UserNotifications)
import UserNotifications
#endif

@MainActor
final class NotificationService: NSObject, ObservableObject {
    enum AuthorizationState {
        case notDetermined
        case denied
        case authorized
        case provisional
        case notAvailable
    }

    @Published private(set) var authorizationState: AuthorizationState = .notDetermined

    private let modelContainer: ModelContainer
    private let loggingService: LoggingService

#if canImport(UserNotifications)
    private let notificationCenter = UNUserNotificationCenter.current()

    private enum ActionIdentifier: String {
        case complete = "plantit.complete"
        case snooze = "plantit.snooze"
    }

    private let categoryIdentifier = "plantit.schedule"
#endif

    init(modelContainer: ModelContainer, loggingService: LoggingService) {
        self.modelContainer = modelContainer
        self.loggingService = loggingService
        super.init()

#if canImport(UserNotifications)
        notificationCenter.delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
#else
        authorizationState = .notAvailable
#endif
    }

    func requestAuthorization() async {
#if canImport(UserNotifications)
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            loggingService.log(
                granted ? "Notifications authorized" : "Notifications denied",
                category: .notifications
            )
        } catch {
            loggingService.log("Notification authorization failed: \(error.localizedDescription)", category: .notifications)
        }
#else
        authorizationState = .notAvailable
#endif
    }

    func refreshAuthorizationStatus() async {
#if canImport(UserNotifications)
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            authorizationState = .notDetermined
        case .denied:
            authorizationState = .denied
        case .authorized:
            authorizationState = .authorized
        case .provisional:
            authorizationState = .provisional
        case .ephemeral:
            authorizationState = .authorized
        @unknown default:
            authorizationState = .denied
        }
#else
        authorizationState = .notAvailable
#endif
    }

    func scheduleReminder(for schedule: Schedule) async {
#if canImport(UserNotifications)
        guard authorizationState == .authorized || authorizationState == .provisional else { return }
        let identifier = schedule.id.uuidString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let dueDate = schedule.nextDueAt else { return }

        let content = UNMutableNotificationContent()
        content.title = schedule.plant?.name ?? "Plant Reminder"
        content.body = bodyText(for: schedule)
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["scheduleID": identifier]

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await notificationCenter.add(request)
            loggingService.log("Scheduled reminder for \(schedule.plant?.name ?? "plant")", category: .notifications)
        } catch {
            loggingService.log("Failed to schedule reminder: \(error.localizedDescription)", category: .notifications)
        }
#else
        // Notifications unavailable on this platform.
#endif
    }

    func cancelReminder(for schedule: Schedule) {
#if canImport(UserNotifications)
        let identifier = schedule.id.uuidString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
#endif
    }

#if canImport(UserNotifications)
    private func registerCategories() {
        let complete = UNNotificationAction(
            identifier: ActionIdentifier.complete.rawValue,
            title: "Complete",
            options: [.authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: ActionIdentifier.snooze.rawValue,
            title: "Snooze",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [complete, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
    }

    private func bodyText(for schedule: Schedule) -> String {
        var parts = [schedule.kind.displayName]
        parts.append(schedule.cadenceDescription)
        if let due = schedule.nextDueAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append("Due \(formatter.string(from: due))")
        }
        return parts.joined(separator: " • ")
    }

    private func handleAction(_ action: ActionIdentifier, scheduleID: UUID) {
        Task { @MainActor in
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<Schedule>(
                predicate: #Predicate { $0.id == scheduleID }
            )

            guard let schedule = try? context.fetch(descriptor).first else { return }
            let repository = PlantRepository(context: context)

            switch action {
            case .complete:
                do {
                    try await repository.complete(schedule: schedule)
                    await scheduleReminder(for: schedule)
                    loggingService.log("Completed via notification for \(schedule.plant?.name ?? "plant")", category: .notifications)
                } catch {
                    loggingService.log("Notification complete failed: \(error.localizedDescription)", category: .notifications)
                }
            case .snooze:
                do {
                    try repository.snooze(schedule: schedule)
                    await scheduleReminder(for: schedule)
                    loggingService.log("Snoozed via notification for \(schedule.plant?.name ?? "plant")", category: .notifications)
                } catch {
                    loggingService.log("Notification snooze failed: \(error.localizedDescription)", category: .notifications)
                }
            }
        }
    }
#endif
}

#if canImport(UserNotifications)
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if
            let scheduleIDString = response.notification.request.content.userInfo["scheduleID"] as? String,
            let scheduleID = UUID(uuidString: scheduleIDString)
        {
            if let action = ActionIdentifier(rawValue: response.actionIdentifier) {
                Task { @MainActor [weak self] in
                    self?.handleAction(action, scheduleID: scheduleID)
                }
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
#endif
