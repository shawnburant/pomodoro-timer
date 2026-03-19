import SwiftUI

private struct ShortcutRow: View {
    let keys: String
    let label: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(keys)
                .monospacedDigit()
        }
    }
}

private enum PopoverTab {
    case timer, tasks
}

struct TimerPopoverView: View {
    @ObservedObject var timer: TimerModel
    @State private var selectedTab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $selectedTab) {
                Text("Timer").tag(PopoverTab.timer)
                Text("Tasks").tag(PopoverTab.tasks)
            }
            .pickerStyle(.segmented)

            if selectedTab == .timer {
                timerContent
            } else {
                TasksView(timer: timer)
            }
        }
        .padding(20)
        .frame(width: 240)
    }

    private var timerContent: some View {
        VStack(spacing: 16) {
            TextField("What are you working on?", text: $timer.sessionLabel)
                .textFieldStyle(.roundedBorder)
                .disabled(timer.timerState == .running)

            VStack(spacing: 4) {
                Text(timer.cycleProgressText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < timer.completedWorkSessions ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            TimerDisplayView(
                remainingSeconds: timer.remainingSeconds,
                sessionType: timer.sessionType,
                isEditable: timer.timerState == .stopped,
                onDurationChange: timer.setCurrentDuration
            )

            ControlButtonsView(
                timerState: timer.timerState,
                onStartPause: timer.startPause,
                onReset: timer.stopReset,
                onFinish: timer.finishEarly
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

            VStack(spacing: 2) {
                ShortcutRow(keys: "⌘⇧S", label: "Start / Pause")
                ShortcutRow(keys: "⌘⇧R", label: "Reset")
                ShortcutRow(keys: "⌘⇧N", label: "New Session")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Toggle("Log to Calendar", isOn: $timer.calendarEnabled)
                .controlSize(.small)

            Toggle("Tick Sound", isOn: $timer.tickSoundEnabled)
                .controlSize(.small)

            if timer.tickSoundEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: $timer.tickVolume, in: 0...1)
                        .controlSize(.small)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.small)
            .foregroundStyle(.secondary)
        }
    }
}
