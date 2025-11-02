import Foundation
import SwiftData

struct LegacyImportDraft {
    struct PendingVillage {
        var name: String
        var climate: Village.Climate
    }

    struct PayloadMetadata {
        let legacyIdentifier: UUID?
        let activityCount: Int
        let scheduleCount: Int
    }

    let sourceURL: URL
    var plant: Plant
    var activities: [PlantActivity]
    var schedules: [Schedule]
    var unknownFields: [String: [String: String]]
    var pendingVillage: PendingVillage?
    let metadata: PayloadMetadata

    var totalUnknownFieldCount: Int {
        unknownFields.values.reduce(0) { $0 + $1.count }
    }
}

struct LegacyPlantPayload: Codable {
    let plant: LegacyPlant
    let activities: [LegacyActivity]
    let schedules: [LegacySchedule]
    let unknownFields: [String: String]

    init(plant: LegacyPlant, activities: [LegacyActivity], schedules: [LegacySchedule], unknownFields: [String: String]) {
        self.plant = plant
        self.activities = activities
        self.schedules = schedules
        self.unknownFields = unknownFields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        guard let plantKey = DynamicCodingKey(stringValue: "plant") else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Missing plant key"))
        }

        plant = try container.decode(LegacyPlant.self, forKey: plantKey)
        let activitiesKey = DynamicCodingKey(stringValue: "activities")
        activities = try activitiesKey.flatMap { try container.decodeIfPresent([LegacyActivity].self, forKey: $0) } ?? []
        let schedulesKey = DynamicCodingKey(stringValue: "schedules")
        schedules = try schedulesKey.flatMap { try container.decodeIfPresent([LegacySchedule].self, forKey: $0) } ?? []

        var unknown: [String: String] = [:]
        let known = ["plant", "activities", "schedules"]
        for key in container.allKeys where !known.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                unknown[key.stringValue] = value.displayString
            }
        }
        unknownFields = unknown
    }
}

struct LegacyPlant: Codable {
    let id: UUID?
    let name: String
    let species: String?
    let notes: String?
    let lastWateredAt: Date?
    let createdAt: Date?
    let villageName: String?
    let villageClimate: String?
    let unknownFields: [String: String]

    init(
        id: UUID?,
        name: String,
        species: String?,
        notes: String?,
        lastWateredAt: Date?,
        createdAt: Date?,
        villageName: String?,
        villageClimate: String?,
        unknownFields: [String: String]
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.notes = notes
        self.lastWateredAt = lastWateredAt
        self.createdAt = createdAt
        self.villageName = villageName
        self.villageClimate = villageClimate
        self.unknownFields = unknownFields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let idKey = DynamicCodingKey(stringValue: "id")
        let legacyID = try idKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        id = legacyID.flatMap(UUID.init(uuidString:))

        let nameKey = DynamicCodingKey(stringValue: "name")
        name = (try nameKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) } ?? "Imported Plant").trimmingCharacters(in: .whitespacesAndNewlines)

        let speciesKey = DynamicCodingKey(stringValue: "species")
        species = try speciesKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }

        let notesKey = DynamicCodingKey(stringValue: "notes")
        notes = try notesKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }

        let lastWateredKey = DynamicCodingKey(stringValue: "lastWateredAt")
        lastWateredAt = try lastWateredKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }

        let createdKey = DynamicCodingKey(stringValue: "createdAt")
        createdAt = try createdKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }

        let villageNameKey = DynamicCodingKey(stringValue: "village")
        if let villageString = try villageNameKey.flatMap({ try container.decodeIfPresent(String.self, forKey: $0) }) {
            villageName = villageString
            villageClimate = nil
        } else if let nestedKey = villageNameKey, container.contains(nestedKey) {
            let nested = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: nestedKey)
            let nestedNameKey = DynamicCodingKey(stringValue: "name")
            villageName = try nestedNameKey.flatMap { try nested.decodeIfPresent(String.self, forKey: $0) }
            let climateKey = DynamicCodingKey(stringValue: "climate")
            villageClimate = try climateKey.flatMap { try nested.decodeIfPresent(String.self, forKey: $0) }
        } else {
            let villageNameFallbackKey = DynamicCodingKey(stringValue: "villageName")
            villageName = try villageNameFallbackKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
            let climateKey = DynamicCodingKey(stringValue: "villageClimate")
            villageClimate = try climateKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        }

        var unknown: [String: String] = [:]
        let known = ["id", "name", "species", "notes", "lastWateredAt", "createdAt", "village", "villageName", "villageClimate"]
        for key in container.allKeys where !known.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                unknown[key.stringValue] = value.displayString
            }
        }
        unknownFields = unknown
    }
}

struct LegacyActivity: Codable {
    let id: UUID?
    let kind: PlantActivity.ActivityKind?
    let note: String?
    let createdAt: Date?
    let unknownFields: [String: String]

    init(id: UUID?, kind: PlantActivity.ActivityKind?, note: String?, createdAt: Date?, unknownFields: [String: String]) {
        self.id = id
        self.kind = kind
        self.note = note
        self.createdAt = createdAt
        self.unknownFields = unknownFields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let idKey = DynamicCodingKey(stringValue: "id")
        let legacyID = try idKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        id = legacyID.flatMap(UUID.init(uuidString:))

        let kindKey = DynamicCodingKey(stringValue: "kind")
        let typeKey = DynamicCodingKey(stringValue: "type")
        let rawKind = try kindKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
            ?? typeKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        kind = LegacyActivity.kind(from: rawKind)

        let noteKey = DynamicCodingKey(stringValue: "note")
        let notesKey = DynamicCodingKey(stringValue: "notes")
        note = try noteKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
            ?? notesKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }

        let createdKey = DynamicCodingKey(stringValue: "createdAt")
        let timestampKey = DynamicCodingKey(stringValue: "timestamp")
        createdAt = try createdKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }
            ?? timestampKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }

        var unknown: [String: String] = [:]
        let known = ["id", "kind", "type", "note", "notes", "createdAt", "timestamp"]
        for key in container.allKeys where !known.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                unknown[key.stringValue] = value.displayString
            }
        }
        unknownFields = unknown
    }

    private static func kind(from rawValue: String?) -> PlantActivity.ActivityKind? {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !value.isEmpty else {
            return nil
        }

        if let kind = PlantActivity.ActivityKind(rawValue: value) {
            return kind
        }

        switch value {
        case "watered", "watering":
            return .water
        case "fertilized", "fertiliser", "fertilize":
            return .fertilize
        default:
            return .note
        }
    }
}

struct LegacySchedule: Codable {
    let id: UUID?
    let kind: Schedule.Kind?
    let cadenceKind: Schedule.CadenceKind?
    let frequencyInDays: Int?
    let weekday: Int?
    let dayOfMonth: Int?
    let nextDueAt: Date?
    let lastCompletedAt: Date?
    let unknownFields: [String: String]

    init(
        id: UUID?,
        kind: Schedule.Kind?,
        cadenceKind: Schedule.CadenceKind?,
        frequencyInDays: Int?,
        weekday: Int?,
        dayOfMonth: Int?,
        nextDueAt: Date?,
        lastCompletedAt: Date?,
        unknownFields: [String: String]
    ) {
        self.id = id
        self.kind = kind
        self.cadenceKind = cadenceKind
        self.frequencyInDays = frequencyInDays
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.nextDueAt = nextDueAt
        self.lastCompletedAt = lastCompletedAt
        self.unknownFields = unknownFields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let idKey = DynamicCodingKey(stringValue: "id")
        let legacyID = try idKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        id = legacyID.flatMap(UUID.init(uuidString:))

        let kindKey = DynamicCodingKey(stringValue: "kind")
        let typeKey = DynamicCodingKey(stringValue: "type")
        let rawKind = try kindKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
            ?? typeKey.flatMap { try container.decodeIfPresent(String.self, forKey: $0) }
        kind = LegacySchedule.kind(from: rawKind)

        let frequencyKeys = ["frequency", "frequencyInDays", "interval", "intervalDays"]
        var parsedFrequency: Int?
        for keyName in frequencyKeys {
            if let key = DynamicCodingKey(stringValue: keyName), let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                parsedFrequency = value
                break
            }
            if let key = DynamicCodingKey(stringValue: keyName), let valueString = try? container.decodeIfPresent(String.self, forKey: key), let value = Int(valueString) {
                parsedFrequency = value
                break
            }
        }
        let cadenceKindKey = DynamicCodingKey(stringValue: "cadenceKind")
        if let rawCadence = try cadenceKindKey.flatMap({ try container.decodeIfPresent(String.self, forKey: $0) }),
           let parsed = Schedule.CadenceKind(rawValue: rawCadence) {
            cadenceKind = parsed
        } else {
            cadenceKind = nil
        }

        let weekdayKey = DynamicCodingKey(stringValue: "weekday")
        weekday = try weekdayKey.flatMap { try container.decodeIfPresent(Int.self, forKey: $0) }

        let dayOfMonthKey = DynamicCodingKey(stringValue: "dayOfMonth")
        dayOfMonth = try dayOfMonthKey.flatMap { try container.decodeIfPresent(Int.self, forKey: $0) }

        let nextDueKey = DynamicCodingKey(stringValue: "nextDueAt")
        nextDueAt = try nextDueKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }

        frequencyInDays = parsedFrequency

        let lastCompletedKey = DynamicCodingKey(stringValue: "lastCompletedAt")
        let updatedKey = DynamicCodingKey(stringValue: "lastDoneAt")
        lastCompletedAt = try lastCompletedKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }
            ?? updatedKey.flatMap { try container.decodeIfPresent(Date.self, forKey: $0) }

        var unknown: [String: String] = [:]
        let known = [
            "id",
            "kind",
            "type",
            "frequency",
            "frequencyInDays",
            "interval",
            "intervalDays",
            "lastCompletedAt",
            "lastDoneAt",
            "cadenceKind",
            "weekday",
            "dayOfMonth",
            "nextDueAt"
        ]
        for key in container.allKeys where !known.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                unknown[key.stringValue] = value.displayString
            }
        }
        unknownFields = unknown
    }

    private static func kind(from rawValue: String?) -> Schedule.Kind? {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !value.isEmpty else {
            return nil
        }

        if let kind = Schedule.Kind(rawValue: value) {
            return kind
        }

        switch value {
        case "water", "watering":
            return .watering
        case "fertilize", "fertilizing", "fertiliser":
            return .fertilizing
        default:
            return .custom
        }
    }
}

extension LegacyPlantPayload {
    func makeDraft(existingVillages: [Village], sourceURL: URL) -> LegacyImportDraft {
        let plantModel = Plant(
            id: plant.id ?? UUID(),
            name: plant.name.isEmpty ? "Imported Plant" : plant.name,
            species: plant.species ?? "Unknown",
            lastWateredAt: plant.lastWateredAt,
            notes: plant.notes ?? "",
            createdAt: plant.createdAt ?? .now
        )

        var pendingVillage: LegacyImportDraft.PendingVillage?
        if let villageName = plant.villageName?.trimmingCharacters(in: .whitespacesAndNewlines), !villageName.isEmpty {
            if let existing = existingVillages.first(where: { $0.name.caseInsensitiveCompare(villageName) == .orderedSame }) {
                plantModel.village = existing
            } else {
                let rawClimate = plant.villageClimate?.lowercased()
                let climate = rawClimate.flatMap(Village.Climate.init(rawValue:)) ?? .temperate
                pendingVillage = .init(name: villageName, climate: climate)
            }
        }

        let activityModels: [PlantActivity] = activities.map { activity in
            let createdAt = activity.createdAt ?? plant.createdAt ?? Date()
            let kind = activity.kind ?? .note
            let activityModel = PlantActivity(
                id: activity.id ?? UUID(),
                createdAt: createdAt,
                kind: kind,
                note: activity.note ?? ""
            )
            activityModel.plant = plantModel
            return activityModel
        }

        let scheduleModels: [Schedule] = schedules.map { schedule in
            let frequency = max(schedule.frequencyInDays ?? 7, 1)
            let cadenceKind = schedule.cadenceKind ?? .everyNDays
            let scheduleModel = Schedule(
                id: schedule.id ?? UUID(),
                kind: schedule.kind ?? .custom,
                cadenceKind: cadenceKind,
                frequencyInDays: frequency,
                weekday: cadenceKind == .dayOfWeek ? schedule.weekday : nil,
                dayOfMonth: cadenceKind == .dayOfMonth ? schedule.dayOfMonth : nil,
                lastCompletedAt: schedule.lastCompletedAt,
                nextDueAt: schedule.nextDueAt,
                plant: plantModel
            )
            if schedule.nextDueAt == nil {
                scheduleModel.recomputeNextDue()
            }
            return scheduleModel
        }

        var unknown: [String: [String: String]] = [:]
        if !unknownFields.isEmpty {
            unknown["payload"] = unknownFields
        }
        if !plant.unknownFields.isEmpty {
            unknown["plant"] = plant.unknownFields
        }
        for (index, activity) in activities.enumerated() where !activity.unknownFields.isEmpty {
            unknown["activity[\(index)]"] = activity.unknownFields
        }
        for (index, schedule) in schedules.enumerated() where !schedule.unknownFields.isEmpty {
            unknown["schedule[\(index)]"] = schedule.unknownFields
        }

        let metadata = LegacyImportDraft.PayloadMetadata(
            legacyIdentifier: plant.id,
            activityCount: activities.count,
            scheduleCount: schedules.count
        )

        return LegacyImportDraft(
            sourceURL: sourceURL,
            plant: plantModel,
            activities: activityModels,
            schedules: scheduleModels,
            unknownFields: unknown,
            pendingVillage: pendingVillage,
            metadata: metadata
        )
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        if let number = try? container.decode(Double.self) {
            self = .number(number)
            return
        }
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }

        if let objectContainer = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            var dictionary: [String: JSONValue] = [:]
            for key in objectContainer.allKeys {
                dictionary[key.stringValue] = try objectContainer.decode(JSONValue.self, forKey: key)
            }
            self = .object(dictionary)
            return
        }

        if var arrayContainer = try? decoder.unkeyedContainer() {
            var array: [JSONValue] = []
            while !arrayContainer.isAtEnd {
                let value = try arrayContainer.decode(JSONValue.self)
                array.append(value)
            }
            self = .array(array)
            return
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
        )
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .string(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .number(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .bool(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case let .object(dictionary):
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in dictionary {
                if let codingKey = DynamicCodingKey(stringValue: key) {
                    try container.encode(value, forKey: codingKey)
                }
            }
        case let .array(array):
            var container = encoder.unkeyedContainer()
            for value in array {
                try container.encode(value)
            }
        }
    }

    var displayString: String {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return Self.numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
        case let .bool(value):
            return value ? "true" : "false"
        case .null:
            return "null"
        case let .object(dictionary):
            let sorted = dictionary.sorted { $0.key < $1.key }
            let entries = sorted.map { "\($0): \($1.displayString)" }
            return "{" + entries.joined(separator: ", ") + "}"
        case let .array(array):
            let values = array.map { $0.displayString }
            return "[" + values.joined(separator: ", ") + "]"
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
