{
    --------------------------------------------
    Filename: display.lcd.st7735.spin
    Author: Jesse Burt
    Description: Driver for Sitronix ST7735-based displays
    Copyright (c) 2022
    Started Mar 7, 2020
    Updated Jan 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define MEMMV_NATIVE wordmove
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR           = 65535
    BYTESPERPX          = 2

' Display visibility modes
    NORMAL              = 0
    ALL_OFF             = 1
    INVERTED            = 2

' Operating modes
'   NORMAL              = 0
    IDLE                = 1
    PARTIAL             = 2

' Subpixel order
    RGB                 = 0
    BGR                 = 1

' Power control 5
    OFF                 = 0
    SMALL               = 1
    MEDLOW              = 2
    MED                 = 3
    MEDHI               = 4
    LARGE               = 5

    BCLK1_1             = 0
    BCLK1_2             = 1
    BCLK1_4             = 2
    BCLK2_2             = 3
    BCLK2_4             = 4
    BCLK4_4             = 5
    BCLK4_8             = 6
    BCLK4_16            = 7

    AUTO                = 0

    AVDD_X2_VGH25       = 0
    AVDD_X3             = 1
    AVDD_X3_VGH25       = 2

' Character attributes
    DRAWBG              = 1 << 0

VAR

    word _framerate
    byte _CS, _RESET, _DC

'   Shadow registers
    byte _colmod, _madctl, _opmode

OBJ

    spi : "com.spi.fast-nocs"                   ' SPI engine (no CS support)
    core: "core.con.st7735"                     ' HW-specific constants
    time: "time"                                ' basic timekeeping methods

PUB Null{}
'This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RESET_PIN, WIDTH, HEIGHT, ptr_drawbuff): status
' Start using custom I/O settings
'   NOTE: RES_PIN is optional, but recommended (pin # only validated in Reset())
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(SDA_PIN: 0..31) and lookdown(DC_PIN: 0..31)
        if (status := spi.init(SCK_PIN, SDA_PIN, -1, core#SPI_MODE))
            _RESET := RESET_PIN
            _DC := DC_PIN
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 1
            dira[_DC] := 1
            reset{}
            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            _buff_sz := (_disp_width * _disp_height) * BYTESPERPX
            _bytesperln := _disp_width * BYTESPERPX
#ifndef GFX_DIRECT
            address(ptr_drawbuff)
#endif
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    displayvisibility(ALL_OFF)
    powered(FALSE)
    spi.deinit{}

PUB Defaults{}
' Apply power-on-reset default settings
    reset{}
    powered(TRUE)

    frameratectrl(1, 44, 45, 0, 0, 0)
    frameratectrl(1, 44, 45, 0, 0, 0)
    frameratectrl(1, 44, 45, 1, 44, 45)

    inversionctrl(%011)

    powercontrol1(4_900, 4_600, -4_600, AUTO)
    powercontrol2(2_400, AVDD_X3, -10_000)
    powercontrol(NORMAL, MEDLOW, SMALL, 1, 1, 1, 1, 1)
    powercontrol(PARTIAL, MEDLOW, SMALL, 2, 4, 2, 1, 2)
    powercontrol(IDLE, MEDLOW, SMALL, 2, 2, 2, 2, 2)
    comvoltagelevel(-0_525)

    displayinverted(FALSE)

    mirrorh(FALSE)
    mirrorv(FALSE)
    subpixelorder(RGB)

    colordepth(16)
    displayoffset(2, 3)
    displaybounds(0, 0, 127, 127)

    gammatablep(@gammatable_pos)
    gammatablen(@gammatable_neg)

    partialarea(0, 161)                     ' Can be 0, 159 also, depending on configuration of GM pins
    opmode(NORMAL)
    displayvisibility(NORMAL)

PUB Preset_GreenTab128x128{}
' Like defaults, but with settings applicable to green-tabbed 128x128 displays
    reset{}
    powered(TRUE)

    frameratectrl(1, 44, 45, 0, 0, 0)
    frameratectrl(1, 44, 45, 0, 0, 0)
    frameratectrl(1, 44, 45, 1, 44, 45)

    inversionctrl(%011)

    powercontrol1(5_000, 4_600, -4_600, AUTO)
    powercontrol2(2_400, AVDD_X3, -10_000)
    powercontrol(NORMAL, MEDLOW, SMALL, 1, 1, 1, 1, 1)
    powercontrol(PARTIAL, MEDLOW, SMALL, 2, 2, 2, 1, 2)
    powercontrol(IDLE, MEDLOW, SMALL, 2, 4, 2, 4, 2)
    comvoltagelevel(-0_525)

    displayinverted(FALSE)

    mirrorh(TRUE)
    mirrorv(TRUE)
    subpixelorder(RGB)

    colordepth(16)
    displayoffset(2, 3)
    displaybounds(0, 0, _disp_xmax, _disp_ymax)

    gammatablep(@gammatable_pos)
    gammatablen(@gammatable_neg)

    partialarea(0, _disp_ymax)
    opmode(NORMAL)
    displayvisibility(NORMAL)

PUB Contrast(level)
' Dummy method

PUB Address(addr): curr_addr
' Set framebuffer/display buffer address
    case addr
        $0000..$7fff-_buff_sz:
            _ptr_drawbuffer := addr
        other:
            return _ptr_drawbuffer

#ifdef GFX_DIRECT
PUB Bitmap(ptr_bmap, xs, ys, bm_wid, bm_lns) | offs, nr_pix
' Display bitmap
'   ptr_bmap: pointer to bitmap data
'   (xs, ys): upper-left corner of bitmap
'   bm_wid: width of bitmap, in pixels
'   bm_lns: number of lines in bitmap
    displaybounds(xs, ys, xs+(bm_wid-1), ys+(bm_lns-1))
    outa[_CS] := 0
    outa[_DC] := core#CMD
    spi.wr_byte(core#RAMWR)

    ' calc total number of pixels to write, based on dims and color depth
    ' clamp to a minimum of 1 to avoid odd behavior
    nr_pix := 1 #> ((xs + bm_wid-1) * (ys + bm_lns-1) * BYTESPERPX)

    outa[_DC] := core#DATA
    spi.wrblock_lsbf(ptr_bmap, nr_pix)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB Box(x1, y1, x2, y2, color, fill) | cmd_pkt[3]
' Draw a box
'   (x1, y1): upper-left corner of box
'   (x2, y2): lower-right corner of box
'   color: border and (optional) fill color
'   fill: filled flag (0: no fill, nonzero: fill)
    if (x2 < x1) or (y2 < y1)
        return
    if fill
        ' filled box: set the display's draw boundaries to the size of
        ' the box, and send enough data to draw H * W pixels
        cmd_pkt.byte[0] := core#CASET           ' D/C L
        cmd_pkt.byte[1] := x1.byte[1]           ' D/C H
        cmd_pkt.byte[2] := x1.byte[0]
        cmd_pkt.byte[3] := x2.byte[1]
        cmd_pkt.byte[4] := x2.byte[0]
        cmd_pkt.byte[5] := core#RASET           ' D/C L
        cmd_pkt.byte[6] := y1.byte[1]           ' D/C H
        cmd_pkt.byte[7] := y1.byte[0]
        cmd_pkt.byte[8] := y2.byte[1]
        cmd_pkt.byte[9] := y2.byte[0]

        outa[_DC] := core#CMD
        outa[_CS] := 0
        spi.wr_byte(cmd_pkt.byte[0])            ' column cmd
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[1], 4)   ' x1, x2

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[5])            ' row cmd
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[6], 4)   ' y1, y2

        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, ((y2-y1)+1) * ((x2-x1)+1))
        outa[_CS] := 1
    else
        ' no-fill box: set the display's draw boundaries to just the
        ' 1-pixel wide/tall segment, and send enough data to draw it
        displaybounds(x1, y1, x2, y1)           ' top
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (x2-x1)+1)

        displaybounds(x1, y2, y2, y2)           ' bottom
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (x2-x1)+1)

        displaybounds(x1, y1, x1, y2)           ' left
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (y2-y1)+1)

        displaybounds(x2, y1, x2, y2)           ' right
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (y2-y1)+1)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB Char(ch) | gl_c, gl_r, lastgl_c, lastgl_r
' Draw character from currently loaded font
    lastgl_c := _font_width-1
    lastgl_r := _font_height-1
    case ch
        CR:
            _charpx_x := 0
        LF:
            _charpx_y += _charcell_h
            if _charpx_y > _charpx_xmax
                _charpx_y := 0
        0..127:                                 ' validate ASCII code
            ' walk through font glyph data
            repeat gl_c from 0 to lastgl_c      ' column
                repeat gl_r from 0 to lastgl_r  ' row
                    ' if the current offset in the glyph is a set bit, draw it
                    if byte[_font_addr][(ch << 3) + gl_c] & (|< gl_r)
                        plot((_charpx_x + gl_c), (_charpx_y + gl_r), _fgcolor)
                    else
                    ' otherwise, draw the background color, if enabled
                        if _char_attrs & DRAWBG
                            plot((_charpx_x + gl_c), (_charpx_y + gl_r), _bgcolor)
            ' move the cursor to the next column, wrapping around to the left,
            ' and wrap around to the top of the display if the bottom is reached
            _charpx_x += _charcell_w
            if _charpx_x > _charpx_xmax
                _charpx_x := 0
                _charpx_y += _charcell_h
            if _charpx_y > _charpx_ymax
                _charpx_y := 0
        other:
            return
#endif

PUB CharAttrs(attrs)
' Set character attributes
    _char_attrs := attrs

#ifdef GFX_DIRECT
PUB Clear{}
' Clear the display directly, bypassing the display buffer
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    outa[_DC] := core#CMD
    outa[_CS] := 0
    spi.wr_byte(core#RAMWR)
    outa[_DC] := core#DATA
    spi.wrwordx_msbf(_bgcolor, _buff_sz/2)
    outa[_CS] := 1
#else
PUB Clear{}
' Clear the display buffer
    wordfill(_ptr_drawbuffer, _bgcolor, _buff_sz/2)
#endif

PUB ColorDepth(format): curr_fmt
' Set expected color format of pixel data, in bits per pixel
'   Valid values: 12, 16, 18
'   Any other value returns the current setting
    case format
        12, 16, 18:
            format := lookdown(format: 0, 0, 12, 0, 16, 18)
            writereg(core#COLMOD, 1, @format)
        other:
            return lookup(_colmod & core#IFPF_BITS: 0, 0, 12, 0, 16, 18)

PUB COMVoltageLevel(level)
' Set VCOM voltage level, in millivolts
'   Valid values:
'       -0_425..-2_000 (in increments of 25mV)   Default: -0_525
'   NOTE: Values are rounded to the nearest 25mV
    case level
        -0_425..-2_000:
            level := (-level / 25) - 17
            writereg(core#VMCTR1, 1, @level)
        other:
            return

PUB DisplayBounds(sx, sy, ex, ey) | tmp, tmpx, tmpy, cmd_pkt[3]
' Set display start (sx, sy) and end (ex, ey) drawing boundaries
    if (sx => 0 and ex =< _disp_xmax) and (sy => 0 and ey =< _disp_ymax)
        ' the ST7735 requires (ex, ey) be greater than (sx, sy)
        ' if they're not, swap them
        sx += _offs_x
        sy += _offs_y
        ex += _offs_x
        ey += _offs_y
        if ex < sx                              ' ex is less than sx?
            tmp := sx                           '   swap them
            sx := ex
            ex := tmp
        if ey < sy                              ' ey is less than sy?
            tmp := sy                           '   swap them
            sy := ey
            ey := tmp
        tmpx.byte[0] := sx.byte[1]
        tmpx.byte[1] := sx.byte[0]
        tmpx.byte[2] := ex.byte[1]
        tmpx.byte[3] := ex.byte[0]
        tmpy.byte[0] := sy.byte[1]
        tmpy.byte[1] := sy.byte[0]
        tmpy.byte[2] := ey.byte[1]
        tmpy.byte[3] := ey.byte[0]

        writereg(core#CASET, 4, @tmpx)
        writereg(core#RASET, 4, @tmpy)

PUB DisplayInverted(state)
' Invert display colors
    case ||(state)
        0:
            displayvisibility(NORMAL)
        1:
            displayvisibility(INVERTED)
        other:
            return

PUB DisplayOffset(x, y)
' Set display offset
    _offs_x := 0 #> x <# 127
    _offs_y := 0 #> y <# 159

PUB DisplayRotate(state): curr_state
' Rotate display
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := ||(state) << core#MV
        other:
            return (((curr_state >> core#MV) & 1) == 1)

    _madctl := ((curr_state & core#MV_MASK) | state)
    writereg(core#MADCTL, 1, @_madctl)

PUB DisplayVisibility(mode) | inv_state
' Set display visiblity
'   NOTE: Doesn't affect display RAM contents.
'   NOTE: There is a mandatory 120ms delay imposed by calling this method
    case mode
        ALL_OFF:
            mode := core#DISPOFF
        NORMAL:
            mode := core#DISPON
            inv_state := core#INVOFF
        INVERTED:
            mode := core#DISPON
            inv_state := core#INVON
        other:
            return

    writereg(mode, 0, 0)
    writereg(inv_state, 0, 0)
    time.msleep(120)

PUB FrameRateCtrl(ln_per, f_porch, b_porch, lim_ln_per, lim_f_porch, lim_b_porch): curr_frmr | tmp[2], nr_bytes
' Set frame frequency
'   Valid values:
'       ln_per: 0..15
'       f_porch: 0..63
'       b_porch: 0..63
'       lim_* variants (effective when in Line Inversion Mode - set only in OpMode(PARTIAL)) - same as above
'           - ignored when opmode is 1 or 2
'   Any other value for opmode returns the last calculated frame frequency
'   Any other values for other parameters are ignored
    result := 0
    case _opmode
        NORMAL, IDLE:
            nr_bytes := 3
        PARTIAL:
            nr_bytes := 6
        other:
            return _framerate

    case ln_per
        0..15:
            tmp.byte[0] := ln_per
        other:
            return

    case f_porch
        0..63:
            tmp.byte[1] := f_porch
        other:
            return

    case b_porch
        0..63:
            tmp.byte[2] := b_porch
        other:
            return

    if _opmode == PARTIAL
        case lim_ln_per
            0..15:
                tmp.byte[3] := lim_ln_per
            other:
                return

        case lim_f_porch
            0..63:
                tmp.byte[4] := lim_f_porch
            other:
                return

        case lim_b_porch
            0..63:
                tmp.byte[5] := lim_b_porch
            other:
                return

    curr_frmr := _framerate := core#FOSC / ((ln_per * 2 + 40) * {
}   (_disp_height + f_porch + b_porch))

    writereg(core#FRMCTR1 + _opmode, nr_bytes, @tmp)

PUB GammaTableN(ptr_buff)
' Modify gamma table (negative polarity)
    writereg(core#GMCTRN1, 16, ptr_buff)

PUB GammaTableP(ptr_buff)
' Modify gamma table (positive polarity)
    writereg(core#GMCTRP1, 16, ptr_buff)

PUB InversionCtrl(mask)
' Set display inversion mode control bitmask
'   Valid values: %000..%111
'       0: Dot inversion
'       1: Line inversion
'       Bits 321:
'           3 - Inversion setting in OpMode(NORMAL) (default: 0)
'           2 - Inversion setting in OpMode(IDLE) (default: 1)
'           1 - Inversion setting in OpMode(PARTIAL) (default: 1)
'   Any other value is ignored
    case mask
        %000..%111:
        other:
            return

    writereg(core#INVCTR, 1, @mask)

#ifdef GFX_DIRECT
PUB Line(x1, y1, x2, y2, color) | sx, sy, ddx, ddy, err, e2
' Draw line from x1, y1 to x2, y2
    if (x1 == x2)
        displaybounds(x1, y1, x1, y2)           ' vertical
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (||(y2-y1))+1)
        outa[_CS] := 1
        return
    if (y1 == y2)
        displaybounds(x1, y1, x2, y1)           ' horizontal
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#RAMWR)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(color, (||(x2-x1))+1)
        outa[_CS] := 1
        return

    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := ddx-ddy

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    repeat until ((x1 == x2) and (y1 == y2))
        plot(x1, y1, color)
        e2 := err << 1

        if e2 > -ddy
            err -= ddy
            x1 += sx

        if e2 < ddx
            err += ddx
            y1 += sy
#endif

PUB MirrorH(state): curr_state
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := ||(state) << core#MX
        other:
            return (((curr_state >> core#MX) & 1) == 1)

    _madctl := ((_madctl & core#MX_MASK) | state)
    writereg(core#MADCTL, 1, @_madctl)

PUB MirrorV(state): curr_state
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := ||(state) << core#MY
        other:
            return (((curr_state >> core#MY) & 1) == 1)

    _madctl := ((_madctl & core#MY_MASK) | state)
    writereg(core#MADCTL, 1, @_madctl)

PUB OpMode(mode)
' Set operating mode
'   Valid values:
'       NORMAL (0): Normal display mode
'       PARTIAL (1): Partial display mode
'       IDLE (2): Idle/reduced color (8 color) mode
'   Any other value is ignored
    case mode
        NORMAL:
            writereg(core#IDMOFF, 0, 0)
            writereg(core#NORON, 0, 0)
        PARTIAL:
            writereg(core#PTLON, 0, 0)
        IDLE:
            writereg(core#IDMON, 0, 0)
        other:
            return

    _opmode := mode

PUB PartialArea(sy, ey) | tmp
' Define visible area (rows) of display when operating in partial-display mode
    tmp.byte[0] := 0
    tmp.byte[1] := sy & $FF
    tmp.byte[2] := 0
    tmp.byte[3] := ey & $FF

    writereg(core#PTLAR, 4, @tmp)

#ifdef GFX_DIRECT
PUB Plot(x, y, color) | tmp, xs, ys, xe, ye, cmd_pkt[3]
' Draw a pixel at x, y (direct to display)
    if (x => 0 and x =< _disp_xmax) and (y => 0 and y =< _disp_ymax)
        cmd_pkt.byte[0] := core#CASET           ' D/C L
        cmd_pkt.byte[1] := x+_offs_x            ' D/C H
        cmd_pkt.byte[2] := x+_offs_x
        cmd_pkt.byte[3] := core#RASET           ' D/C L
        cmd_pkt.byte[4] := y+_offs_y            ' D/C H
        cmd_pkt.byte[5] := y+_offs_y
        cmd_pkt.byte[6] := core#RAMWR           ' D/C L
        cmd_pkt.byte[7] := color.byte[1]        ' D/C H
        cmd_pkt.byte[8] := color.byte[0]
        outa[_DC] := core#CMD
        outa[_CS] := 0
        spi.wr_byte(cmd_pkt.byte[0])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[1], 2)

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[3])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[4], 2)

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[6])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[7], 2)
        outa[_CS] := 1

#else

PUB Plot(x, y, color)
' Draw a pixel at (x, y) in color (buffered)
    word[_ptr_drawbuffer][x + (y * _disp_width)] := color
#endif

#ifndef GFX_DIRECT
PUB Point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return word[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB Powered(state)
' Enable display power
    case ||(state)
        0, 1:
            state := ||(state) + core#SLPIN
        other:
            return

    writereg(state, 0, 0)
    time.msleep(120)

PUB PowerControl(mode, ap, sap, bclkdiv1, bclkdiv2, bclkdiv3, bclkdiv4, bclkdiv5) | tmp
' Set partial mode/full-colors power control
'   Valid values:
'       mode: Settings applied to operating mode
'           0: Normal mode/full color
'           1: Idle mode/8-color
'           2: Partial mode/full color
'       ap, sap: Set opamp current
'           OFF (0): Disabled
'           SMALL (1), MEDLOW (2), MED (3), MEDHI (4), LARGE (5)
'       boost_clkdiv: Set booster circuit clock frequency divisor
'           Setting     Booster circuit 1
'           1:          BCLK / 1
'           1_5:        BCLK / 1.5
'           2:          BCLK / 2
'           4:          BCLK / 4
    case mode
        0..2:
        other:
            return

    case ap
        OFF, SMALL, MEDLOW, MED, MEDHI, LARGE:
        other:
            return

    case sap
        OFF, SMALL, MEDLOW, MED, MEDHI, LARGE:
            sap <<= core#SAP
        other:
            return

    case bclkdiv1
        1, 1_5, 2, 4:
            bclkdiv1 := lookdownz(bclkdiv1: 1, 1_5, 2, 4)
        other:
            return

    case bclkdiv2
        1, 1_5, 2, 4:
            bclkdiv2 := lookdownz(bclkdiv2: 1, 1_5, 2, 4)
        other:
            return

    case bclkdiv3
        1, 1_5, 2, 4:
            bclkdiv3 := lookdownz(bclkdiv3: 1, 1_5, 2, 4)
        other:
            return

    case bclkdiv4
        1, 1_5, 2, 4:
            bclkdiv4 := lookdownz(bclkdiv4: 1, 1_5, 2, 4)
        other:
            return

    case bclkdiv5
        1, 1_5, 2, 4:
            bclkdiv5 := lookdownz(bclkdiv5: 1, 1_5, 2, 4)
        other:
            return

    tmp.byte[0] := ap | sap | (bclkdiv5 << core#DCMSB)
    tmp.byte[1] := (bclkdiv4 << 6) | (bclkdiv3 << 4) | (bclkdiv2 << 2) | bclkdiv1
    writereg(core#PWCTR3 + mode, 2, @tmp)

PUB PowerControl1(avdd, gvdd, gvcl, mode) | tmp
' Set LCD supply voltages, in millivolts
'   Valid values:
'       avdd: 4_500..5_100, in increments of 100 (default: 4_900)
'       gvdd: 3_150..4_700, in increments of 50 (default: 4_600)
'       gvcl: -4_700..-3_150, in increments of 50 (default: -4_600)
'       mode: 2, 3, AUTO (0) (default: AUTO)
'   Any other value is ignored

    case avdd
        4_500..5_100:
            avdd := ((avdd / 100) - 45) << core#AVDD
        other:
            return

    case gvdd
        3_150..4_700:
            gvdd := ((4_700 - gvdd) / 50) & core#VRHP_BITS
        other:
            return

    case gvcl
        -4_700..-3_150:
            gvcl := ((4_700 - (-gvcl)) / 50) & core#VRHN_BITS
        other:
            return

    case mode
        2, 3, AUTO:
            mode := lookdownz(mode: 2, 3, AUTO) << core#MODE
            mode |= %000100

    tmp.byte[0] := avdd | gvdd
    tmp.byte[1] := gvcl
    tmp.byte[2] := mode

    writereg(core#PWCTR1, 3, @tmp)

PUB PowerControl2(v25, vgh, vgl) | tmp
' Set LCD supply voltages, in millivolts
'   Valid values:
'       V25: 2_100, 2_200, 2_300, 2_400 (default: 2_400)
'       VGH: AVDD_X2_VGH25 (0), AVDD_X3 (1), AVDD_X3_VGH25 (2) (default: AVDD_X3)
'       VGL: -13_000, -12_500, -10_000, -7_500 (default: -10_000)
    case v25
        2_100, 2_200, 2_300, 2_400:
            v25 := lookdownz(v25: 2_100, 2_200, 2_300, 2_400) << core#VGH25
        other:
            return

    case vgh
        AVDD_X2_VGH25, AVDD_X3, AVDD_X3_VGH25:
            vgh := lookdownz(vgh: AVDD_X2_VGH25, AVDD_X3, AVDD_X3_VGH25) & core#VGHBT_BITS
        other:
            return

    case vgl
        -13_000, -12_500, -10_000, -7_500:
            vgl := lookdownz(vgl: -7_500, -10_000, -12_500, -13_000) << core#VGLSEL
        other:
            return

    tmp := v25 | vgh | vgl

    writereg(core#PWCTR2, 1, @tmp)

PUB Reset{}
' Reset the display controller
    outa[_RESET] := 1
    dira[_RESET] := 1
    if lookdown(_RESET: 0..31)                  ' I/O pin defined - hard reset
        outa[_RESET] := 1
        time.usleep(10)
        outa[_RESET] := 0
        time.usleep(10)
        outa[_RESET] := 1
        time.msleep(5)
    else                                        ' no I/O pin defined - do
        writereg(core#SOFT_RESET, 0, 0)         '   soft reset instead

PUB SubpixelOrder(order): curr_ord
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    curr_ord := _madctl
    case order
        0, 1:
            order <<= core#RGB
        other:
            return ((curr_ord >> core#RGB) & 1)

    _madctl := ((curr_ord & core#RGB_MASK) | order)
    writereg(core#MADCTL, 1, @_madctl)

PUB Update{}
' Write the draw buffer to the display
#ifndef GFX_DIRECT
    outa[_DC] := core#CMD
    outa[_CS] := 0
    spi.wr_byte(core#RAMWR)
    outa[_DC] := core#DATA                      ' D/C high = data
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)
    outa[_CS] := 1
#endif

#ifndef GFX_DIRECT
PRI memFill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    wordfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), val, count)
#endif

PRI writeReg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to device from ptr_buff
    case reg_nr
        ' single-byte commands
        $00, $01, $11, $12, $13, $20, $21, $28, $29, $38, $39:
            outa[_DC] := core#CMD               ' D/C low = command
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_CS] := 1
            return
        ' multi-byte commands
        $2A..$2C, $30, $36, $3A, $B1..$B4, $B6, $C0..$C5, $E0, $E1, $FC:
            outa[_DC] := core#CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_DC] := core#DATA
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return

DAT

    gammatable_neg  byte    $02, $1C, $07, $12
                    byte    $37, $32, $29, $2D
                    byte    $29, $25, $2B, $39
                    byte    $00, $01, $03, $10

    gammatable_pos  byte    $03, $1D, $07, $06
                    byte    $2E, $2C, $29, $2D
                    byte    $2E, $2E, $37, $3F
                    byte    $00, $00, $02, $10

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}