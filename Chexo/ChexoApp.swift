import SwiftUI
import SwiftData

/// The main application entry point for Chexo.
///
/// Configures a macOS menu bar app that presents a floating task panel
/// with focus mode for tracking daily tasks.
@main
struct ChexoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

/// Manages the application lifecycle and floating panel presentation.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PanelController?

    /// Sets up the SwiftData container and shows the floating panel on launch.
    func applicationDidFinishLaunching(_ notification: Notification) {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: TaskItem.self)
        } catch {
            NSLog("Chexo: failed to create ModelContainer — \(error.localizedDescription). Falling back to clean store.")
            container = try! ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        let controller = PanelController(container: container)
        panelController = controller
        controller.show()
    }
}
