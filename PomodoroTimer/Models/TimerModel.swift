import Combine
import Foundation

@MainActor
final class TimerModel: ObservableObject {
    @Published var timerState: TimerState = .stopped
    @Published var sessionType: SessionType = .work
    @Published var remainingSeconds: Int

    private var timerCancellable: AnyCancellable?
    private var lastTickDate: Date?

    var menuBarTitle: String {
        switch timerState {
        case .stopped:
            return "🍅"
        case .running:
            return "🍅 \(TimeFormatting.format(seconds: remainingSeconds))"
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
        remainingSeconds = sessionType.duration
    }

    private func start() {
        lastTickDate = Date()
        timerState = .running

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
        }
    }
}
