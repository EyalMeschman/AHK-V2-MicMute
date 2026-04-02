#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\Config.ahk
#Include lib\MicController.ahk
#Include lib\HotkeyMgr.ahk
#Include lib\TrayMenu.ahk
#Include lib\SoundFeedback.ahk
#Include lib\Overlay.ahk
#Include lib\OSD.ahk

; --- Load config ---
configPath := A_ScriptDir . "\config.json"
cfg := Config.Load(configPath)

; --- Initialize components ---
mic := MicController()
hkMgr := HotkeyMgr()
sound := SoundFeedback(A_ScriptDir . "\resources\sounds")
sound.Enabled := cfg.soundEnabled
ovl := Overlay({iconsDir: A_ScriptDir . "\resources\icons", size: cfg.overlaySize, monitor: cfg.overlayMonitor})
notify := OSD()
notify.Enabled := cfg.osdEnabled
tray := TrayMenu(mic, A_ScriptDir . "\resources\icons", cfg, configPath, sound, notify, ovl)

; --- State change handler ---
mic.OnStateChange := OnMicStateChange

; --- Register hotkey ---
hkMgr.Register(cfg.hotkey, (*) => mic.Toggle())

; --- Show initial state (without sound on startup) ---
sound.Enabled := false
OnMicStateChange(mic.IsMuted)
sound.Enabled := cfg.soundEnabled

OnMicStateChange(isMuted) {
    tray.UpdateIcon(isMuted)
    ovl.Update(isMuted)
    notify.Show(isMuted ? "Microphone Muted" : "Microphone Online", isMuted)
    sound.Play(isMuted ? "mute" : "unmute")
}
