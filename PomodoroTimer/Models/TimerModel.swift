import Combine
import Foundation

@MainActor
final class TimerModel: ObservableObject {
    @Published var timerState: TimerState = .stopped
    @Published var sessionType: SessionType = .work
    @Published var remainingSeconds: Int
    @Published var sessionLabel: String = ""
    @Published var completedWorkSessions: Int = 0

    private(set) var currentSession: Session?
    private(set) var lastCompletedSession: Session?

    private var timerCancellable: AnyCancellable?
    private var lastTickDate: Date?

    var cycleProgressText: String {
        switch sessionType {
        case .work:
            let name = sessionLabel.isEmpty ? "Work" : sessionLabel
            return "\(name) \(completedWorkSessions + 1)/4"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var menuBarTitle: String {
        let icon = sessionType == .work ? "🍅" : "☕"
        switch timerState {
        case .stopped:
            return icon
        case .running:
            return "\(icon) \(TimeFormatting.format(seconds: remainingSeconds))"
        case .paused:
            return "⏸ \(TimeFormatting.format(seconds: remainingSeconds))"
        }
    }

    init() {
        self.remainingSeconds = SessionType.work.duration
    }

    func startPause() {
        switch timerState {
        case .stopped:
            start()
        case .running:
            pause()
        case .paused:
            start()
        }
    }

    func stopReset() {
        timerCancellable?.cancel()
        timerCancellable = nil
        lastTickDate = nil
        timerState = .stopped
        currentSession = nil
        remainingSeconds = sessionType.duration
    }

    private func start() {
        lastTickDate = Date()
        timerState = .running

        if currentSession == nil {
            currentSession = Session(
                label: sessionLabel,
                sessionType: sessionType,
                startTime: Date(),
                duration: sessionType.duration
            )
        }

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] fireDate in
                guard let self else { return }
                self.tick(fireDate: fireDate)
            }
    }

    private func pause() {
        timerCancellable?.cancel()
        timerCancellable = nil
        lastTickDate = nil
        timerState = .paused
    }

    private func tick(fireDate: Date) {
        guard let lastTick = lastTickDate else { return }

        let elapsed = Int(fireDate.timeIntervalSince(lastTick))
        guard elapsed > 0 else { return }

        lastTickDate = fireDate
        remainingSeconds = max(0, remainingSeconds - elapsed)

        if remainingSeconds == 0 {
            timerCancellable?.cancel()
            timerCancellable = nil
            lastTickDate = nil
            timerState = .stopped
            lastCompletedSession = currentSession
            currentSession = nil
            advanceCycle()
        }
    }

    private func advanceCycle() {
        switch sessionType {
        case .work:
            completedWorkSessions += 1
            if completedWorkSessions >= 4 {
                sessionType = .longBreak
            } else {
                sessionType = .shortBreak
            }
        case .shortBreak:
            sessionType = .work
        case .longBreak:
            completedWorkSessions = 0
            sessionType = .work
        }
        remainingSeconds = sessionType.duration
    }

    func repeatSession() {
        guard let last = lastCompletedSession else { return }
        sessionLabel = last.label
        sessionType = last.sessionType
        remainingSeconds = last.sessionType.duration
        lastCompletedSession = nil
        startPause()
    }

    func newSession() {
        stopReset()
        sessionLabel = ""
        sessionType = .work
        remainingSeconds = SessionType.work.duration
        completedWorkSessions = 0
        lastCompletedSession = nil
    }
}
