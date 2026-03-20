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

private struct DurationRow: View {
    let label: String
    let type: SessionType
    @ObservedObject var timer: TimerModel

    private var minutes: Int { timer.duration(for: type) / 60 }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Stepper(value: Binding(
                get: { minutes },
                set: { timer.updateDuration(for: type, minutes: $0) }
            ), in: 1...99) {
                Text("\(minutes) min")
                    .monospacedDigit()
                    .frame(minWidth: 42, alignment: .trailing)
            }
        }
    }
}

private enum PopoverTab {
    case timer, tasks, settings
}

struct TimerPopoverView: View {
    @ObservedObject var timer: TimerModel
    @State private var selectedTab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $selectedTab) {
                Text("Timer").tag(PopoverTab.timer)
                Text("Tasks").tag(PopoverTab.tasks)
                Text("Settings").tag(PopoverTab.settings)
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case .timer:
                timerContent
            case .tasks:
                TasksView(timer: timer)
            case .settings:
                settingsContent
            }
        }
        .padding(20)
        .frame(width: 260)
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
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Durations") {
                DurationRow(label: "Work", type: .work, timer: timer)
                DurationRow(label: "Short Break", type: .shortBreak, timer: timer)
                DurationRow(label: "Long Break", type: .longBreak, timer: timer)
            }

            Divider()

            settingsSection("Sound") {
                Toggle("Tick Sound", isOn: $timer.tickSoundEnabled)
                if timer.tickSoundEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $timer.tickVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            settingsSection("Integrations") {
                Toggle("Log to Calendar", isOn: $timer.calendarEnabled)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.small)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }
}
