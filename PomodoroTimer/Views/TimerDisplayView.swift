import SwiftUI

struct TimerDisplayView: View {
    let remainingSeconds: Int
    let sessionType: SessionType
    let isEditable: Bool
    let onDurationChange: (Int) -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $editText)
                    .font(.system(size: 48, weight: .medium, design: .monospaced))
                    .foregroundStyle(sessionType.accentColor)
                    .multilineTextAlignment(.center)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: fieldFocused) { focused in
                        if !focused { commitEdit() }
                    }
                    .frame(width: 140)
            } else {
                Text(TimeFormatting.format(seconds: remainingSeconds))
                    .font(.system(size: 48, weight: .medium, design: .monospaced))
                    .foregroundStyle(sessionType.accentColor)
                    .help(isEditable ? "Click to change duration" : "")
                    .onTapGesture {
                        guard isEditable else { return }
                        editText = TimeFormatting.format(seconds: remainingSeconds)
                        isEditing = true
                        fieldFocused = true
                    }
            }
        }
    }

    private func commitEdit() {
        isEditing = false
        let parts = editText.split(separator: ":")
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]),
              seconds < 60,
              minutes * 60 + seconds > 0
        else { return }
        onDurationChange(minutes * 60 + seconds)
    }
}
