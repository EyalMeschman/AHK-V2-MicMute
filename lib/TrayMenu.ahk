#Requires AutoHotkey v2.0

class TrayMenu {
    static REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static REG_VALUE := "MicMute"

    _micController := ""
    _hkMgr := ""
    _mutedIcon := ""
    _unmutedIcon := ""
    _cfg := ""
    _configPath := ""
    _sound := ""
    _notify := ""
    _ovl := ""

    __New(micController, hkMgr, iconsDir, cfg, configPath, sound, notify, ovl) {
        this._micController := micController
        this._hkMgr := hkMgr
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
        A_TrayMenu.Add("Sound", (*) => this._ToggleOption("soundEnabled", "Sound", this._sound))
        A_TrayMenu.Add("Notifications", (*) => this._ToggleOption("osdEnabled", "Notifications", this._notify))
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

    _ToggleOption(cfgKey, menuLabel, component) {
        this._cfg.%cfgKey% := !this._cfg.%cfgKey%
        component.Enabled := this._cfg.%cfgKey%
        if this._cfg.%cfgKey%
            A_TrayMenu.Check(menuLabel)
        else
            A_TrayMenu.Uncheck(menuLabel)
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
        this._hkMgr.Unregister(this._cfg.hotkey)

        hkGui.Show("AutoSize")
        WinWaitClose(hkGui)

        newKey := hkCtrl.Value
        hkGui.Destroy()

        if !saved || newKey = "" {
            ; Re-register old hotkey if cancelled
            this._hkMgr.Register(this._cfg.hotkey, (*) => this._micController.Toggle())
            return
        }

        ; Register new hotkey
        try {
            this._hkMgr.Register(newKey, (*) => this._micController.Toggle())
            this._cfg.hotkey := newKey
            this._SaveConfig()
        } catch {
            this._hkMgr.Register(this._cfg.hotkey, (*) => this._micController.Toggle())
        }
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
        currentChoice := this._ovl.GetCurrentMonitor()
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
