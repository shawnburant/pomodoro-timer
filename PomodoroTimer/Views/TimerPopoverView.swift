import SwiftUI

struct TimerPopoverView: View {
    @ObservedObject var timer: TimerModel

    var body: some View {
        VStack(spacing: 16) {
            Text(timer.sessionType.displayName)
                .font(.headline)
                .foregroundStyle(.secondary)

            TimerDisplayView(
                remainingSeconds: timer.remainingSeconds,
                sessionType: timer.sessionType
            )

            ControlButtonsView(
                timerState: timer.timerState,
                onStartPause: timer.startPause,
                onReset: timer.stopReset
            )

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.small)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 240)
    }
}
