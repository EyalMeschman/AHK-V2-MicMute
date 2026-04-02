#Requires AutoHotkey v2.0

class TrayMenu {
    static REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static REG_VALUE := "MicMute"

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
        A_TrayMenu.Add("Start on boot", (*) => this._ToggleStartup())
        A_TrayMenu.Add()  ; separator
        A_TrayMenu.Add("Exit", (*) => ExitApp())

        ; Set default action (double-click)
        A_TrayMenu.Default := "Toggle Mute"

        ; Check/uncheck startup menu item
        if this._IsStartupEnabled()
            A_TrayMenu.Check("Start on boot")

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

    _IsStartupEnabled() {
        try {
            RegRead(TrayMenu.REG_KEY, TrayMenu.REG_VALUE)
            return true
        }
        return false
    }

    _ToggleStartup() {
        if this._IsStartupEnabled() {
            RegDelete(TrayMenu.REG_KEY, TrayMenu.REG_VALUE)
            A_TrayMenu.Uncheck("Start on boot")
        } else {
            ahkExe := '"' . A_AhkPath . '"'
            script := '"' . A_ScriptFullPath . '"'
            RegWrite(ahkExe . " " . script, "REG_SZ", TrayMenu.REG_KEY, TrayMenu.REG_VALUE)
            A_TrayMenu.Check("Start on boot")
        }
    }
}
