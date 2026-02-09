# Pomodoro Timer - macOS Menu Bar App

## Goal
Build a macOS menu bar Pomodoro timer that helps track focused work sessions with calendar integration for completed pomodoros.

## Core Features
- Menu bar countdown display (e.g., "🍅 24:30")
- Standard Pomodoro timing (25 min work, 5 min short break, 15 min long break)
- Session labeling (what you're working on)
- Calendar integration to log completed pomodoros
- Configurable keyboard shortcuts
- Audio feedback (ticking sound + completion alarm)
- macOS notifications on completion

## Tech Stack
- Swift + SwiftUI
- NSStatusItem for menu bar presence
- EventKit for calendar integration
- AVFoundation for audio playback
- UserNotifications for system notifications
- UserDefaults for settings persistence

## Phase 1: Core Timer Functionality
- [ ] Set up Xcode project with SwiftUI lifecycle
- [ ] Create menu bar status item with basic icon
- [ ] Implement Timer model with states (running, paused, stopped)
- [ ] Build countdown logic (25 min default)
- [ ] Display countdown in menu bar (update every second)
- [ ] Create popover UI with timer display and basic controls
- [ ] Add Start/Pause button
- [ ] Add Stop/Reset button
- [ ] Add visual state indication (work vs break)

## Phase 2: Session Management
- [ ] Create Session model (label, start time, duration, type)
- [ ] Add session label text field to popover
- [ ] Implement "Repeat Session" functionality
- [ ] Add "New Session" action (resets label and timer)
- [ ] Store current session state in memory

## Phase 3: Pomodoro Flow
- [ ] Implement full Pomodoro cycle:
  - Work session (25 min) → Short break (5 min) → repeat 3x
  - After 4th work session → Long break (15 min)
- [ ] Auto-transition between work and breaks
- [ ] Track Pomodoro count in current cycle
- [ ] Display current phase in popover (Work 1/4, Break, etc.)

## Phase 4: Audio Feedback
- [ ] Add ticking sound file to project (or generate simple tick)
- [ ] Implement audio player using AVFoundation
- [ ] Add toggle for ticking sound in popover
- [ ] Add completion alarm sound file
- [ ] Play alarm when timer completes
- [ ] Ensure audio works even when app is in background

## Phase 5: Notifications
- [ ] Request notification permissions on first launch
- [ ] Send notification when work session completes
- [ ] Send notification when break completes
- [ ] Include session label in notification content
- [ ] Add notification actions (Start Break, Skip Break, etc.)

## Phase 6: Keyboard Shortcuts
- [ ] Set up global keyboard shortcut listener
- [ ] Implement default shortcuts:
  - Cmd+Shift+S: Start/Pause
  - Cmd+Shift+R: Reset/Stop
  - Cmd+Shift+N: New Session
- [ ] Add keyboard shortcut display in popover
- [ ] (Future: Make shortcuts configurable in settings)

## Phase 7: Calendar Integration
- [ ] Request calendar access permissions
- [ ] Create/access "Pomodoro" calendar (or let user choose)
- [ ] When work session completes, create calendar event:
  - Title: Session label
  - Start time: Actual start time
  - Duration: 25 minutes
  - Notes: "Pomodoro session"
- [ ] Handle calendar permission denials gracefully
- [ ] Add toggle to enable/disable calendar logging

## Phase 8: Polish & UX
- [ ] Design proper menu bar icon (tomato with countdown)
- [ ] Add app icon
- [ ] Create preferences/settings window (accessible from menu)
- [ ] Add "About" menu item
- [ ] Add "Quit" menu item
- [ ] Ensure app survives system sleep/wake
- [ ] Test timer accuracy over long periods
- [ ] Add basic error handling and logging

## Technical Notes
- Use `NSStatusBar.system.statusItem()` for menu bar
- Use `Timer.publish()` or async/await for countdown
- EventKit requires calendar permissions in Info.plist
- Global shortcuts require accessibility permissions
- Store audio files in app bundle's Resources
- Consider using SwiftUI's `@StateObject` for timer state

## Future Enhancements (Not in Initial Build)
- Configurable timer durations
- Statistics dashboard
- Multiple timer presets
- Dark/light mode icon variants
- Integration with other calendars (Google, etc.)
- Export session history

## Success Criteria
- Timer counts down accurately in menu bar
- Can start, pause, and reset sessions
- Completed pomodoros appear in Calendar.app
- Keyboard shortcuts work from any app
- Audio and notifications work reliably
- App feels native and polished
