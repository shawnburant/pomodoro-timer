import SwiftUI

struct TasksView: View {
    @ObservedObject var timer: TimerModel
    @ObservedObject private var taskStore: TaskStore
    @State private var showCompleted = false

    init(timer: TimerModel) {
        self.timer = timer
        self.taskStore = timer.taskStore
    }

    private var activeTasks: [PomodoroTask] {
        taskStore.tasks
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                let lhsDate = lhs.completedSessions.last?.startTime ?? lhs.createdAt
                let rhsDate = rhs.completedSessions.last?.startTime ?? rhs.createdAt
                return lhsDate > rhsDate
            }
    }

    private var completedTasks: [PomodoroTask] {
        taskStore.tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tasks")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            if activeTasks.isEmpty {
                Text("No active tasks.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(activeTasks) { task in
                    TaskRow(task: task, timer: timer)
                }
            }

            Button {
                showCompleted.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("Completed (\(completedTasks.count))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            if showCompleted {
                if completedTasks.isEmpty {
                    Text("No completed tasks.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(completedTasks) { task in
                        TaskRow(task: task, timer: timer)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct TaskRow: View {
    let task: PomodoroTask
    @ObservedObject var timer: TimerModel

    private var isActiveTask: Bool {
        !task.isCompleted &&
        task.name.lowercased() == timer.sessionLabel.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var isStopped: Bool { timer.timerState == .stopped }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                if task.isCompleted {
                    timer.taskStore.unmarkComplete(task)
                } else {
                    timer.taskStore.markComplete(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            Button {
                guard isStopped && !task.isCompleted else { return }
                timer.switchToTask(task)
            } label: {
                Text(task.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted || !isStopped)

            Text("🍅 \(task.pomodoroCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button { timer.taskStore.deleteTask(task) } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isActiveTask ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
