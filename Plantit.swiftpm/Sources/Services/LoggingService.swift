import Foundation

@MainActor
final class LoggingService: ObservableObject {
    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let category: Category
    }

    enum Category: String, CaseIterable {
        case lifecycle
        case data
        case backup
        case importExport
        case general
        case notifications
    }

    @Published private(set) var entries: [Entry] = []
    private let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        self.formatter = formatter
    }

    func log(_ message: String, category: Category = .general) {
        let entry = Entry(timestamp: Date(), message: message, category: category)
        entries.append(entry)
        entries = entries.suffix(100)
        #if DEBUG
        print("[LOG][\(category.rawValue)] \(formatted(date: entry.timestamp)) — \(message)")
        #endif
    }

    func formatted(date: Date) -> String {
        formatter.string(from: date)
    }
}
