import AppKit

struct AudioManager {
    func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }
}
