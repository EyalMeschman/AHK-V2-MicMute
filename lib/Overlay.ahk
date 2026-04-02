#Requires AutoHotkey v2.0

class Overlay {
    static GDI_TOKEN := 0
    static PADDING := 5
    static CORNER_RADIUS := 5
    static BG_COLOR := 0xEF232323  ; ARGB: 94% opaque dark gray

    _gui := ""
    _hwnd := 0
    _hdc := 0
    _hbm := 0
    _oldBm := 0
    _graphics := 0
    _bgBrush := 0
    _mutedBitmap := 0
    _unmutedBitmap := 0
    _iconSize := 32
    _winSize := 0
    _visible := false
    _x := 0
    _y := 0

    __New(options := {}) {
        this._iconSize := HasProp(options, "size") ? options.size : 32
        this._winSize := this._iconSize + 2 * Overlay.PADDING

        ; Start GDI+
        this._InitGdip()

        ; Load icon bitmaps
        iconsDir := HasProp(options, "iconsDir") ? options.iconsDir : ""
        if iconsDir != "" {
            mutedFile := iconsDir . "\overlay_muted.ico"
            unmutedFile := iconsDir . "\overlay_unmuted.ico"
            if FileExist(mutedFile)
                this._mutedBitmap := this._LoadBitmap(mutedFile)
            if FileExist(unmutedFile)
                this._unmutedBitmap := this._LoadBitmap(unmutedFile)
        }

        ; Pick which monitor to display on (default: secondary, fallback: primary)
        monitorOpt := HasProp(options, "monitor") ? options.monitor : 0
        monitor := monitorOpt = 0 ? this._GetSecondaryMonitor() : monitorOpt
        MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
        this._x := right - this._winSize - 50
        this._y := top + 77

        ; Create GUI as a layered window
        this._gui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80000 +E0x20")
        this._gui.Show("x" . this._x . " y" . this._y . " w" . this._winSize . " h" . this._winSize . " NoActivate Hide")
        this._hwnd := this._gui.Hwnd

        ; Create drawing resources
        this._hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
        this._hbm := this._CreateDIB(this._winSize, this._winSize)
        this._oldBm := DllCall("SelectObject", "Ptr", this._hdc, "Ptr", this._hbm, "Ptr")
        this._graphics := this._GraphicsFromHDC(this._hdc)

        ; Set rendering quality
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", this._graphics, "Int", 4)
        DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", this._graphics, "Int", 7)

        ; Create background brush
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", Overlay.BG_COLOR, "Ptr*", &brush := 0)
        this._bgBrush := brush
    }

    Update(isMuted) {
        if isMuted {
            this._Draw(this._mutedBitmap)
            this.Show()
        } else {
            this.Hide()
        }
    }

    Show() {
        this._UpdateLayeredWindow()
        this._gui.Show("x" . this._x . " y" . this._y . " NoActivate")
        this._visible := true
    }

    Hide() {
        this._gui.Hide()
        this._visible := false
    }

    ToggleVisibility() {
        if this._visible
            this.Hide()
        else
            this.Show()
    }

    ; --- Private methods ---

    _Draw(bitmap) {
        ; Clear canvas to fully transparent
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", this._graphics, "UInt", 0x00000000)

        ; Draw icon centered
        if bitmap
            DllCall("gdiplus\GdipDrawImageRectI", "Ptr", this._graphics, "Ptr", bitmap
                , "Int", 0, "Int", 0
                , "Int", this._winSize, "Int", this._winSize)
    }

    _UpdateLayeredWindow() {
        pt := Buffer(8, 0)
        NumPut("Int", this._x, pt, 0)
        NumPut("Int", this._y, pt, 4)

        sz := Buffer(8, 0)
        NumPut("Int", this._winSize, sz, 0)
        NumPut("Int", this._winSize, sz, 4)

        ptSrc := Buffer(8, 0)

        bf := Buffer(4, 0)
        NumPut("UChar", 0, bf, 0)     ; BlendOp = AC_SRC_OVER
        NumPut("UChar", 0, bf, 1)     ; BlendFlags
        NumPut("UChar", 255, bf, 2)   ; SourceConstantAlpha
        NumPut("UChar", 1, bf, 3)     ; AlphaFormat = AC_SRC_ALPHA

        DllCall("UpdateLayeredWindow"
            , "Ptr", this._hwnd
            , "Ptr", 0
            , "Ptr", pt
            , "Ptr", sz
            , "Ptr", this._hdc
            , "Ptr", ptSrc
            , "UInt", 0
            , "Ptr", bf
            , "UInt", 2)  ; ULW_ALPHA
    }

    _GetSecondaryMonitor() {
        primary := MonitorGetPrimary()
        count := MonitorGetCount()
        loop count {
            if A_Index != primary
                return A_Index
        }
        return primary  ; fallback if only one monitor
    }

    _InitGdip() {
        if Overlay.GDI_TOKEN != 0
            return
        DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
        input := Buffer(24, 0)
        NumPut("UInt", 1, input, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &token := 0, "Ptr", input, "Ptr", 0)
        Overlay.GDI_TOKEN := token
    }

    _LoadBitmap(filePath) {
        DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", filePath, "Ptr*", &bitmap := 0)
        return bitmap
    }

    _GraphicsFromHDC(hdc) {
        DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &graphics := 0)
        return graphics
    }

    _CreateDIB(w, h) {
        hdr := Buffer(40, 0)
        NumPut("UInt", 40, hdr, 0)
        NumPut("Int", w, hdr, 4)
        NumPut("Int", -h, hdr, 8)      ; negative = top-down
        NumPut("UShort", 1, hdr, 12)
        NumPut("UShort", 32, hdr, 14)  ; 32-bit ARGB
        return DllCall("CreateDIBSection"
            , "Ptr", 0, "Ptr", hdr, "UInt", 0
            , "Ptr*", 0, "Ptr", 0, "UInt", 0, "Ptr")
    }

    _FillRoundedRect(graphics, brush, x, y, w, h, r) {
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &path := 0)
        d := r * 2.0
        fw := Float(w)
        fh := Float(h)
        fx := Float(x)
        fy := Float(y)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", fx, "Float", fy, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", fw - d, "Float", fy, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", fw - d, "Float", fh - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", fx, "Float", fh - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
        DllCall("gdiplus\GdipFillPath", "Ptr", graphics, "Ptr", brush, "Ptr", path)
        DllCall("gdiplus\GdipDeletePath", "Ptr", path)
    }

    __Delete() {
        if this._bgBrush
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", this._bgBrush)
        if this._mutedBitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", this._mutedBitmap)
        if this._unmutedBitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", this._unmutedBitmap)
        if this._graphics
            DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this._graphics)
        if this._oldBm
            DllCall("SelectObject", "Ptr", this._hdc, "Ptr", this._oldBm)
        if this._hbm
            DllCall("DeleteObject", "Ptr", this._hbm)
        if this._hdc
            DllCall("DeleteDC", "Ptr", this._hdc)
    }
}
