import SwiftUI
import AppKit

@main
struct AeroToneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app lives entirely in the menu bar (managed by AppDelegate); this
        // inert scene just satisfies the `App` requirement.
        Settings { EmptyView() }
    }
}

/// Owns the menu-bar status item. Left-click toggles the window; right-click or
/// cmd-click shows a menu with a Quit option.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let router = AppRouter()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon

        popover.contentSize = NSSize(width: 400, height: 560)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(router: router).frame(width: 400, height: 560)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshLabel() }
        }
        refreshLabel()
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.command) ?? false)
        if wantsMenu {
            presentMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func presentMenu() {
        let menu = NSMenu()
        let quit = NSMenuItem(
            title: "Quit AeroTone",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        menu.addItem(quit)

        // Attaching a menu makes the next click open it; clear it right after so
        // left-click keeps toggling the window.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    private func refreshLabel() {
        guard let button = statusItem?.button else { return }
        if let controller = router.flightController, controller.elapsed > 0, !controller.didComplete {
            let symbol = controller.isRunning ? "airplane" : "pause.fill"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "AeroTone")
            button.title = " " + Self.format(controller.remaining)
        } else {
            button.image = NSImage(systemSymbolName: "airplane", accessibilityDescription: "AeroTone")
            button.title = ""
        }
    }

    private static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%d:%02d", m, s)
    }
}
