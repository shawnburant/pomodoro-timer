import Foundation

@MainActor
final class TimerModel: NSObject, ObservableObject {
    @Published var timerState: TimerState = .stopped
    @Published var sessionType: SessionType = .work
    @Published var remainingSeconds: Int
    @Published var sessionLabel: String = ""
    @Published var completedWorkSessions: Int = 0
    @Published var tickSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(tickSoundEnabled, forKey: "tickSoundEnabled") }
    }
    @Published var tickVolume: Float {
        didSet { UserDefaults.standard.set(tickVolume, forKey: "tickVolume") }
    }

    private(set) var currentSession: Session?
    private(set) var lastCompletedSession: Session?

    private let audioManager = AudioManager()
    private var timer: Timer?
    private var targetEndDate: Date?

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

    override init() {
        self.remainingSeconds = SessionType.work.duration
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "tickSoundEnabled") == nil {
            self.tickSoundEnabled = true
        } else {
            self.tickSoundEnabled = defaults.bool(forKey: "tickSoundEnabled")
        }
        if defaults.object(forKey: "tickVolume") == nil {
            self.tickVolume = 0.5
        } else {
            self.tickVolume = defaults.float(forKey: "tickVolume")
        }
        super.init()
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
        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        timerState = .stopped
        currentSession = nil
        remainingSeconds = sessionType.duration
    }

    private func start() {
        targetEndDate = Date().addingTimeInterval(Double(remainingSeconds))
        timerState = .running

        if currentSession == nil {
            currentSession = Session(
                label: sessionLabel,
                sessionType: sessionType,
                startTime: Date(),
                duration: sessionType.duration
            )
        }

        let now = Date().timeIntervalSinceReferenceDate
        let nextSecond = Date(timeIntervalSinceReferenceDate: ceil(now))
        let t = Timer(fireAt: nextSecond, interval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func pause() {
        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        timerState = .paused
    }

    @objc private func timerFired() {
        tick(fireDate: Date())
    }

    private func tick(fireDate: Date) {
        guard let endDate = targetEndDate else { return }

        let newRemaining = max(0, Int(ceil(endDate.timeIntervalSince(fireDate))))
        guard newRemaining != remainingSeconds else { return }
        remainingSeconds = newRemaining

        if remainingSeconds > 0 && tickSoundEnabled {
            audioManager.playTickSound(volume: tickVolume)
        }

        if remainingSeconds == 0 {
            timer?.invalidate()
            timer = nil
            targetEndDate = nil
            timerState = .stopped
            lastCompletedSession = currentSession
            currentSession = nil
            audioManager.playCompletionSound()
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

    func finishEarly() {
        guard timerState == .running || timerState == .paused else { return }

        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        timerState = .stopped

        let elapsed = sessionType.duration - remainingSeconds
        if var session = currentSession {
            session = Session(
                label: session.label,
                sessionType: session.sessionType,
                startTime: session.startTime,
                duration: elapsed
            )
            lastCompletedSession = session
        }
        currentSession = nil
        audioManager.playCompletionSound()
        advanceCycle()
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
