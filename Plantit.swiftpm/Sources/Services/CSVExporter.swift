import Foundation

enum CSVExporter {
    struct Document {
        let filename: String
        let contents: String
        let rowCount: Int
    }

    static func plantsCSV(from plants: [ExportedData.PlantRecord]) -> Document {
        var rows: [[String]] = [[
            "id",
            "name",
            "species",
            "notes",
            "created_at",
            "last_watered_at",
            "village_id",
            "village_name"
        ]]

        for plant in plants {
            rows.append([
                plant.id.uuidString,
                plant.name,
                plant.species,
                plant.notes,
                isoString(from: plant.createdAt),
                plant.lastWateredAt.map { isoString(from: $0) } ?? "",
                plant.villageID?.uuidString ?? "",
                plant.villageName ?? ""
            ])
        }

        return makeDocument(filename: "plants.csv", rows: rows)
    }

    static func activitiesCSV(from activities: [ExportedData.ActivityRecord]) -> Document {
        var rows: [[String]] = [[
            "id",
            "plant_id",
            "kind",
            "note",
            "created_at"
        ]]

        for activity in activities {
            rows.append([
                activity.id.uuidString,
                activity.plantID.uuidString,
                activity.kind,
                activity.note,
                isoString(from: activity.createdAt)
            ])
        }

        return makeDocument(filename: "activities.csv", rows: rows)
    }

    static func schedulesCSV(from schedules: [ExportedData.ScheduleRecord]) -> Document {
        var rows: [[String]] = [[
            "id",
            "plant_id",
            "kind",
            "cadence_kind",
            "frequency_in_days",
            "weekday",
            "day_of_month",
            "next_due_at",
            "last_completed_at"
        ]]

        for schedule in schedules {
            rows.append([
                schedule.id.uuidString,
                schedule.plantID.uuidString,
                schedule.kind,
                schedule.cadenceKind,
                String(schedule.frequencyInDays),
                schedule.weekday.map(String.init) ?? "",
                schedule.dayOfMonth.map(String.init) ?? "",
                schedule.nextDueAt.map { isoString(from: $0) } ?? "",
                schedule.lastCompletedAt.map { isoString(from: $0) } ?? ""
            ])
        }

        return makeDocument(filename: "schedules.csv", rows: rows)
    }

    private static func makeDocument(filename: String, rows: [[String]]) -> Document {
        let csvString = rows.map { row in
            row.map { escape($0) }.joined(separator: ",")
        }.joined(separator: "\n") + "\n"

        let rowCount = max(rows.count - 1, 0)
        return Document(filename: filename, contents: csvString, rowCount: rowCount)
    }

    private static func escape(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private static func isoString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
}
