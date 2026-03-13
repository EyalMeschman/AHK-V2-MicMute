# MicMute AHK v2 - Design Document

## Overview

A microphone mute/unmute utility built in AutoHotkey v2, inspired by [SaifAqqad/AHK_MicMute](https://github.com/SaifAqqad/AHK_MicMute). This is a learning project focused on AHK v2 and Windows system programming.

**Target feature set:** Core mute/unmute hotkey, system tray icon, GDI+ overlay, sound feedback, and OSD notifications.

## Architecture

Event-driven design with a central coordinator (`MicMute.ahk`) wiring together independent components via callbacks. Components do not know about each other -- `MicController` emits state changes, and the entry point routes them to all UI components.

```
                    ┌─────────────┐
                    │ MicMute.ahk │  (entry point / coordinator)
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           v               v               v
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │   Config   │  │ HotkeyMgr  │  │  TrayMenu  │
    └────────────┘  └─────┬──────┘  └─────┬──────┘
                          │               │
                          v               v
                   ┌──────────────┐
                   │MicController │ ◄── VA.ahk (Core Audio COM)
                   └──────┬───────┘
                          │ onStateChange callback
              ┌───────────┼───────────┬──────────┐
              v           v           v          v
       ┌──────────┐ ┌─────────┐ ┌────────┐ ┌─────────┐
       │SoundFeed │ │   OSD   │ │Overlay │ │TrayMenu │
       │  back    │ │         │ │ (GDI+) │ │(update) │
       └──────────┘ └─────────┘ └────────┘ └─────────┘
```

## File Structure

```
AHK-V2-MicMute/
├── MicMute.ahk              # Entry point: wires everything together
├── lib/
│   ├── MicController.ahk    # Mute/unmute via Core Audio
│   ├── HotkeyMgr.ahk        # Hotkey registration and dispatch
│   ├── Overlay.ahk           # GDI+ always-on-top overlay
│   ├── OSD.ahk               # Transient on-screen notification
│   ├── SoundFeedback.ahk     # Play mute/unmute sounds
│   ├── TrayMenu.ahk          # System tray icon + context menu
│   └── Config.ahk            # Load/save JSON config
├── vendor/
│   ├── VA.ahk                # Core Audio COM wrapper (v2 port)
│   └── Gdip_All.ahk          # GDI+ wrapper (v2)
├── resources/
│   ├── icons/
│   │   ├── mic_muted.ico
│   │   ├── mic_unmuted.ico
│   │   ├── overlay_muted.png
│   │   └── overlay_unmuted.png
│   └── sounds/
│       ├── mute.wav
│       └── unmute.wav
├── docs/
│   └── plans/
│       └── 2026-03-14-micmute-ahkv2-design.md  (this file)
└── config.json
```

## Component Contracts

### MicController

The core component. Controls microphone mute state via Windows Core Audio API.

```
Class MicController {
    __New(deviceName?)      ; Initialize, find capture device
    Toggle()                ; Flip mute state
    Mute()                  ; Explicitly mute
    Unmute()                ; Explicitly unmute
    IsMuted => bool         ; Property: current state
    OnStateChange           ; Callback: (isMuted) => void
}
```

Internally uses VA.ahk: `VA_SetMasterMute`, `VA_GetMasterMute`, `VA_GetDevice`.

### HotkeyMgr

Registers global hotkeys and dispatches to callbacks.

```
Class HotkeyMgr {
    Register(keyCombo, callback, options?)
    Unregister(keyCombo)
}
```

Options: `{passthrough: false, wildcard: false}`.
Supports toggle mode (single key) and PTT (hold-to-talk using `KeyWait`).

### Overlay

GDI+ layered window showing mic state. Always-on-top, click-through by default.

```
Class Overlay {
    __New(options)          ; Create GDI+ layered window
    Update(isMuted)         ; Redraw with correct icon
    Show() / Hide()
    ToggleVisibility()
    ToggleLock()            ; Enable/disable dragging
}
```

Window styles: `-Caption +E0x20 +E0x80000 +AlwaysOnTop +ToolWindow`
- `WS_EX_TRANSPARENT (0x20)` = click-through
- `WS_EX_LAYERED (0x80000)` = layered/transparent window

Uses: `Gdip_Startup`, `CreateCompatibleDC`, `CreateDIBSection`, `Gdip_FillRoundedRectangle`, `Gdip_DrawImage`, `UpdateLayeredWindow`.

### OSD

Transient on-screen notification that auto-hides.

```
Class OSD {
    Show(message, durationMs := 2000)
}
```

Uses native AHK v2 `Gui` with `-Caption +AlwaysOnTop +ToolWindow` and `WinSetTransparent`.
Positioned at bottom-center of screen. Auto-hides via `SetTimer`.

### SoundFeedback

Plays different sounds for mute/unmute actions.

```
Class SoundFeedback {
    __New(soundDir)
    Play(type)              ; type: "mute" or "unmute"
}
```

Uses AHK v2 built-in `SoundPlay` (no external DLL needed for core functionality).

### TrayMenu

System tray icon with context menu.

```
Class TrayMenu {
    __New(micController)
    UpdateIcon(isMuted)
}
```

Menu items: Toggle Mute, separator, Exit.
Uses `A_TrayMenu`, `TraySetIcon`.

### Config

Loads and saves user configuration as JSON.

```
Class Config {
    static Load(path) => configObj
    static Save(path, configObj)
}
```

Stores: hotkey combo, overlay position/visibility, sound enabled, OSD enabled.

## Data Flow

### Hotkey Press Sequence

```
User presses hotkey (e.g. F13)
  → AHK hotkey engine triggers callback
    → HotkeyMgr dispatches to MicController.Toggle()
      → MicController calls VA_SetMasterMute(!current)
        → Windows Core Audio mutes/unmutes the mic
      → MicController updates IsMuted property
      → MicController invokes OnStateChange(isMuted)
        → SoundFeedback.Play("mute" or "unmute")
        → OSD.Show("Muted" or "Unmuted")
        → Overlay.Update(isMuted)
        → TrayMenu.UpdateIcon(isMuted)
```

### Startup Sequence

```
MicMute.ahk starts
  → Config.Load("config.json")
  → MicController.__New(config.device)
  → TrayMenu.__New(micController)
  → Overlay.__New(config.overlay)
  → HotkeyMgr.Register(config.hotkey, micController.Toggle.Bind(micController))
  → Wire MicController.OnStateChange to all UI components
  → Read initial mic state and update all UI
```

## Dependencies

Only two external AHK v2 libraries are needed:

| Library | Source | Purpose |
|---------|--------|---------|
| VA.ahk (v2) | [SaifAqqad/VA.ahk](https://github.com/SaifAqqad/VA.ahk) v2 branch | Windows Core Audio COM wrapper for mute/unmute/device enumeration |
| Gdip_All.ahk | [mmikeww/AHKv2-Gdip](https://github.com/mmikeww/AHKv2-Gdip) | GDI+ drawing for the overlay |

No BASS DLL, no Neutron, no package manager needed.

## Difficulty Assessment

| Component | Difficulty | Estimated Time | Key Challenge |
|-----------|-----------|---------------|---------------|
| Learning AHK v2 | Medium | 3-5 days | Unique syntax, event model |
| Hotkey registration | Easy | 1-2 days | AHK's core strength |
| Mic mute/unmute | Medium | 2-3 days | COM Core Audio via VA.ahk |
| System tray | Easy | 1 day | Built into AHK |
| Sound feedback | Easy | 1 day | Built-in SoundPlay |
| OSD | Easy-Medium | 1-2 days | Transparent GUI, auto-hide |
| GDI+ Overlay | Hard | 3-5 days | Layered windows, GDI+ drawing, click-through |
| Config system | Easy | 1-2 days | JSON file I/O |

**Overall: Medium difficulty. Estimated timeline: 2-4 weeks.**

## Learning Roadmap (Build Order)

### Phase 1: Hello AHK (Day 1-2)
- Install AutoHotkey v2
- Create a script with a hotkey that shows a tooltip
- Learn: `#Requires`, `Hotkey()`, `ToolTip()`, `A_ScriptDir`, classes, fat arrow functions

### Phase 2: Mic Mute Toggle (Day 3-5)
- Download VA.ahk v2 port into `vendor/`
- Build `MicController` class
- Toggle mute on hotkey, verify in Windows Sound Settings
- Learn: `#Include`, COM basics, how VA.ahk wraps Core Audio

### Phase 3: System Tray (Day 5-6)
- Add tray icon that reflects mute state (different icons for muted/unmuted)
- Add right-click context menu (Toggle, Exit)
- Learn: `A_TrayMenu`, `TraySetIcon`, `Menu` class

### Phase 4: Sound Feedback (Day 6-7)
- Play different .wav files for mute vs unmute
- Learn: `SoundPlay`, resource file paths

### Phase 5: OSD Notification (Day 7-9)
- Create transparent, borderless GUI that appears briefly at bottom-center
- Auto-hide after ~2 seconds using `SetTimer`
- Learn: `Gui` class, `WinSetTransparent`, `WinSetRegion`, `SysGet`/`MonitorGet`

### Phase 6: GDI+ Overlay (Day 9-15) -- hardest phase
- Download Gdip_All.ahk into `vendor/`
- Initialize GDI+, create layered window
- Draw rounded rectangle background + mute/unmute icon
- Make it always-on-top, click-through
- Implement drag-to-reposition (toggle click-through via hotkey)
- Learn: GDI+ pipeline, device contexts, `UpdateLayeredWindow`, `OnMessage`, `WM_LBUTTONDOWN`

### Phase 7: Configuration (Day 15-18)
- Build `Config` class for JSON read/write
- Save and restore: hotkey, overlay position, feature toggles
- Learn: `FileRead`, `FileOpen`, JSON parsing/serialization in v2

### Phase 8: Polish (Day 18-25)
- PTT mode (hold to unmute, release to mute via `KeyWait`)
- Startup with Windows (Registry `Run` key or Task Scheduler)
- Handle device disconnection gracefully
- Multi-monitor overlay positioning

## Reference

The original AHK_MicMute (v1) codebase at https://github.com/SaifAqqad/AHK_MicMute is a valuable reference for implementation patterns, especially:
- `src/MicrophoneController.ahk` -- Core Audio integration patterns
- `src/UI/Overlay.ahk` -- GDI+ overlay implementation
- `src/UI/OSD.ahk` -- On-screen display approach
- `src/HotkeyManager.ahk` -- Hotkey multiplexing pattern

Note: The original is AHK v1 syntax, so code cannot be copied directly but the patterns and API usage translate.
