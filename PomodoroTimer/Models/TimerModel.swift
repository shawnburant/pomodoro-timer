import Foundation
import AppKit

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
    @Published var calendarEnabled: Bool {
        didSet { UserDefaults.standard.set(calendarEnabled, forKey: "calendarEnabled") }
    }
    @Published var workDuration: Int {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }
    @Published var shortBreakDuration: Int {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration") }
    }
    @Published var longBreakDuration: Int {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration") }
    }

    var onNewSessionFromHotkey: (() -> Void)?

    private(set) var currentSession: Session?
    private(set) var lastCompletedSession: Session?

    private let audioManager = AudioManager()
    private let calendarManager = CalendarManager()
    private var hotKeyManager: HotKeyManager?
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

    func duration(for type: SessionType) -> Int {
        switch type {
        case .work: workDuration
        case .shortBreak: shortBreakDuration
        case .longBreak: longBreakDuration
        }
    }

    func setCurrentDuration(_ seconds: Int) {
        switch sessionType {
        case .work: workDuration = seconds
        case .shortBreak: shortBreakDuration = seconds
        case .longBreak: longBreakDuration = seconds
        }
        remainingSeconds = seconds
    }

    override init() {
        let defaults = UserDefaults.standard
        let work = defaults.object(forKey: "workDuration") == nil ? SessionType.work.duration : defaults.integer(forKey: "workDuration")
        let short = defaults.object(forKey: "shortBreakDuration") == nil ? SessionType.shortBreak.duration : defaults.integer(forKey: "shortBreakDuration")
        let long = defaults.object(forKey: "longBreakDuration") == nil ? SessionType.longBreak.duration : defaults.integer(forKey: "longBreakDuration")
        self.workDuration = work
        self.shortBreakDuration = short
        self.longBreakDuration = long
        self.remainingSeconds = work
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
        self.calendarEnabled = defaults.object(forKey: "calendarEnabled") == nil
            ? false
            : defaults.bool(forKey: "calendarEnabled")
        super.init()
        hotKeyManager = HotKeyManager(timerModel: self)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
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
        remainingSeconds = duration(for: sessionType)
    }

    private func start() {
        targetEndDate = Date().addingTimeInterval(Double(remainingSeconds))
        timerState = .running

        if currentSession == nil {
            currentSession = Session(
                label: sessionLabel,
                sessionType: sessionType,
                startTime: Date(),
                duration: duration(for: sessionType)
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

    @objc private func systemDidWake() {
        guard timerState == .running else { return }
        timer?.invalidate()
        timer = nil
        let now = Date().timeIntervalSinceReferenceDate
        let nextSecond = Date(timeIntervalSinceReferenceDate: ceil(now))
        let t = Timer(fireAt: nextSecond, interval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
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
            let completedType = sessionType
            let completedLabel = sessionLabel
            currentSession = nil
            audioManager.playCompletionSound()
            advanceCycle()
            sendCompletionNotification(for: completedType, label: completedLabel)
            if completedType == .work, calendarEnabled, let session = lastCompletedSession {
                Task { await calendarManager.logSession(session) }
            }
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
        remainingSeconds = duration(for: sessionType)
    }

    func finishEarly() {
        guard timerState == .running || timerState == .paused else { return }

        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        timerState = .stopped

        let elapsed = duration(for: sessionType) - remainingSeconds
        if var session = currentSession {
            session = Session(
                label: session.label,
                sessionType: session.sessionType,
                startTime: session.startTime,
                duration: elapsed
            )
            lastCompletedSession = session
        }
        let wasWork = sessionType == .work
        currentSession = nil
        audioManager.playCompletionSound()
        advanceCycle()
        if wasWork, calendarEnabled, let session = lastCompletedSession {
            Task { await calendarManager.logSession(session) }
        }
    }

    private func sendCompletionNotification(for type: SessionType, label: String) {
        switch type {
        case .work:
            NotificationManager.sendWorkSessionComplete(label: label)
        case .shortBreak, .longBreak:
            NotificationManager.sendBreakComplete()
        }
    }

    func repeatSession() {
        guard let last = lastCompletedSession else { return }
        sessionLabel = last.label
        sessionType = last.sessionType
        remainingSeconds = duration(for: last.sessionType)
        lastCompletedSession = nil
        startPause()
    }

    func newSession() {
        stopReset()
        sessionLabel = ""
        sessionType = .work
        remainingSeconds = workDuration
        completedWorkSessions = 0
        lastCompletedSession = nil
    }
}
