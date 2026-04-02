# MicMute AHK v2

A lightweight microphone mute/unmute utility for Windows, built entirely in AutoHotkey v2 with **zero third-party libraries**. Mutes your default capture device via the Windows Core Audio API.

## Features

- **Global hotkey** to toggle mic mute (default: `Ctrl+Alt+M`)
- **System tray icon** that reflects mute state (red = muted, green = unmuted)
- **On-screen overlay** showing muted icon on your secondary monitor
- **OSD notification** with accent-colored popup ("Microphone Muted" / "Microphone Online")
- **Sound feedback** on mute/unmute
- **Settings via tray menu** -- toggle sound, notifications, change hotkey, choose overlay monitor, start on boot
- **Auto-reconnect** if your mic is disconnected/reconnected
- **Dynamic default device** -- switching your default mic in Windows Settings takes effect immediately

## Prerequisites

- **Windows 10/11**
- **[AutoHotkey v2](https://www.autohotkey.com/download/)** (v2.0 or later)

## Installation

1. Clone or download this repository
2. Double-click `MicMute.ahk` to run

That's it. No build step, no dependencies, no package manager.

## Usage

| Action            | How                                        |
| ----------------- | ------------------------------------------ |
| Toggle mute       | Press `Ctrl+Alt+M` (or your custom hotkey) |
| Toggle mute (alt) | Double-click the tray icon                 |
| Change settings   | Right-click the tray icon                  |
| Exit              | Right-click tray icon > Exit               |

### Tray Menu Options

- **Toggle Mute** -- mute/unmute your mic
- **Sound** -- enable/disable sound effects
- **Notifications** -- enable/disable the OSD popup
- **Change Hotkey** -- opens a hotkey picker to set a new key combination
- **Overlay Monitor** -- choose which monitor displays the mute overlay
- **Start on boot** -- launch MicMute automatically when you log in
- **Exit** -- close MicMute

## Configuration

Settings are stored in `config.json` and persist across restarts:

```json
{
  "hotkey": "^!m",
  "osdEnabled": true,
  "overlayMonitor": 2,
  "overlaySize": 40,
  "soundEnabled": true
}
```

| Setting          | Description                                                   |
| ---------------- | ------------------------------------------------------------- |
| `hotkey`         | AHK hotkey string                                             |
| `soundEnabled`   | Play sounds on mute/unmute                                    |
| `osdEnabled`     | Show on-screen notification                                   |
| `overlaySize`    | Overlay icon size in pixels                                   |
| `overlayMonitor` | Monitor number                                                |


## License

[MIT](LICENSE)
