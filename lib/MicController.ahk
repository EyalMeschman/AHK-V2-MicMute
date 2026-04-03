#Requires AutoHotkey v2.0

class MicController {
    _isMuted := false
    _onStateChange := ""
    _connected := false
    _reconnectFn := ""

    __New() {
        this._reconnectFn := this._TryReconnect.Bind(this)
        this._connected := this._CheckDevice()
        if this._connected
            this._isMuted := this._ReadMuteState()
        else
            this._StartReconnect()
    }

    IsMuted => this._isMuted
    Connected => this._connected

    OnStateChange {
        get => this._onStateChange
        set => this._onStateChange := value
    }

    Toggle() {
        this._SetMute(!this._isMuted)
    }

    Mute() {
        this._SetMute(true)
    }

    Unmute() {
        this._SetMute(false)
    }

    _SetMute(state) {
        try {
            endpointVolume := this._GetEndpointVolume()
            try {
                guidNull := Buffer(16, 0)
                ComCall(14, endpointVolume, "Int", state, "Ptr", guidNull)
            } finally {
                ObjRelease(endpointVolume)
            }
            this._isMuted := state
            this._connected := true
            this._NotifyChange()
        } catch {
            this._OnDisconnect()
        }
    }

    ; Re-acquires the default capture device every time — no caching
    ; so switching default mic in Windows Settings takes effect immediately
    _GetEndpointVolume() {
        deviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}"
            , "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

        defaultDevice := 0
        ComCall(4, deviceEnumerator, "UInt", 1, "UInt", 0, "Ptr*", &defaultDevice)
        if !defaultDevice
            throw Error("No default capture device")

        try {
            IID := Buffer(16)
            DllCall("ole32\CLSIDFromString", "Str", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "Ptr", IID, "UInt")
            endpointVolume := 0
            ComCall(3, defaultDevice, "Ptr", IID, "UInt", 23, "Ptr", 0, "Ptr*", &endpointVolume)
        } finally {
            ObjRelease(defaultDevice)
        }
        if !endpointVolume
            throw Error("Failed to get IAudioEndpointVolume")

        return endpointVolume
    }

    _ReadMuteState() {
        try {
            endpointVolume := this._GetEndpointVolume()
            try {
                muted := 0
                ComCall(15, endpointVolume, "UInt*", &muted)
                return muted != 0
            } finally {
                ObjRelease(endpointVolume)
            }
        } catch {
            return this._isMuted
        }
    }

    _CheckDevice() {
        try {
            deviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}"
                , "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
            defaultDevice := 0
            ComCall(4, deviceEnumerator, "UInt", 1, "UInt", 0, "Ptr*", &defaultDevice)
            if !defaultDevice
                return false
            ObjRelease(defaultDevice)
            return true
        }
        return false
    }

    _NotifyChange() {
        if this._onStateChange
            this._onStateChange.Call(this._isMuted)
    }

    _OnDisconnect() {
        if !this._connected
            return
        this._connected := false
        this._StartReconnect()
    }

    _StartReconnect() {
        SetTimer(this._reconnectFn, 2000)
    }

    _TryReconnect() {
        if this._CheckDevice() {
            this._connected := true
            SetTimer(this._reconnectFn, 0)
            this._isMuted := this._ReadMuteState()
            this._NotifyChange()
        }
    }
}
