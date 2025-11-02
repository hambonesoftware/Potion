import Foundation

enum BackupExporter {
    private static let emptyArchiveBase64 = "UEsDBAoAAAAAAAMJYlsGsKHdAwAAAAMAAAANABwAbWFuaWZlc3QuanNvblVUCQAD9a4GafWuBml1eAsAAQQAAAAABAAAAAB7fQpQSwECHgMKAAAAAAADCWJbBrCh3QMAAAADAAAADQAYAAAAAAABAAAApIEAAAAAbWFuaWZlc3QuanNvblVUBQAD9a4GaXV4CwABBAAAAAAEAAAAAFBLBQYAAAAAAQABAFMAAABKAAAAAAA="

    static func exportEmptyArchive(date: Date = .now, fileManager: FileManager = .default) throws -> URL {
        guard let archiveData = Data(base64Encoded: emptyArchiveBase64) else {
            throw BackupError.encodingFailure
        }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let filename = "PlantitBackup-\(formatter.string(from: date)).zip"
        let destination = documentsURL.appendingPathComponent(filename)
        try archiveData.write(to: destination, options: .atomic)
        return destination
    }

    enum BackupError: LocalizedError {
        case encodingFailure

        var errorDescription: String? {
            switch self {
            case .encodingFailure:
                return "Could not prepare backup archive."
            }
        }
    }
}
