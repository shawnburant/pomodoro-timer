import SwiftUI

@main
struct PomodoroTimerApp: App {
    @StateObject private var timer = TimerModel()

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView(timer: timer)
        } label: {
            if timer.timerState == .stopped {
                Image(systemName: timer.sessionType == .work ? "timer" : "cup.and.saucer.fill")
            } else {
                Text(timer.menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
