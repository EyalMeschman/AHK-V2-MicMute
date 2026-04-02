#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\MicController.ahk
#Include lib\HotkeyMgr.ahk
#Include lib\TrayMenu.ahk
#Include lib\SoundFeedback.ahk
#Include lib\Overlay.ahk

; --- Initialize components ---
mic := MicController()
hkMgr := HotkeyMgr()
tray := TrayMenu(mic, A_ScriptDir . "\resources\icons")
sound := SoundFeedback(A_ScriptDir . "\resources\sounds")
ovl := Overlay({iconsDir: A_ScriptDir . "\resources\icons", size: 38})

; --- State change handler ---
mic.OnStateChange := OnMicStateChange

; --- Register hotkey (F7 to toggle) ---
hkMgr.Register("F7", (*) => mic.Toggle())

; --- Show initial state ---
OnMicStateChange(mic.IsMuted)

OnMicStateChange(isMuted) {
    tray.UpdateIcon(isMuted)
    ovl.Update(isMuted)
    sound.Play(isMuted ? "mute" : "unmute")
}
