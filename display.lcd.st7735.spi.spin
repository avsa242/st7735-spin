{
    --------------------------------------------
    Filename: display.lcd.st7735.spi.spin
    Author: Jesse Burt
    Description: Driver for Sitronix ST7735-based displays (4W SPI)
    Copyright (c) 2021
    Started Mar 07, 2020
    Updated Jan 10, 2021
    See end of file for terms of use.
    --------------------------------------------
}
#define ST7735
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

VAR

    long _ptr_drawbuffer
    word _buff_sz
    word _framerate
    word BYTESPERLN
    byte _RESET, _DC
    byte _disp_width, _disp_height, _disp_xmax, _disp_ymax, _offs_x, _offs_y

'   Shadow registers
    byte _colmod, _madctl, _opmode

OBJ

    spi : "com.spi.fast"
    core: "core.con.st7735"
    time: "time"
    io  : "io"

PUB Null{}
'This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RESET_PIN, disp_width, disp_height, ptr_drawbuff): okay

    if okay := spi.start(CS_PIN, SCK_PIN, SDA_PIN, SDA_PIN)
        _RESET := RESET_PIN
        _DC := DC_PIN

        io.high(_RESET)
        io.output(_RESET)
        io.high(_DC)
        io.output(_DC)

        _disp_width := disp_width
        _disp_height := disp_height
        _disp_xmax := _disp_width-1
        _disp_ymax := _disp_height-1
        BYTESPERLN := _disp_width * BYTESPERPX
        _buff_sz := (_disp_width * _disp_height) * BYTESPERPX
        reset{}
        address(ptr_drawbuff)
        return okay
    return                                                'If we got here, something went wrong

PUB Stop{}

    powered(FALSE)
    spi.stop{}

PUB Defaults{} | tmp
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

PUB Preset_GreenTab128x128{} | tmp
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
    subpixelorder(BGR)

    colordepth(16)
    displayoffset(2, 3)
    displaybounds(0, 0, _disp_xmax, _disp_ymax)

    gammatablep(@gammatable_pos)
    gammatablen(@gammatable_neg)

    partialarea(0, _disp_ymax)                     ' Can be 0, 159 also, depending on configuration of GM pins
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

PUB ClearAccel{} | x, y   ' XXX replace hardcoded values
' Dummy method
    displaybounds(_offs_x, _offs_y, _disp_xmax+_offs_x, _disp_ymax+_offs_y)
    repeat y from 0 to _disp_ymax
        repeat x from 0 to _disp_xmax
            writereg(core#RAMWR, 2, @_bgcolor)
'            plot(x, y, _bgcolor)

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
            level := ((level * -1) / 25) - 17
            writereg(core#VMCTR1, 1, @level)
        other:
            return

PUB DisplayBounds(xs, ys, xe, ye) | tmp
' Set display start and end offsets
    xs += _offs_x
    ys += _offs_y
    xe += _offs_x
    ye += _offs_y
    tmp.byte[0] := xs.byte[1]
    tmp.byte[1] := xs.byte[0]
    tmp.byte[2] := xe.byte[1]
    tmp.byte[3] := xe.byte[0]
    writereg(core#CASET, 4, @tmp)

    tmp.byte[0] := ys.byte[1]
    tmp.byte[1] := ys.byte[0]
    tmp.byte[2] := ye.byte[1]
    tmp.byte[3] := ye.byte[0]
    writereg(core#RASET, 4, @tmp)

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
' Modify gamma table (negative polarity)
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
PUB Plot(x, y, color)

    displaybounds(x+_offs+x, y+_offs_y, x+_offs_x, y+_offs_y)
    writereg(core#RAMWR, 2, @color)

#endif GFX_DIRECT

PUB Powered(state)
' Enable display power
    case ||(state)
        0, 1:
            state := ||(state) + core#SLPIN
        other:
            return

    writereg(state, 0, 0)
    time.msleep(120)

PUB Reset{}
' Reset the display controller
    io.high(_RESET)
    time.usleep(10)
    io.low(_RESET)
    time.usleep(10)
    io.high(_RESET)
    time.msleep(5)

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
            avdd := ((avdd / 100) - 45) << core#avdd
        other:
            return

    case gvdd
        3_150..4_700:
            gvdd := ((4_700 - gvdd) / 50) & core#VRHP_BITS
        other:
            return

    case gvcl
        -4_700..-3_150:
            gvcl := ((4_700 - (gvcl * -1) ) / 50) & core#VRHN_BITS
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
'       VGH: AVDD_X2_VGH25 (0), AVDD_X3 (1), AVDD_X3_VGH25 (2) (default: AVDD3X)
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
    writereg(core#RAMWR, _buff_sz, _ptr_drawbuffer)

PRI writeReg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to device from ptr_buff
    case reg_nr
        ' single-byte commands
        $00, $01, $11, $12, $13, $20, $21, $28, $29, $38, $39:
            io.low(_DC)                         ' D/C low = command
            spi.write(TRUE, @reg_nr, 1, TRUE)   ' Write reg_nr, raise CS after
            return
        core#RAMWR:
            io.low(_DC)
            spi.write(TRUE, @reg_nr, 1, FALSE)  ' leave CS low after
            io.high(_DC)                        ' D/C high = data
            spi.write(TRUE, ptr_buff, nr_bytes, TRUE)
            return
        ' multi-byte commands
        $2A..$2C, $30, $36, $3A, $B1..$B4, $B6, $C0..$C5, $E0, $E1, $FC:
            io.low(_DC)
            spi.write(TRUE, @reg_nr, 1, FALSE)
            io.high(_DC)
            spi.write(TRUE, ptr_buff, nr_bytes, TRUE)
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
