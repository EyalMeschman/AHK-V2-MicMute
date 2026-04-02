#Requires AutoHotkey v2.0

class MicController {
    _isMuted := false
    _deviceName := "Microphone"
    _onStateChange := ""

    __New(deviceName?) {
        if IsSet(deviceName)
            this._deviceName := deviceName
        this._isMuted := this._ReadMuteState()
    }

    IsMuted => this._isMuted

    OnStateChange {
        get => this._onStateChange
        set => this._onStateChange := value
    }

    Toggle() {
        SoundSetMute(-1, , this._deviceName)
        this._UpdateState()
    }

    Mute() {
        SoundSetMute(true, , this._deviceName)
        this._UpdateState()
    }

    Unmute() {
        SoundSetMute(false, , this._deviceName)
        this._UpdateState()
    }

    _ReadMuteState() {
        return SoundGetMute(, this._deviceName) = 1
    }

    _UpdateState() {
        this._isMuted := this._ReadMuteState()
        if this._onStateChange
            this._onStateChange.Call(this._isMuted)
    }
}
