import SwiftUI

@main
struct PomodoroTimerApp: App {
    @StateObject private var timer = TimerModel()

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView(timer: timer)
        } label: {
            Text(timer.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }
}
