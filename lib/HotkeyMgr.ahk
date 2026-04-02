#Requires AutoHotkey v2.0

class HotkeyMgr {
    _registeredKeys := Map()

    Register(keyCombo, callback, options?) {
        opts := IsSet(options) ? options : {}
        prefix := ""
        if HasProp(opts, "passthrough") && opts.passthrough
            prefix .= "~"
        if HasProp(opts, "wildcard") && opts.wildcard
            prefix .= "*"

        hotkeyStr := prefix . keyCombo
        Hotkey(hotkeyStr, callback, "On")
        this._registeredKeys[keyCombo] := hotkeyStr
    }

    Unregister(keyCombo) {
        if this._registeredKeys.Has(keyCombo) {
            Hotkey(this._registeredKeys[keyCombo], "Off")
            this._registeredKeys.Delete(keyCombo)
        }
    }
}
