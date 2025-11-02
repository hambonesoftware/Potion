import Foundation
import SwiftData

struct ExportedData {
    struct PlantRecord: Codable {
        let id: UUID
        let name: String
        let species: String
        let notes: String
        let createdAt: Date
        let lastWateredAt: Date?
        let villageID: UUID?
        let villageName: String?
    }

    struct ActivityRecord: Codable {
        let id: UUID
        let plantID: UUID
        let kind: String
        let note: String
        let createdAt: Date
    }

    struct ScheduleRecord: Codable {
        let id: UUID
        let plantID: UUID
        let kind: String
        let cadenceKind: String
        let frequencyInDays: Int
        let weekday: Int?
        let dayOfMonth: Int?
        let nextDueAt: Date?
        let lastCompletedAt: Date?
    }

    struct VillageRecord: Codable {
        let id: UUID
        let name: String
        let climate: String
    }

    struct PhotoRecord: Codable {
        let id: UUID
        let plantID: UUID
        let createdAt: Date
        let caption: String
        let placeholderSymbolName: String
        let colorSeed: Int
    }

    struct Metadata: Codable {
        let generatedAt: Date
        let appVersion: String
        let counts: BackupExporter.ExportCounts
    }

    let metadata: Metadata
    let plants: [PlantRecord]
    let activities: [ActivityRecord]
    let schedules: [ScheduleRecord]
    let villages: [VillageRecord]
    let photos: [PhotoRecord]
}

enum BackupExporter {
    struct ExportCounts: Codable {
        let plants: Int
        let activities: Int
        let schedules: Int
        let villages: Int
        let photos: Int
    }

    struct CSVRowCounts {
        let plants: Int
        let activities: Int
        let schedules: Int
    }

    struct ExportResult {
        let url: URL
        let counts: ExportCounts
        let csvRows: CSVRowCounts
    }

    enum BackupError: LocalizedError {
        case encodingFailure
        case zipUnavailable
        case csvRowMismatch(file: String, expected: Int, actual: Int)
        case zipFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailure:
                return "Could not prepare backup archive."
            case .zipUnavailable:
                return "Creating ZIP archives is not supported on this platform."
            case let .csvRowMismatch(file, expected, actual):
                return "Row count mismatch for \(file): expected \(expected), found \(actual)."
            case .zipFailed:
                return "Failed to package backup archive."
            }
        }
    }

    static func exportBundle(
        context: ModelContext,
        date: Date = .now,
        fileManager: FileManager = .default
    ) throws -> ExportResult {
        let data = try gatherData(context: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDirectory)
        }

        try writeJSONFiles(for: data, to: tempDirectory, encoder: encoder)
        let csvCounts = try writeCSVFiles(for: data, to: tempDirectory)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let filename = "PlantitExport-\(formatter.string(from: date)).zip"
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let destination = documentsURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        do {
            try fileManager.zipItem(at: tempDirectory, to: destination, shouldKeepParent: false)
        } catch {
            throw BackupError.zipFailed
        }
        #else
        throw BackupError.zipUnavailable
        #endif

        return ExportResult(url: destination, counts: data.metadata.counts, csvRows: csvCounts)
    }

    private static func gatherData(context: ModelContext) throws -> ExportedData {
        let plants = try context.fetch(FetchDescriptor<Plant>(sortBy: [SortDescriptor(\Plant.createdAt, order: .forward)]))
        let activities = try context.fetch(FetchDescriptor<PlantActivity>(sortBy: [SortDescriptor(\PlantActivity.createdAt, order: .forward)]))
        let schedules = try context.fetch(FetchDescriptor<Schedule>(sortBy: [SortDescriptor(\Schedule.kind, order: .forward)]))
        let villages = try context.fetch(FetchDescriptor<Village>(sortBy: [SortDescriptor(\Village.name, order: .forward)]))
        let photos = try context.fetch(FetchDescriptor<PlantPhoto>(sortBy: [SortDescriptor(\PlantPhoto.createdAt, order: .forward)]))

        let plantRecords = plants.map { plant in
            ExportedData.PlantRecord(
                id: plant.id,
                name: plant.name,
                species: plant.species,
                notes: plant.notes,
                createdAt: plant.createdAt,
                lastWateredAt: plant.lastWateredAt,
                villageID: plant.village?.id,
                villageName: plant.village?.name
            )
        }

        let activityRecords = activities.map { activity in
            ExportedData.ActivityRecord(
                id: activity.id,
                plantID: activity.plant?.id ?? activity.id,
                kind: activity.kind.rawValue,
                note: activity.note,
                createdAt: activity.createdAt
            )
        }

        let scheduleRecords = schedules.map { schedule in
            ExportedData.ScheduleRecord(
                id: schedule.id,
                plantID: schedule.plant?.id ?? schedule.id,
                kind: schedule.kind.rawValue,
                cadenceKind: schedule.cadenceKind.rawValue,
                frequencyInDays: schedule.frequencyInDays,
                weekday: schedule.weekday,
                dayOfMonth: schedule.dayOfMonth,
                nextDueAt: schedule.nextDueAt,
                lastCompletedAt: schedule.lastCompletedAt
            )
        }

        let villageRecords = villages.map { village in
            ExportedData.VillageRecord(
                id: village.id,
                name: village.name,
                climate: village.climate.rawValue
            )
        }

        let photoRecords = photos.map { photo in
            ExportedData.PhotoRecord(
                id: photo.id,
                plantID: photo.plant?.id ?? photo.id,
                createdAt: photo.createdAt,
                caption: photo.caption,
                placeholderSymbolName: photo.placeholderSymbolName,
                colorSeed: photo.colorSeed
            )
        }

        let counts = ExportCounts(
            plants: plantRecords.count,
            activities: activityRecords.count,
            schedules: scheduleRecords.count,
            villages: villageRecords.count,
            photos: photoRecords.count
        )

        let metadata = ExportedData.Metadata(
            generatedAt: .now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            counts: counts
        )

        return ExportedData(
            metadata: metadata,
            plants: plantRecords,
            activities: activityRecords,
            schedules: scheduleRecords,
            villages: villageRecords,
            photos: photoRecords
        )
    }

    private static func writeJSONFiles(for data: ExportedData, to directory: URL, encoder: JSONEncoder) throws {
        try writeJSON(data.metadata, named: "metadata.json", to: directory, encoder: encoder)
        try writeJSON(data.plants, named: "plants.json", to: directory, encoder: encoder)
        try writeJSON(data.activities, named: "activities.json", to: directory, encoder: encoder)
        try writeJSON(data.schedules, named: "schedules.json", to: directory, encoder: encoder)
        try writeJSON(data.villages, named: "villages.json", to: directory, encoder: encoder)
        try writeJSON(data.photos, named: "photos.json", to: directory, encoder: encoder)
    }

    private static func writeJSON<T: Encodable>(_ value: T, named filename: String, to directory: URL, encoder: JSONEncoder) throws {
        let jsonData = try encoder.encode(value)
        let url = directory.appendingPathComponent(filename)
        try jsonData.write(to: url, options: .atomic)
    }

    private static func writeCSVFiles(for data: ExportedData, to directory: URL) throws -> CSVRowCounts {
        let plantCSV = CSVExporter.plantsCSV(from: data.plants)
        let activityCSV = CSVExporter.activitiesCSV(from: data.activities)
        let scheduleCSV = CSVExporter.schedulesCSV(from: data.schedules)

        try plantCSV.contents.write(to: directory.appendingPathComponent(plantCSV.filename), atomically: true, encoding: .utf8)
        try activityCSV.contents.write(to: directory.appendingPathComponent(activityCSV.filename), atomically: true, encoding: .utf8)
        try scheduleCSV.contents.write(to: directory.appendingPathComponent(scheduleCSV.filename), atomically: true, encoding: .utf8)

        guard plantCSV.rowCount == data.plants.count else {
            throw BackupError.csvRowMismatch(file: plantCSV.filename, expected: data.plants.count, actual: plantCSV.rowCount)
        }

        guard activityCSV.rowCount == data.activities.count else {
            throw BackupError.csvRowMismatch(file: activityCSV.filename, expected: data.activities.count, actual: activityCSV.rowCount)
        }

        guard scheduleCSV.rowCount == data.schedules.count else {
            throw BackupError.csvRowMismatch(file: scheduleCSV.filename, expected: data.schedules.count, actual: scheduleCSV.rowCount)
        }

        return CSVRowCounts(
            plants: plantCSV.rowCount,
            activities: activityCSV.rowCount,
            schedules: scheduleCSV.rowCount
        )
    }
}
