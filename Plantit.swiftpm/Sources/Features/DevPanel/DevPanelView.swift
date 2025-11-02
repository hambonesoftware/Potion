import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DevPanelView: View {
    @EnvironmentObject private var loggingService: LoggingService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Village.name) private var villages: [Village]
    @Query(sort: \Plant.name) private var plants: [Plant]

    @StateObject private var legacyImportService = LegacyImportService()

    @State private var lastExportResult: BackupExporter.ExportResult?
    @State private var exportError: String?
    @State private var isPresentingImporter = false
    @State private var showingReconcile = false
    @State private var importError: String?

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

                Section("Legacy Import") {
                    if let draft = legacyImportService.draft {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(draft.sourceURL.lastPathComponent)
                                .font(.subheadline)
                            if draft.totalUnknownFieldCount > 0 {
                                Text("Unknown fields: \(draft.totalUnknownFieldCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No pending legacy import.")
                            .foregroundStyle(.secondary)
                    }

                    if let importError {
                        Text(importError)
                            .foregroundStyle(.red)
                    }

                    Button {
                        isPresentingImporter = true
                    } label: {
                        Label("Import Legacy JSON", systemImage: "tray.and.arrow.down")
                    }

                    if legacyImportService.draft != nil {
                        Button {
                            showingReconcile = true
                        } label: {
                            Label("Review Draft", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }

                Section("Exports") {
                    if let result = lastExportResult {
                        LabeledContent("Bundle", value: result.url.lastPathComponent)
                            .textSelection(.enabled)
                        LabeledContent("Plants", value: "\(result.counts.plants)")
                        LabeledContent("Activities", value: "\(result.counts.activities)")
                        LabeledContent("Schedules", value: "\(result.counts.schedules)")
                        LabeledContent("Villages", value: "\(result.counts.villages)")
                        LabeledContent("Photos", value: "\(result.counts.photos)")
                        LabeledContent("CSV Rows", value: "P \(result.csvRows.plants) · A \(result.csvRows.activities) · S \(result.csvRows.schedules)")
                    }

                    if let exportError {
                        Text(exportError)
                            .foregroundStyle(.red)
                    }

                    Button {
                        exportBundle()
                    } label: {
                        Label("Export Data Bundle", systemImage: "externaldrive.badge.plus")
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
        .fileImporter(isPresented: $isPresentingImporter, allowedContentTypes: [.json]) { result in
            handleImporter(result: result)
        }
        .sheet(isPresented: Binding(
            get: { showingReconcile && legacyImportService.draft != nil },
            set: { showingReconcile = $0 }
        )) {
            LegacyReconcileView(service: legacyImportService, loggingService: loggingService) { _ in
                importError = nil
                showingReconcile = false
            }
        }
    }

    private func exportBundle() {
        do {
            let result = try BackupExporter.exportBundle(context: modelContext)
            lastExportResult = result
            exportError = nil
            loggingService.log("Exported bundle to \(result.url.lastPathComponent)", category: .importExport)
        } catch {
            exportError = error.localizedDescription
            loggingService.log("Failed to export bundle: \(error.localizedDescription)", category: .importExport)
        }
    }

    private func handleImporter(result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            let securityScoped = url.startAccessingSecurityScopedResource()
            defer {
                if securityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                try legacyImportService.loadDraft(from: url, context: modelContext)
                importError = nil
                showingReconcile = true
                loggingService.log("Loaded legacy draft from \(url.lastPathComponent)", category: .importExport)
            } catch {
                importError = error.localizedDescription
                loggingService.log("Failed to load legacy draft: \(error.localizedDescription)", category: .importExport)
            }
        case let .failure(error as NSError):
            if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError {
                importError = nil
                loggingService.log("Legacy import cancelled by user", category: .importExport)
            } else {
                importError = error.localizedDescription
                loggingService.log("Legacy import failed: \(error.localizedDescription)", category: .importExport)
            }
        case let .failure(error):
            importError = error.localizedDescription
            loggingService.log("Legacy import failed: \(error.localizedDescription)", category: .importExport)
        }
    }
}

#Preview("Dev Panel") {
    ContentPreviewBuilder.make(showDevPanel: true)
}
