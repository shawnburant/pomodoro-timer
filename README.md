# Pomodoro Timer

A minimal macOS menu bar Pomodoro timer. Stays out of your way until you need it.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)

## Features

- **Menu bar countdown** — live timer display (🍅 24:30) without cluttering your dock
- **Full Pomodoro cycle** — 25 min work → 5 min break × 3 → 15 min long break, auto-advancing
- **Session labels** — name what you're working on; label appears in notifications and calendar events
- **Task list** — tracks named tasks across sessions; see total pomodoro count per task, mark complete, switch between tasks
- **Task autocomplete** — clicking the session label field drops down your active tasks; type to filter, tap to select
- **Configurable durations** — set work, short break, and long break lengths from the Settings tab
- **Audio feedback** — soft tick sound during countdown, alarm on completion (with volume control)
- **System notifications** — alerts when sessions and breaks complete, even when the app is hidden
- **Calendar logging** — logs completed work sessions to a "Pomodoro" calendar in Calendar.app
- **Global keyboard shortcuts** — control the timer from any app
- **Sleep/wake aware** — timer stays accurate across system sleep

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| ⌘⇧S | Start / Pause |
| ⌘⇧R | Reset |
| ⌘⇧N | New Session (opens popover) |

## Requirements

- macOS 13.0 or later
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Installation

Clone the repo and run the install script:

```bash
git clone https://github.com/shawnburant/pomodoro-timer.git
cd pomodoro-timer
./install.sh
```

This builds a Release binary, installs it to `/Applications`, and launches it. The first time macOS may block it since it's unsigned — right-click the app → **Open** → **Open** to bypass Gatekeeper once.

To launch automatically on login, go to **System Settings → General → Login Items** and add PomodoroTimer.

## Building for Development

```bash
xcodegen generate
open PomodoroTimer.xcodeproj
```

Then press **Cmd+R** to build and run in debug mode.

## Permissions

The app will request the following permissions at runtime:

- **Notifications** — to alert you when sessions complete
- **Calendar** — optional; only requested if you enable "Log to Calendar" in Settings

No accessibility permissions are required. Global keyboard shortcuts use the Carbon hotkey API.

## Tech Stack

- Swift 6 + SwiftUI
- AppKit (`NSStatusItem`, `NSPopover`)
- AVFoundation for audio
- EventKit for calendar integration
- UserNotifications for alerts
- Carbon for global hotkeys
