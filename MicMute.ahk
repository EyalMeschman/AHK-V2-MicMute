#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\MicController.ahk
#Include lib\HotkeyMgr.ahk

; --- Initialize components ---
mic := MicController()
hkMgr := HotkeyMgr()

; --- State change handler (tooltip feedback for now) ---
mic.OnStateChange := OnMicStateChange

; --- Register hotkey (F7 to toggle) ---
hkMgr.Register("F7", (*) => mic.Toggle())

; --- Show initial state ---
OnMicStateChange(mic.IsMuted)

OnMicStateChange(isMuted) {
    state := isMuted ? "MUTED" : "UNMUTED"
    ToolTip("Mic: " . state)
    SetTimer(() => ToolTip(), -2000)
}
