import AppKit
import SwiftUI

/// Owns the NSStatusItem (menu bar icon) and the NSPopover that contains the SwiftUI UI.
final class StatusMenuController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let deviceManager = AudioDeviceManager()
    private let aggregateBuilder = AudioAggregateBuilder()
    // MirrorState is a reference type shared between StatusMenuController and MenuBarView
    // so cleanup() can trigger deactivation on the live state, not a struct copy.
    private let mirrorState = MirrorState()
    private var eventMonitor: Any?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "hifispeaker.2.fill",
                accessibilityDescription: "AudioMirror"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        let view = MenuBarView(deviceManager: deviceManager, aggregateBuilder: aggregateBuilder, mirrorState: mirrorState)

        let hostingController = NSHostingController(rootView: view)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient

        // Close popover on click outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePopover()
        }

        deviceManager.refresh()
        deviceManager.installHardwareListener()

        // Deactivate on system sleep to avoid AirPlay issues
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }

    func cleanup() {
        mirrorState.deactivate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        deviceManager.removeHardwareListener()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        mirrorState.deactivate()
    }
}
