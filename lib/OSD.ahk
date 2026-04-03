#Requires AutoHotkey v2.0

class OSD {
    static ACCENT_MUTED := "DC3545"    ; red
    static ACCENT_UNMUTED := "007BFF"  ; blue
    static BG_DARK := "272727"
    static WIDTH := 220
    static HEIGHT := 38
    static CORNER_RADIUS := 15

    _gui := ""
    _text := ""
    _accent := ""
    _enabled := true
    _hideFn := ""
    _scale := 1
    _w := 0
    _h := 0

    __New() {
        this._scale := A_ScreenDPI / 96

        w := Round(OSD.WIDTH * this._scale)
        h := Round(OSD.HEIGHT * this._scale)
        r := Round(OSD.CORNER_RADIUS * this._scale)
        fontSize := Round(12 * this._scale)

        this._gui := Gui("+AlwaysOnTop -Caption -Border +ToolWindow -DPIScale")
        this._gui.BackColor := OSD.BG_DARK
        this._gui.MarginX := 0
        this._gui.MarginY := 0

        ; Accent bar (left edge) — colored strip that changes per state
        this._accent := this._gui.Add("Progress", "x0 y0 w4 h" . h . " Background" . OSD.ACCENT_MUTED . " c" . OSD.ACCENT_MUTED, 100)

        ; Text label
        this._gui.SetFont("s" . fontSize . " cWhite w500", "Segoe UI")
        this._text := this._gui.Add("Text", "x12 y" . Round((h - fontSize * 1.6) / 2) . " w" . (w - 20) . " h" . h . " Center", "")

        ; Show hidden to apply region
        this._gui.Show("Hide w" . w . " h" . h)

        ; Rounded corners via region
        WinSetRegion("0-0 w" . w . " h" . h . " R" . r . "-" . r, this._gui)

        ; Near-opaque
        WinSetTransparent(245, this._gui)

        this._w := w
        this._h := h
        this._hideFn := this._HideCallback.Bind(this)
    }

    Enabled {
        get => this._enabled
        set => this._enabled := value
    }

    Show(message, isMuted := true, durationMs := 1500) {
        if !this._enabled
            return

        ; Update accent color and text color based on state
        accent := isMuted ? OSD.ACCENT_MUTED : OSD.ACCENT_UNMUTED
        this._accent.Opt("Background" . accent . " c" . accent)
        this._text.SetFont("c" . accent)

        ; Truncate long text
        if StrLen(message) > 18
            message := SubStr(message, 1, 18) . Chr(0x2026)
        this._text.Value := message

        ; Position bottom-center of primary monitor
        MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
        x := left + (right - left - this._w) // 2
        y := bottom - this._h - Round(74 * this._scale)

        this._gui.Show("x" . x . " y" . y . " w" . this._w . " h" . this._h . " NoActivate")

        ; Restart countdown
        SetTimer(this._hideFn, 0)
        SetTimer(this._hideFn, -durationMs)
    }

    _HideCallback() {
        this._gui.Hide()
    }
}
