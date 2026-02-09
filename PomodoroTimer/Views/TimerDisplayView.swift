import SwiftUI

struct TimerDisplayView: View {
    let remainingSeconds: Int
    let sessionType: SessionType

    var body: some View {
        Text(TimeFormatting.format(seconds: remainingSeconds))
            .font(.system(size: 48, weight: .medium, design: .monospaced))
            .foregroundStyle(sessionType.accentColor)
    }
}
