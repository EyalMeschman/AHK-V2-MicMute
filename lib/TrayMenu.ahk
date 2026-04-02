#Requires AutoHotkey v2.0

class TrayMenu {
    ; Shell32.dll icon indices for tray
    ; 138 = microphone-like icon, 131 = muted/blocked
    ; Using simpler icons: 1 = blank doc, 132 = warning
    ; We'll use custom ico files from resources/icons/ if available,
    ; otherwise fall back to colored H icons via icon number

    _micController := ""
    _mutedIcon := ""
    _unmutedIcon := ""

    __New(micController, iconsDir := "") {
        this._micController := micController

        if iconsDir != "" && FileExist(iconsDir . "\mic_muted.ico") {
            this._mutedIcon := iconsDir . "\mic_muted.ico"
            this._unmutedIcon := iconsDir . "\mic_unmuted.ico"
        }

        ; Remove default menu items
        A_TrayMenu.Delete()

        ; Add our items
        A_TrayMenu.Add("Toggle Mute", (*) => this._micController.Toggle())
        A_TrayMenu.Add()  ; separator
        A_TrayMenu.Add("Exit", (*) => ExitApp())

        ; Set default action (double-click)
        A_TrayMenu.Default := "Toggle Mute"

        ; Set tooltip
        A_IconTip := "MicMute"

        ; Update icon to initial state
        this.UpdateIcon(micController.IsMuted)
    }

    UpdateIcon(isMuted) {
        if this._mutedIcon != "" {
            TraySetIcon(isMuted ? this._mutedIcon : this._unmutedIcon)
        }
        A_IconTip := isMuted ? "MicMute - Muted" : "MicMute - Unmuted"
    }
}
