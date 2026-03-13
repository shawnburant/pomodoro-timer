import AppKit

struct AudioManager {
    private let tickSound = NSSound(named: "Tink")

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
