#Requires AutoHotkey v2.0

class Config {
    static Default := {
        hotkey: "^!m",
        soundEnabled: true,
        osdEnabled: true,
        overlaySize: 40,
        overlayMonitor: 0,  ; 0 = secondary (fallback primary)
    }

    static BooleanKeys := ["soundEnabled", "osdEnabled"]

    static Load(path) {
        if !FileExist(path)
            return Config.Default.Clone()

        text := FileRead(path)
        if text = ""
            return Config.Default.Clone()

        cfg := Config.Default.Clone()
        ; Parse simple flat JSON
        for key, defaultVal in Config.Default.OwnProps() {
            isBool := false
            for bk in Config.BooleanKeys {
                if key = bk {
                    isBool := true
                    break
                }
            }

            pattern := '"' . key . '"\s*:\s*'
            if defaultVal is String
                pattern .= '"([^"]*)"'
            else if isBool
                pattern .= '(true|false)'
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
            isBool := false
            for bk in Config.BooleanKeys {
                if key = bk {
                    isBool := true
                    break
                }
            }
            if val is String
                lines.Push('  "' . key . '": "' . val . '"')
            else if isBool
                lines.Push('  "' . key . '": ' . (val ? "true" : "false"))
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

        try {
            f := FileOpen(path, "w", "UTF-8")
            f.Write(text)
            f.Close()
        }
    }
}
