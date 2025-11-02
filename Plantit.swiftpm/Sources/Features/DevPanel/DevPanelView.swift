import SwiftUI
import SwiftData

struct DevPanelView: View {
    @EnvironmentObject private var loggingService: LoggingService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Village.name) private var villages: [Village]
    @Query(sort: \Plant.name) private var plants: [Plant]

    @State private var lastExportURL: URL?
    @State private var exportError: String?

    private var applicationSupportPath: String {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "Unknown"
    }

    private var documentsPath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Paths") {
                    LabeledContent("Application Support", value: applicationSupportPath)
                        .textSelection(.enabled)
                    LabeledContent("Documents", value: documentsPath)
                        .textSelection(.enabled)
                }

                Section("Counts") {
                    LabeledContent("Villages", value: "\(villages.count)")
                    LabeledContent("Plants", value: "\(plants.count)")
                }

                Section("Backup") {
                    if let lastExportURL {
                        LabeledContent("Last Export", value: lastExportURL.lastPathComponent)
                            .textSelection(.enabled)
                    }

                    if let exportError {
                        Text(exportError)
                            .foregroundStyle(.red)
                    }

                    Button {
                        exportBackup()
                    } label: {
                        Label("Export Empty Backup", systemImage: "externaldrive.badge.plus")
                    }
                }

                let recentEntries = Array(loggingService.entries.suffix(10))
                if !recentEntries.isEmpty {
                    Section("Recent Logs") {
                        ForEach(recentEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loggingService.formatted(date: entry.timestamp))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.message)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Developer Panel")
        }
    }

    private func exportBackup() {
        do {
            let url = try BackupExporter.exportEmptyArchive()
            lastExportURL = url
            exportError = nil
            loggingService.log("Exported backup to \(url.lastPathComponent)", category: .backup)
        } catch {
            exportError = error.localizedDescription
            loggingService.log("Failed to export backup: \(error.localizedDescription)", category: .backup)
        }
    }
}

#Preview("Dev Panel") {
    ContentPreviewBuilder.make(showDevPanel: true)
}
