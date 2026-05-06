import SwiftUI
import SwiftData

@main
struct ChexoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: TaskItem.self)
        } catch {
            NSLog("Chexo: failed to create ModelContainer — \(error.localizedDescription). Falling back to in-memory store.")
            do {
                container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("Chexo: in-memory ModelContainer failed — \(error.localizedDescription). This should never happen.")
            }
        }
        let controller = PanelController(container: container)
        panelController = controller
        controller.show()
    }
}
