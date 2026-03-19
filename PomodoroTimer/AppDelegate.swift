import Cocoa
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    let timerModel = TimerModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.requestPermission()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        let hostingController = NSHostingController(rootView: TimerPopoverView(timer: timerModel))
        popover = NSPopover()
        popover.contentViewController = hostingController
        popover.behavior = .transient

        timerModel.onNewSessionFromHotkey = { [weak self] in self?.showPopover() }

        timerModel.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateStatusButton() }
            }
            .store(in: &cancellables)

        updateStatusButton()
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        if timerModel.timerState == .stopped {
            let symbolName = timerModel.sessionType == .work ? "timer" : "cup.and.saucer.fill"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            button.title = ""
        } else {
            button.image = nil
            button.title = timerModel.menuBarTitle
        }
    }
}
