#Requires AutoHotkey v2.0

class Config {
    static Default := {
        hotkey: "F7",
        soundEnabled: true,
        osdEnabled: true,
        overlaySize: 40,
        overlayMonitor: 0,  ; 0 = secondary (fallback primary)
    }

    static Load(path) {
        if !FileExist(path)
            return Config.Default.Clone()

        text := FileRead(path)
        if text = ""
            return Config.Default.Clone()

        cfg := Config.Default.Clone()
        ; Parse simple flat JSON
        for key, defaultVal in Config.Default.OwnProps() {
            pattern := '"' . key . '"\s*:\s*'
            if defaultVal is String
                pattern .= '"([^"]*)"'
            else if defaultVal is Integer && (defaultVal = 0 || defaultVal = 1) && !(key ~= "Size|Monitor")
                pattern .= '(true|false|\d+)'
            else
                pattern .= '(-?\d+)'

            if RegExMatch(text, pattern, &m) {
                val := m[1]
                if val = "true"
                    cfg.%key% := true
                else if val = "false"
                    cfg.%key% := false
                else if defaultVal is Integer
                    cfg.%key% := Integer(val)
                else
                    cfg.%key% := val
            }
        }
        return cfg
    }

    static Save(path, cfg) {
        lines := []
        for key, val in cfg.OwnProps() {
            if val is String
                lines.Push('  "' . key . '": "' . val . '"')
            else if val = true
                lines.Push('  "' . key . '": true')
            else if val = false
                lines.Push('  "' . key . '": false')
            else
                lines.Push('  "' . key . '": ' . val)
        }

        text := "{`n"
        loop lines.Length {
            text .= lines[A_Index]
            if A_Index < lines.Length
                text .= ",`n"
            else
                text .= "`n"
        }
        text .= "}"

        f := FileOpen(path, "w", "UTF-8")
        f.Write(text)
        f.Close()
    }
}
