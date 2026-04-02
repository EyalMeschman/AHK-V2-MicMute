#Requires AutoHotkey v2.0

class SoundFeedback {
    _soundDir := ""
    _enabled := true

    __New(soundDir := "") {
        this._soundDir := soundDir
    }

    Enabled {
        get => this._enabled
        set => this._enabled := value
    }

    Play(type) {
        if !this._enabled
            return
        if this._soundDir = ""
            return

        soundFile := this._soundDir . "\" . type . ".wav"
        if FileExist(soundFile)
            SoundPlay(soundFile)
    }
}
