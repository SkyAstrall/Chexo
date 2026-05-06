import AppKit
import SwiftUI
import SwiftData

/// Manages the menu bar status item and floating panel lifecycle.
///
/// Owns the `NSStatusItem` that appears in the system menu bar, toggles the
/// floating panel on click, and persists the panel's screen position across launches.
@MainActor
final class PanelController: NSObject {
    private static let panelWidth: CGFloat = 320
    private static let panelHeight: CGFloat = 480
    private let statusItem: NSStatusItem
    private var panel: FloatingPanel<AnyView>?
    private let container: ModelContainer

    /// Creates a controller with the given data container and sets up the menu bar icon.
    /// - Parameter container: The SwiftData model container for task persistence.
    init(container: ModelContainer) {
        self.container = container
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        statusItem.button?.action = #selector(toggle)
        statusItem.button?.target = self
        updateStatusIcon()

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateStatusIcon() }
        }
    }

    /// Creates the panel if needed and fades it in.
    func show() {
        ensurePanel()
        panel?.animatedOrderFront()
    }

    /// Fades the panel out and removes it from the screen.
    func collapse() {
        panel?.animatedOrderOut()
    }

    /// Toggles the panel between visible and hidden.
    @objc private func toggle() {
        if let panel, panel.isVisible {
            collapse()
        } else {
            show()
        }
    }

    /// Updates the menu bar icon to reflect the current focus state.
    private func updateStatusIcon() {
        let hasFocus: Bool
        if let data = UserDefaults.standard.data(forKey: "focusedTaskIDData") {
            hasFocus = !data.isEmpty
        } else {
            hasFocus = false
        }
        let symbolName = hasFocus ? "target" : "checklist"
        let description = hasFocus ? "Tasks (focused)" : "Tasks"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
    }

    /// Lazily creates the floating panel with the task view and restores its saved position.
    private func ensurePanel() {
        guard panel == nil else { return }

        let rect = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight)
        panel = FloatingPanel(rect: rect) {
            AnyView(
                FloatingPanelView(onCollapse: { [weak self] in
                    self?.collapse()
                })
                .modelContainer(self.container)
            )
        }
        restoreFrame()
        observeFrameChanges()
    }

    /// Restores the panel to its last saved position, or falls back to the default.
    private func restoreFrame() {
        guard let panel else { return }

        if let saved = UserDefaults.standard.string(forKey: "panelFrame") {
            let frame = NSRectFromString(saved)
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(frame) }) {
                panel.setFrame(frame, display: false)
                return
            }
        }
        panel.setFrame(defaultFrame(), display: false)
    }

    /// Returns the default panel frame, positioned at the bottom-right of the main screen.
    private func defaultFrame() -> NSRect {
        guard let screen = NSScreen.main else { return NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight) }
        let visible = screen.visibleFrame
        return NSRect(x: visible.maxX - Self.panelWidth - 20, y: visible.minY + 20, width: Self.panelWidth, height: Self.panelHeight)
    }

    /// Listens for panel move and resize events to persist the frame.
    private func observeFrameChanges() {
        guard let panel else { return }

        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveFrame() }
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveFrame() }
        }
    }

    /// Persists the panel's current frame to UserDefaults.
    private func saveFrame() {
        guard let panel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panelFrame")
    }
}
