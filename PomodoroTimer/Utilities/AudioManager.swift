import AppKit

struct AudioManager {
    private let tickSound: NSSound? = {
        guard let url = Bundle.main.url(forResource: "tick", withExtension: "aiff") else { return nil }
        return NSSound(contentsOf: url, byReference: true)
    }()

    func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }

    func playTickSound() {
        DispatchQueue.global(qos: .userInteractive).async {
            tickSound?.stop()
            tickSound?.play()
        }
    }
}
