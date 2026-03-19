import Carbon

// Global storage needed for C callback — safe because it's only written on MainActor at init
nonisolated(unsafe) private var hotKeyActions: [UInt32: () -> Void] = [:]

private func carbonEventHandler(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    hotKeyActions[hotKeyID.id]?()
    return noErr
}

final class HotKeyManager {
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []

    @MainActor
    init(timerModel: TimerModel) {
        hotKeyActions[1] = { Task { @MainActor in timerModel.startPause() } }
        hotKeyActions[2] = { Task { @MainActor in timerModel.stopReset() } }
        hotKeyActions[3] = { Task { @MainActor in
            timerModel.newSession()
            timerModel.onNewSessionFromHotkey?()
        } }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonEventHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        register(keyCode: UInt32(kVK_ANSI_S), id: 1) // ⌘⇧S — Start/Pause
        register(keyCode: UInt32(kVK_ANSI_R), id: 2) // ⌘⇧R — Reset
        register(keyCode: UInt32(kVK_ANSI_N), id: 3) // ⌘⇧N — New Session
    }

    private func register(keyCode: UInt32, id: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x504D5400), id: id)
        var ref: EventHotKeyRef?
        RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        hotKeyRefs.append(ref)
    }

    deinit {
        hotKeyRefs.compactMap { $0 }.forEach { UnregisterEventHotKey($0) }
        if let handler = eventHandlerRef { RemoveEventHandler(handler) }
    }
}
