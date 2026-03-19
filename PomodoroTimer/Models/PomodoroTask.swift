import Foundation

struct PomodoroTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var completedSessions: [Session]
    var isCompleted: Bool
    let createdAt: Date
    var completedAt: Date?

    var pomodoroCount: Int { completedSessions.count }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.completedSessions = []
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
    }
}
