import SwiftUI

struct ControlButtonsView: View {
    let timerState: TimerState
    let onStartPause: () -> Void
    let onReset: () -> Void
    let onFinish: () -> Void

    private var startPauseLabel: String {
        switch timerState {
        case .stopped: "Start"
        case .running: "Pause"
        case .paused: "Resume"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onStartPause) {
                Text(startPauseLabel)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])

            Button(action: onFinish) {
                Text("Finish")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(timerState == .stopped)

            Button(action: onReset) {
                Text("Reset")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(timerState == .stopped)
        }
    }
}
