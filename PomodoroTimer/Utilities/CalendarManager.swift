import EventKit

@MainActor
final class CalendarManager {
    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            return true
        case .notDetermined:
            if #available(macOS 14.0, *) {
                return (try? await store.requestFullAccessToEvents()) ?? false
            } else {
                return await withCheckedContinuation { continuation in
                    store.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
        default:
            return false
        }
    }

    func logSession(_ session: Session) async {
        guard await requestAccess() else { return }
        guard let calendar = pomodoroCalendar() else { return }

        let event = EKEvent(eventStore: store)
        event.title = session.label.isEmpty ? "Pomodoro" : session.label
        event.startDate = session.startTime
        event.endDate = session.startTime.addingTimeInterval(TimeInterval(session.duration))
        event.notes = "Pomodoro session"
        event.calendar = calendar

        try? store.save(event, span: .thisEvent)
    }

    private func pomodoroCalendar() -> EKCalendar? {
        if let existing = store.calendars(for: .event).first(where: { $0.title == "Pomodoro" }) {
            return existing
        }
        guard let source = defaultSource() else { return nil }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Pomodoro"
        calendar.source = source
        calendar.cgColor = CGColor(red: 1, green: 0.3, blue: 0.2, alpha: 1) // tomato red
        try? store.saveCalendar(calendar, commit: true)
        return calendar
    }

    private func defaultSource() -> EKSource? {
        store.sources.first { $0.sourceType == .calDAV && $0.title == "iCloud" }
            ?? store.sources.first { $0.sourceType == .local }
            ?? store.defaultCalendarForNewEvents?.source
    }
}
