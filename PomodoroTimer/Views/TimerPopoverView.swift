import SwiftUI

struct TimerPopoverView: View {
    @ObservedObject var timer: TimerModel

    var body: some View {
        VStack(spacing: 16) {
            TextField("What are you working on?", text: $timer.sessionLabel)
                .textFieldStyle(.roundedBorder)
                .disabled(timer.timerState == .running)

            TimerDisplayView(
                remainingSeconds: timer.remainingSeconds,
                sessionType: timer.sessionType
            )

            ControlButtonsView(
                timerState: timer.timerState,
                onStartPause: timer.startPause,
                onReset: timer.stopReset
            )

            HStack(spacing: 12) {
                Button(action: timer.repeatSession) {
                    Text("Repeat")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .disabled(timer.lastCompletedSession == nil)

                Button(action: timer.newSession) {
                    Text("New Session")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }

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
