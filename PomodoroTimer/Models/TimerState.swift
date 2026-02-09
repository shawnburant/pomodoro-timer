import SwiftUI

enum TimerState {
    case stopped
    case running
    case paused
}

enum SessionType: CaseIterable {
    case work
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .work: "Work"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    var duration: Int {
        switch self {
        case .work: 25 * 60
        case .shortBreak: 5 * 60
        case .longBreak: 15 * 60
        }
    }

    var accentColor: Color {
        switch self {
        case .work: .red
        case .shortBreak: .green
        case .longBreak: .blue
        }
    }
}
