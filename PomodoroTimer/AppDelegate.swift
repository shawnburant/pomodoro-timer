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
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

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

    @objc func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Pomodoro Timer", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        if timerModel.timerState == .stopped {
            let emoji = timerModel.sessionType == .work ? "🍅" : "☕"
            button.image = emojiImage(emoji, size: 18)
            button.title = ""
        } else {
            button.image = nil
            button.title = timerModel.menuBarTitle
        }
    }

    private func emojiImage(_ emoji: String, size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        (emoji as NSString).draw(
            at: NSPoint(x: 0, y: -2),
            withAttributes: [.font: NSFont.systemFont(ofSize: size)]
        )
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
