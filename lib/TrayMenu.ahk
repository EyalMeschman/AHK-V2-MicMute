#Requires AutoHotkey v2.0
#Include Config.ahk

class TrayMenu {
    static REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static REG_VALUE := "MicMute"

    _micController := ""
    _mutedIcon := ""
    _unmutedIcon := ""
    _cfg := ""
    _configPath := ""
    _sound := ""
    _notify := ""
    _ovl := ""

    __New(micController, iconsDir, cfg, configPath, sound, notify, ovl) {
        this._micController := micController
        this._cfg := cfg
        this._configPath := configPath
        this._sound := sound
        this._notify := notify
        this._ovl := ovl

        if iconsDir != "" && FileExist(iconsDir . "\mic_muted.ico") {
            this._mutedIcon := iconsDir . "\mic_muted.ico"
            this._unmutedIcon := iconsDir . "\mic_unmuted.ico"
        }

        ; Remove default menu items
        A_TrayMenu.Delete()

        ; Add our items
        A_TrayMenu.Add("Toggle Mute", (*) => this._micController.Toggle())
        A_TrayMenu.Add()  ; separator
        A_TrayMenu.Add("Sound", (*) => this._ToggleSound())
        A_TrayMenu.Add("Notifications", (*) => this._ToggleOSD())
        A_TrayMenu.Add()  ; separator
        A_TrayMenu.Add("Change Hotkey", (*) => this._ChangeHotkey())
        A_TrayMenu.Add("Overlay Monitor", (*) => this._ChangeMonitor())
        A_TrayMenu.Add("Start on boot", (*) => this._ToggleStartup())
        A_TrayMenu.Add()  ; separator
        A_TrayMenu.Add("Exit", (*) => ExitApp())

        ; Set default action (double-click)
        A_TrayMenu.Default := "Toggle Mute"

        ; Set checkmarks based on current config
        if cfg.soundEnabled
            A_TrayMenu.Check("Sound")
        if cfg.osdEnabled
            A_TrayMenu.Check("Notifications")
        if this._IsStartupEnabled()
            A_TrayMenu.Check("Start on boot")

        A_IconTip := "MicMute"
        this.UpdateIcon(micController.IsMuted)
    }

    UpdateIcon(isMuted) {
        if this._mutedIcon != "" {
            TraySetIcon(isMuted ? this._mutedIcon : this._unmutedIcon)
        }
        A_IconTip := isMuted ? "MicMute - Muted" : "MicMute - Unmuted"
    }

    _ToggleSound() {
        this._cfg.soundEnabled := !this._cfg.soundEnabled
        this._sound.Enabled := this._cfg.soundEnabled
        if this._cfg.soundEnabled
            A_TrayMenu.Check("Sound")
        else
            A_TrayMenu.Uncheck("Sound")
        this._SaveConfig()
    }

    _ToggleOSD() {
        this._cfg.osdEnabled := !this._cfg.osdEnabled
        this._notify.Enabled := this._cfg.osdEnabled
        if this._cfg.osdEnabled
            A_TrayMenu.Check("Notifications")
        else
            A_TrayMenu.Uncheck("Notifications")
        this._SaveConfig()
    }

    _ChangeHotkey() {
        hkGui := Gui("+AlwaysOnTop -MinimizeBox", "Change Hotkey")
        hkGui.SetFont("s11", "Segoe UI")
        hkGui.Add("Text", "w280", "Press your desired key combination:")
        hkCtrl := hkGui.Add("Hotkey", "w280", this._cfg.hotkey)
        saveBtn := hkGui.Add("Button", "w280 Default", "Save")

        saved := false
        saveBtn.OnEvent("Click", (*) => (saved := true, hkGui.Hide()))
        hkGui.OnEvent("Close", (*) => hkGui.Hide())

        ; Temporarily disable current hotkey so it doesn't intercept
        try Hotkey(this._cfg.hotkey, "Off")

        hkGui.Show("AutoSize")
        WinWaitClose(hkGui)

        newKey := hkCtrl.Value
        hkGui.Destroy()

        if !saved || newKey = "" {
            ; Re-enable old hotkey if cancelled
            try Hotkey(this._cfg.hotkey, "On")
            return
        }

        ; Unregister old, register new
        try Hotkey(this._cfg.hotkey, "Off")
        this._cfg.hotkey := newKey
        Hotkey(this._cfg.hotkey, (*) => this._micController.Toggle(), "On")
        this._SaveConfig()
    }

    _ChangeMonitor() {
        count := MonitorGetCount()
        primary := MonitorGetPrimary()

        choices := []
        loop count {
            name := ""
            try name := MonitorGetName(A_Index)
            if A_Index = primary
                label := "Primary"
            else if count = 2
                label := "Secondary"
            else
                label := "Monitor #" . A_Index
            choices.Push(label)
        }

        monGui := Gui("+AlwaysOnTop -MinimizeBox", "Overlay Monitor")
        monGui.SetFont("s11", "Segoe UI")
        monGui.Add("Text", "w280", "Choose which monitor for the overlay:")
        currentChoice := this._cfg.overlayMonitor = 0 ? this._ovl._GetSecondaryMonitor() : this._cfg.overlayMonitor
        ddl := monGui.Add("DropDownList", "w280 Choose" . currentChoice, choices)
        saveBtn := monGui.Add("Button", "w280 Default", "Save")

        saved := false
        saveBtn.OnEvent("Click", (*) => (saved := true, monGui.Hide()))
        monGui.OnEvent("Close", (*) => monGui.Hide())

        monGui.Show("AutoSize")
        WinWaitClose(monGui)

        selectedIndex := ddl.Value
        monGui.Destroy()

        if !saved || selectedIndex = 0
            return

        this._cfg.overlayMonitor := selectedIndex  ; 1-based monitor number
        this._ovl.SetMonitor(this._cfg.overlayMonitor)
        this._SaveConfig()
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

    _IsStartupEnabled() {
        try {
            RegRead(TrayMenu.REG_KEY, TrayMenu.REG_VALUE)
            return true
        }
        return false
    }

    _SaveConfig() {
        Config.Save(this._configPath, this._cfg)
    }
}
