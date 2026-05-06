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
    private var panel: FloatingPanel?
    private let container: ModelContainer

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

    func show() {
        ensurePanel()
        panel?.animatedOrderFront()
    }

    func collapse() {
        panel?.animatedOrderOut()
    }

    @objc private func toggle() {
        if let panel, panel.isVisible {
            collapse()
        } else {
            show()
        }
    }

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

    private func ensurePanel() {
        guard panel == nil else { return }

        let rect = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight)
        panel = FloatingPanel(rect: rect) {
            FloatingPanelView(onCollapse: { [weak self] in
                self?.collapse()
            })
            .modelContainer(self.container)
        }
        restoreFrame()
        observeFrameChanges()
    }

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

    private func defaultFrame() -> NSRect {
        guard let screen = NSScreen.main else { return NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight) }
        let visible = screen.visibleFrame
        return NSRect(x: visible.maxX - Self.panelWidth - 20, y: visible.minY + 20, width: Self.panelWidth, height: Self.panelHeight)
    }

    private func observeFrameChanges() {
        guard let panel else { return }

        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveFrame() }
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveFrame() }
        }
    }

    private func saveFrame() {
        guard let panel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panelFrame")
    }
}
