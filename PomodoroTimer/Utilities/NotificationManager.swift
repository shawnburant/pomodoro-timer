import UserNotifications

struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sendWorkSessionComplete(label: String) {
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Pomodoro complete!" : "\(label) complete!"
        content.body = "Time for a break."
        content.sound = .default
        schedule(content, id: "session-complete")
    }

    static func sendBreakComplete() {
        let content = UNMutableNotificationContent()
        content.title = "Break over."
        content.body = "Ready to focus?"
        content.sound = .default
        schedule(content, id: "break-complete")
    }

    private static func schedule(_ content: UNMutableNotificationContent, id: String) {
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
