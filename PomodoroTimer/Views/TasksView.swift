import SwiftUI

struct TasksView: View {
    @ObservedObject var timer: TimerModel
    @State private var showCompleted = false

    private var activeTasks: [PomodoroTask] {
        timer.taskStore.tasks
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                let lhsDate = lhs.completedSessions.last?.startTime ?? lhs.createdAt
                let rhsDate = rhs.completedSessions.last?.startTime ?? rhs.createdAt
                return lhsDate > rhsDate
            }
    }

    private var completedTasks: [PomodoroTask] {
        timer.taskStore.tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if activeTasks.isEmpty && completedTasks.isEmpty {
                    Text("No tasks yet. Complete a work session to create one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    ForEach(activeTasks) { task in
                        TaskRow(task: task, timer: timer)
                    }

                    if !completedTasks.isEmpty {
                        DisclosureGroup(isExpanded: $showCompleted) {
                            ForEach(completedTasks) { task in
                                TaskRow(task: task, timer: timer)
                            }
                        } label: {
                            Text("Completed (\(completedTasks.count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 6)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 220)
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
        .padding(.vertical, 6)
        .background(isActiveTask ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture {
            guard isStopped && !task.isCompleted else { return }
            timer.switchToTask(task)
        }
        .disabled(!isStopped || task.isCompleted)
        .contextMenu {
            if !task.isCompleted {
                Button("Mark Complete") {
                    timer.taskStore.markComplete(task)
                }
            }
            Button("Delete", role: .destructive) {
                timer.taskStore.deleteTask(task)
            }
        }
    }
}
