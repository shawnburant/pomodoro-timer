# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS menu bar Pomodoro timer app built with Swift and SwiftUI. Features countdown display in menu bar, calendar integration for logging completed sessions, audio feedback, and global keyboard shortcuts.

## Build Commands

This is an Xcode project. Build and run using:
- **Build:** `xcodebuild -scheme PomodoroTimer build` or Cmd+B in Xcode
- **Run:** `xcodebuild -scheme PomodoroTimer run` or Cmd+R in Xcode
- **Clean:** `xcodebuild clean`

## Tech Stack

- **Swift + SwiftUI** with SwiftUI lifecycle (not AppKit AppDelegate)
- **NSStatusItem** for menu bar presence
- **EventKit** for Calendar.app integration
- **AVFoundation** for audio playback
- **UserNotifications** for system notifications
- **UserDefaults** for settings persistence

## Architecture

The app follows standard SwiftUI patterns with these key components:

- **Timer Model:** Manages countdown state (running, paused, stopped) using `Timer.publish()` or async/await
- **Session Model:** Tracks label, start time, duration, and session type (work/break)
- **Menu Bar:** `NSStatusBar.system.statusItem()` displays countdown (e.g., "🍅 24:30")
- **Popover UI:** SwiftUI popover attached to status item for controls

### Pomodoro Cycle Logic
- Work session (25 min) → Short break (5 min) → repeat 3x
- After 4th work session → Long break (15 min)
- Auto-transitions between phases

## Required Permissions (Info.plist)

- **Calendar access:** Required for EventKit to log completed pomodoros
- **Accessibility permissions:** Required for global keyboard shortcuts
- **Notification permissions:** Requested at runtime for session completion alerts

## Key Implementation Notes

- Use `@StateObject` for timer state management
- Audio files stored in app bundle's Resources folder
- Global shortcuts: Cmd+Shift+S (Start/Pause), Cmd+Shift+R (Reset), Cmd+Shift+N (New Session)
- Handle system sleep/wake to maintain timer accuracy
