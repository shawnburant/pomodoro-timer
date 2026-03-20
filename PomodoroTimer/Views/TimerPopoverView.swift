import SwiftUI

private struct TaskAutocompleteField: View {
    @Binding var text: String
    let tasks: [PomodoroTask]
    let isDisabled: Bool
    let onSelect: (PomodoroTask) -> Void

    @FocusState private var focused: Bool

    private var filteredTasks: [PomodoroTask] {
        text.isEmpty ? tasks : tasks.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    private var showDropdown: Bool {
        focused && !filteredTasks.isEmpty && !isDisabled
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            TextField("What are you working on?", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .disabled(isDisabled)
            if !text.isEmpty && !isDisabled {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
        .zIndex(1)
        .overlay(alignment: .bottom) {
            if showDropdown {
                let rowHeight: CGFloat = 34
                let dropdownHeight = min(CGFloat(filteredTasks.count), 4) * rowHeight
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredTasks) { task in
                            HStack {
                                Text(task.name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("🍅 \(task.pomodoroCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(task)
                                focused = false
                            }
                        }
                    }
                }
                .frame(height: dropdownHeight)
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                .offset(y: dropdownHeight)
            }
        }
    }
}

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
            TaskAutocompleteField(
                text: $timer.sessionLabel,
                tasks: timer.taskStore.tasks.filter { !$0.isCompleted },
                isDisabled: timer.timerState == .running,
                onSelect: { task in timer.switchToTask(task) }
            )

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
