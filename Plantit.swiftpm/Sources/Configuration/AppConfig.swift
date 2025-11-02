import Foundation

@MainActor
final class AppConfig: ObservableObject {
    @Published var appDisplayName: String
    @Published var accentColorHex: String
    @Published var enableDeveloperPanel: Bool
    @Published var supportEmail: String

    init(
        appDisplayName: String = "Plantit",
        accentColorHex: String = "#4CAF50",
        enableDeveloperPanel: Bool = true,
        supportEmail: String = "support@plantit.app"
    ) {
        self.appDisplayName = appDisplayName
        self.accentColorHex = accentColorHex
        self.enableDeveloperPanel = enableDeveloperPanel
        self.supportEmail = supportEmail
    }
}
