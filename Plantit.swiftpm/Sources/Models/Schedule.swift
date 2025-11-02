import Foundation
import SwiftData

@Model
final class Schedule: Identifiable {
    @Attribute(.unique) var id: UUID
    var kind: Kind
    var cadenceRawValue: CadenceKind.RawValue
    var frequencyInDays: Int
    var weekday: Int?
    var dayOfMonth: Int?
    var nextDueAt: Date?
    var lastCompletedAt: Date?
    var plant: Plant?

    init(
        id: UUID = UUID(),
        kind: Kind,
        cadenceKind: CadenceKind = .everyNDays,
        frequencyInDays: Int = 7,
        weekday: Int? = nil,
        dayOfMonth: Int? = nil,
        lastCompletedAt: Date? = nil,
        nextDueAt: Date? = nil,
        plant: Plant? = nil
    ) {
        self.id = id
        self.kind = kind
        self.cadenceRawValue = cadenceKind.rawValue
        self.frequencyInDays = max(1, frequencyInDays)
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.lastCompletedAt = lastCompletedAt
        self.nextDueAt = nextDueAt
        self.plant = plant
        if nextDueAt == nil {
            recomputeNextDue(referenceDate: .now)
        }
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case watering
        case fertilizing
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .watering: return "Watering"
            case .fertilizing: return "Fertilizing"
            case .custom: return "Custom"
            }
        }

        var defaultActivityKind: PlantActivity.ActivityKind? {
            switch self {
            case .watering: return .water
            case .fertilizing: return .fertilize
            case .custom: return nil
            }
        }
    }

    enum CadenceKind: String, Codable, CaseIterable, Identifiable {
        case everyNDays
        case dayOfWeek
        case dayOfMonth

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .everyNDays: return "Every N Days"
            case .dayOfWeek: return "Weekly"
            case .dayOfMonth: return "Monthly"
            }
        }
    }

    var cadenceKind: CadenceKind {
        get { CadenceKind(rawValue: cadenceRawValue) ?? .everyNDays }
        set { cadenceRawValue = newValue.rawValue }
    }

    var cadenceDescription: String {
        let calendar = Calendar.current
        switch cadenceKind {
        case .everyNDays:
            return "Every \(frequencyInDays) day\(frequencyInDays == 1 ? "" : "s")"
        case .dayOfWeek:
            let weekdayIndex = (weekday ?? calendar.component(.weekday, from: .now)) - 1
            let symbol = calendar.weekdaySymbols[safe: weekdayIndex] ?? "Weekday"
            return "Every \(symbol)"
        case .dayOfMonth:
            let day = dayOfMonth ?? 1
            let ordinal = Self.ordinalFormatter.string(from: NSNumber(value: day)) ?? "day \(day)"
            return "Every \(ordinal)"
        }
    }

    var nextDueDescription: String {
        guard let nextDueAt else { return "No reminder set" }
        return nextDueAt.formatted(date: .abbreviated, time: .shortened)
    }

    var isDue: Bool {
        guard let nextDueAt else { return false }
        return nextDueAt <= Date()
    }

    func recomputeNextDue(referenceDate: Date = .now) {
        nextDueAt = Self.computeNextDueDate(
            cadenceKind: cadenceKind,
            frequencyInDays: frequencyInDays,
            weekday: weekday,
            dayOfMonth: dayOfMonth,
            lastCompletedAt: lastCompletedAt,
            referenceDate: referenceDate
        )
    }

    static func computeNextDueDate(
        cadenceKind: CadenceKind,
        frequencyInDays: Int,
        weekday: Int?,
        dayOfMonth: Int?,
        lastCompletedAt: Date?,
        referenceDate: Date = .now
    ) -> Date? {
        let calendar = Calendar.current
        let baseDate = lastCompletedAt ?? referenceDate
        switch cadenceKind {
        case .everyNDays:
            let interval = max(1, frequencyInDays)
            return calendar.date(byAdding: .day, value: interval, to: baseDate)
        case .dayOfWeek:
            let targetWeekday = weekday ?? calendar.component(.weekday, from: baseDate)
            var components = DateComponents()
            components.weekday = targetWeekday
            return calendar.nextDate(after: baseDate, matching: components, matchingPolicy: .nextTime, direction: .forward)
        case .dayOfMonth:
            let targetDay = max(1, min(dayOfMonth ?? calendar.component(.day, from: baseDate), 31))
            let startOfBase = calendar.startOfDay(for: baseDate)
            if let computed = nextMonthlyDate(from: startOfBase, day: targetDay, calendar: calendar) {
                return computed
            } else {
                return calendar.date(byAdding: .month, value: 1, to: startOfBase)
            }
        }
    }

    private static func nextMonthlyDate(from base: Date, day: Int, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: base)
        guard components.year != nil else {
            return nil
        }

        let targetDay = max(1, min(day, calendar.range(of: .day, in: .month, for: base)?.count ?? day))
        components.day = targetDay
        components.hour = calendar.component(.hour, from: base)
        components.minute = calendar.component(.minute, from: base)
        var nextDate = calendar.date(from: components)

        if let candidate = nextDate, candidate > base {
            return candidate
        }

        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        if let monthAdvance = calendar.date(byAdding: nextMonthComponents, to: base) {
            var futureComponents = calendar.dateComponents([.year, .month], from: monthAdvance)
            let futureDay = max(1, min(day, calendar.range(of: .day, in: .month, for: monthAdvance)?.count ?? day))
            futureComponents.day = futureDay
            futureComponents.hour = calendar.component(.hour, from: base)
            futureComponents.minute = calendar.component(.minute, from: base)
            nextDate = calendar.date(from: futureComponents)
        }

        return nextDate
    }

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
}

extension Schedule: Hashable {
    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
