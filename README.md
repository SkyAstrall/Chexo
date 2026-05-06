# Chexo

A minimal floating task panel for macOS. Lives in your menu bar, ready when you need it.

## What it does

- **Floating panel** — stays above your windows, drag it anywhere on screen
- **Focus mode** — isolate a single task and zero in until it's done
- **Keyboard-first** — press `Cmd-N` to start typing a task, `Esc` to dismiss
- **Progress tracking** — see your completion rate at a glance
- **Lightweight** — no accounts, no sync, no subscriptions. Just tasks.

## Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.43+

## Build

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Generate the Xcode project from project.yml
xcodegen generate

# Build
xcodebuild -project Chexo.xcodeproj -scheme Chexo -configuration Debug build
```

Or open in Xcode after running `xcodegen generate`.

## Architecture

```
Chexo/
  ChexoApp.swift              — App entry point, SwiftData container setup
  Models/
    TaskItem.swift             — SwiftData model (title, completion, order, date)
  Views/
    FloatingPanelView.swift    — Main panel UI, task list, focus mode
    TaskRow.swift              — Single task row with checkbox, inline editing
  WindowManagement/
    FloatingPanel.swift        — NSPanel subclass (borderless, floating)
    PanelController.swift      — Menu bar status item and panel lifecycle
```

## Brand

- **Name**: Chexo (from "check off")
- **Tagline**: Chex it off.
- **Accent color**: Warm amber `#E08A30`
- See [STYLEGUIDE.md](STYLEGUIDE.md) for the full brand system.

## License

MIT License. See [LICENSE](LICENSE).
