import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [PomodoroTask] = []

    private let defaultsKey = "pomodoroTasks"

    init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([PomodoroTask].self, from: data) else { return }
        tasks = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func appendSession(_ session: Session, toTaskNamed name: String) {
        let resolvedName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name.trimmingCharacters(in: .whitespaces)

        if let index = tasks.firstIndex(where: {
            !$0.isCompleted && $0.name.lowercased() == resolvedName.lowercased()
        }) {
            tasks[index].completedSessions.append(session)
        } else if let index = tasks.firstIndex(where: {
            $0.name.lowercased() == resolvedName.lowercased()
        }) {
            // All matches are completed — create a new task with the same name
            var newTask = PomodoroTask(name: tasks[index].name)
            newTask.completedSessions.append(session)
            tasks.insert(newTask, at: 0)
        } else {
            var newTask = PomodoroTask(name: resolvedName)
            newTask.completedSessions.append(session)
            tasks.insert(newTask, at: 0)
        }
        save()
    }

    func markComplete(_ task: PomodoroTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = true
        tasks[index].completedAt = Date()
        save()
    }

    func unmarkComplete(_ task: PomodoroTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = false
        tasks[index].completedAt = nil
        save()
    }

    func deleteTask(_ task: PomodoroTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }
}
