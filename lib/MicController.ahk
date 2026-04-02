#Requires AutoHotkey v2.0

class MicController {
    _isMuted := false
    _deviceName := "Microphone"
    _onStateChange := ""
    _connected := false
    _reconnectFn := ""

    __New(deviceName?) {
        if IsSet(deviceName)
            this._deviceName := deviceName
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
        if !this._connected
            return
        try {
            SoundSetMute(-1, , this._deviceName)
            this._UpdateState()
        } catch {
            this._OnDisconnect()
        }
    }

    Mute() {
        if !this._connected
            return
        try {
            SoundSetMute(true, , this._deviceName)
            this._UpdateState()
        } catch {
            this._OnDisconnect()
        }
    }

    Unmute() {
        if !this._connected
            return
        try {
            SoundSetMute(false, , this._deviceName)
            this._UpdateState()
        } catch {
            this._OnDisconnect()
        }
    }

    _ReadMuteState() {
        try
            return SoundGetMute(, this._deviceName) = 1
        catch {
            this._OnDisconnect()
            return this._isMuted
        }
    }

    _UpdateState() {
        this._isMuted := this._ReadMuteState()
        if this._onStateChange
            this._onStateChange.Call(this._isMuted)
    }

    _CheckDevice() {
        try {
            SoundGetMute(, this._deviceName)
            return true
        }
        return false
    }

    _OnDisconnect() {
        if !this._connected
            return
        this._connected := false
        this._StartReconnect()
    }

    _StartReconnect() {
        ; Check every 2 seconds for device reconnection
        SetTimer(this._reconnectFn, 2000)
    }

    _TryReconnect() {
        if this._CheckDevice() {
            this._connected := true
            SetTimer(this._reconnectFn, 0)
            this._UpdateState()
        }
    }
}
