{
    --------------------------------------------
    Filename: display.lcd.st7735.spi.spin
    Author: Jesse Burt
    Description: Driver for Sitronix ST7735-based displays (4W SPI)
    Copyright (c) 2020
    Started Mar 07, 2020
    Updated Mar 10, 2020
    See end of file for terms of use.
    --------------------------------------------
}
#define ST7735
#include "lib.gfx.bitmap.spin"

CON

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

    long _ptr_framebuffer
    word _buff_sz
    word _framerate
    byte _SDA, _SCK, _RESET, _DC
    byte _disp_width, _disp_height, _disp_xmax, _disp_ymax
'   Shadow registers
    byte _colmod, _madctl, _opmode

OBJ

    spi : "com.spi.fast"
    core: "core.con.st7735"
    time: "time"
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RESET_PIN, disp_width, disp_height, drawbuffer_address): okay

    if okay := spi.Start(CS_PIN, SCK_PIN, SDA_PIN, SDA_PIN)
        _SDA := SDA_PIN
        _SCK := SCK_PIN
        _RESET := RESET_PIN
        _DC := DC_PIN

        io.High(_RESET)
        io.Output(_RESET)
        io.High(_DC)
        io.Output(_DC)

        _disp_width := disp_width
        _disp_height := disp_height
        _disp_xmax := _disp_width-1
        _disp_ymax := _disp_height-1
        _buff_sz := (_disp_width * _disp_height) * 2
        Reset
        Address(drawbuffer_address)
        return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    Powered(FALSE)
    spi.Stop

PUB Defaults | tmp
' Apply power-on-reset default settings
    writeReg(core#SOFT_RESET, 0, 0)
    time.MSleep(150)

    Powered(TRUE)

    FramerateCtrl(1, 44, 45, 0, 0, 0)
    FramerateCtrl(1, 44, 45, 0, 0, 0)
    FramerateCtrl(1, 44, 45, 1, 44, 45)

    tmp := $03
    writeReg(core#INVCTR, 1, @tmp)

    PowerControl1(4_900, 4_600, -4_600, AUTO)
    PowerControl2(2_400, AVDD_X3, -10_000)
    PowerControl(3, $0A, $00)
    PowerControl(4, $8A, $2A)
    PowerControl(5, $8A, $EE)

    COMVoltageLevel(-0_525)
    DisplayInverted(FALSE)

    MirrorH(TRUE)
    MirrorV(TRUE)
    SubpixelOrder(BGR)

    ColorDepth(16)
    DisplayBounds(2, 3, 129, 130)

    GammaTableP(@gammatable_pos)
    GammaTableN(@gammatable_neg)

    PartialArea(0, 161)                     ' Can be 0, 159 also, depending on configuration of GM pins
    OpMode(NORMAL)
    DisplayVisibility(NORMAL)

PUB DefaultsCommon | tmp

    writeReg(core#SOFT_RESET, 0, 0)
    time.MSleep(150)

    Powered(TRUE)

    FramerateCtrl(1, 44, 45, 0, 0, 0)
    FramerateCtrl(1, 44, 45, 0, 0, 0)
    FramerateCtrl(1, 44, 45, 1, 44, 45)

    tmp := $07
    writeReg(core#INVCTR, 1, @tmp)

    PowerControl1(5_000, 4_600, -4_600, AUTO)
    PowerControl2(2_400, AVDD_X3, -10_000)
    PowerControl(3, $0A, $00)
    PowerControl(4, $8A, $2A)
    PowerControl(5, $8A, $EE)

    COMVoltageLevel(-0_525)
    DisplayInverted(FALSE)

    MirrorH(TRUE)
    MirrorV(TRUE)
    SubpixelOrder(BGR)

    ColorDepth(16)
    DisplayBounds(2, 3, 129, 130)

    GammaTableP(@gammatable_pos)
    GammaTableN(@gammatable_neg)

    PartialArea(0, 161)                     ' Can be 0, 159 also, depending on configuration of GM pins
    OpMode(NORMAL)
    DisplayVisibility(NORMAL)

PUB Contrast(level)
' Dummy method

PUB Address(addr)
' Set framebuffer/display buffer address
    _ptr_framebuffer := addr

PUB ClearAccel
' Dummy method
    return 0

PUB ColorDepth(format) | tmp
' Set expected color format of pixel data, in bits per pixel
'   Valid values: 12, 16, 18
'   Any other value returns the current setting
    tmp := $00
    case format
        12, 16, 18:
            format := lookdown(format: 0, 0, 12, 0, 16, 18)
        OTHER:
            return _colmod & core#BITS_IFPF

    writeReg(core#COLMOD, 1, @format)

PUB COMVoltageLevel(mV)
' Set VCOM voltage level, in millivolts
'   Valid values:
'       -0_425..-2_000 (in increments of 25mV)   Default: -0_525
'   NOTE: Values are rounded to the nearest 25mV
    case mV
        -0_425..-2_000:
            mV := ((mV * -1) / 25) - 17
        OTHER:
            return FALSE

    writeReg(core#VMCTR1, 1, @mV)

PUB DisplayBounds(xs, ys, xe, ye) | tmp
' Set display start and end offsets
' XXX
' These definitions are in Adafruit's driver for the green tabbed 1.44" display,
'   but they didn't quite work for me - the display was shifted up and to the left,
'   leaving garbage around the right edge:
'   tmp.byte[0] := $00
'   tmp.byte[0] := $00
'   tmp.byte[0] := $00
'   tmp.byte[0] := $7F

'   tmp.byte[0] := $00
'   tmp.byte[0] := $00
'   tmp.byte[0] := $00
'   tmp.byte[0] := $7F

    tmp.byte[0] := xs.byte[1]
    tmp.byte[1] := xs.byte[0]
    tmp.byte[2] := xe.byte[1]
    tmp.byte[3] := xe.byte[0]
    writeReg(core#CASET, 4, @tmp)

    tmp.byte[0] := ys.byte[1]
    tmp.byte[1] := ys.byte[0]
    tmp.byte[2] := ye.byte[1]
    tmp.byte[3] := ye.byte[0]
    writeReg(core#RASET, 4, @tmp)

PUB DisplayInverted(enabled) | tmp
' Invert display colors
    case ||enabled
        0:
            DisplayVisibility(NORMAL)
        1:
            DisplayVisibility(INVERTED)
        OTHER:
            return FALSE

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

        OTHER:
            return FALSE

    writeReg(mode, 0, 0)
    writeReg(inv_state, 0, 0)
    time.MSleep(120)

PUB FrameRateCtrl(line_period, f_porch, b_porch, lim_line_period, lim_f_porch, lim_b_porch) | tmp[2], nr_bytes
' Set frame frequency
'   Valid values:
'       line_period: 0..15
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
        OTHER:
            return _framerate

    case line_period
        0..15:
            tmp.byte[0] := line_period
        OTHER:
            return

    case f_porch
        0..63:
            tmp.byte[1] := f_porch
        OTHER:
            return

    case b_porch
        0..63:
            tmp.byte[2] := b_porch
        OTHER:
            return

    if _opmode == PARTIAL
        case lim_line_period
            0..15:
                tmp.byte[3] := lim_line_period
            OTHER:
                return

        case lim_f_porch
            0..63:
                tmp.byte[4] := lim_f_porch
            OTHER:
                return

        case lim_b_porch
            0..63:
                tmp.byte[5] := lim_b_porch
            OTHER:
                return

    result := _framerate := core#FOSC / ((line_period * 2 + 40) * (_disp_height + f_porch + b_porch))

    writeReg(core#FRMCTR1 + _opmode, nr_bytes, @tmp)

PUB GammaTableN(buff_addr)
' Modify gamma table (negative polarity)
    writeReg(core#GMCTRN1, 16, buff_addr)

PUB GammaTableP(buff_addr)
' Modify gamma table (negative polarity)
    writeReg(core#GMCTRP1, 16, buff_addr)

PUB MirrorH(enabled) | tmp
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    tmp := $00
    tmp := _madctl
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_MX
        OTHER:
            result := (tmp >> core#FLD_MX) & %1
            return

    _madctl &= core#MASK_MX
    _madctl := (_madctl | enabled) & core#MADCTL_MASK
    writeReg(core#MADCTL, 1, @_madctl)

PUB MirrorV(enabled) | tmp
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    tmp := $00
    tmp := _madctl
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_MY
        OTHER:
            result := (tmp >> core#FLD_MY) & %1
            return

    _madctl &= core#MASK_MY
    _madctl := (_madctl | enabled) & core#MADCTL_MASK
    writeReg(core#MADCTL, 1, @_madctl)

PUB OpMode(mode) | tmp
' Set operating mode
'   Valid values:
'       NORMAL (0): Normal display mode
'       PARTIAL (1): Partial display mode
'       IDLE (2): Idle/reduced color (8 color) mode
'   Any other value is ignored
    case mode
        NORMAL:
            writeReg(core#IDMOFF, 0, 0)
            writeReg(core#NORON, 0, 0)
        PARTIAL:
            writeReg(core#PTLON, 0, 0)
        IDLE:
            writeReg(core#IDMON, 0, 0)
        OTHER:
            return FALSE

    _opmode := mode                                         ' Update VAR used by some methods
                                                            '   to read current state

PUB PartialArea(sy, ey) | tmp
' Define visible area (rows) of display when operting in partial-display mode
    tmp.byte[0] := $00
    tmp.byte[1] := sy & $FF
    tmp.byte[2] := $00
    tmp.byte[3] := ey & $FF

    writeReg(core#PTLAR, 4, @tmp)

PUB Powered(enabled) | tmp
' Enable display power
    case ||enabled
        0, 1:
            enabled := ||enabled + core#SLPIN
        OTHER:
            return FALSE

    writeReg(enabled, 0, 0)
    time.MSleep(120)

PUB Reset
' Reset the display controller
    io.Low(_RESET)
    time.USleep(10)
    io.High(_RESET)
    time.MSleep(5)

PUB PowerControl(mode, Isource, boost_clkdiv) | tmp
' Set partial mode/full-colors power control    XXX rewrite - currently allows any params after opmode
'   Valid values:
'       mode: Settings applied to operating mode
'           3: Normal mode/full color
'           4: Idle mode/8-color
'           5: Partial mode/full color
'       Isource: Set opamp current
'           OFF (0): Disabled
'           SMALL (1), MEDLOW (2), MED (3), MEDHI (4), LARGE (5)
'       boost_clkdiv: Set booster circuit clock frequency divisor
'           Setting     Booster circuit 1       Booster circuit 2, 4
'           BCLK1_1:    BCLK / 1                BCLK / 1
'           BCLK1_2:    BCLK / 1                BCLK / 2
'           BCLK1_4:    BCLK / 1                BCLK / 4
'           BCLK2_2:    BCLK / 2                BCLK / 2
'           BCLK2_4:    BCLK / 2                BCLK / 4
'           BCLK4_4:    BCLK / 4                BCLK / 4
'           BCLK4_8:    BCLK / 4                BCLK / 8
'           BCLK4_16:   BCLK / 4                BCLK / 16
    case mode
        3..5:
            mode -= 3
        OTHER:
            return FALSE

{    case Isource
        OFF, SMALL, MEDLOW, MED, MEDHI, LARGE:
        OTHER:
            return FALSE

    case boost_clkdiv
        BCLK1_1, BCLK1_2, BCLK1_4, BCLK2_2, BCLK2_4, BCLK4_4, BCLK4_8, BCLK4_16:
        OTHER:
            return FALSE
}
    writeReg(core#PWCTR3 + mode, 2, @Isource)

PUB PowerControl1(AVDD, GVDD, GVCL, mode) | tmp
' Set LCD supply voltages, in millivolts
'   Valid values:
'       AVDD: 4_500..5_100, in increments of 100 (default: 4_900)
'       GVDD: 3_150..4_700, in increments of 50 (default: 4_600)
'       GVCL: -4_700..-3_150, in increments of 50 (default: -4_600)
'       mode: 2, 3, AUTO (0) (default: AUTO)
'   Any other value is ignored
    case AVDD
        4_500..5_100:
            AVDD := ((AVDD / 100) - 45) << core#FLD_AVDD
        OTHER:
            return FALSE

    case GVDD
        3_150..4_700:
            GVDD := ((4_700 - GVDD) / 50) & core#BITS_VRHP
        OTHER:
            return FALSE

    case GVCL
        -4_700..-3_150:
            GVCL := ((4_700 - (GVCL * -1) ) / 50) & core#BITS_VRHN
        OTHER:
            return FALSE

    case mode
        2, 3, AUTO:
            mode := lookdownz(mode: 2, 3, AUTO) << core#FLD_MODE
            mode |= %000100

    tmp.byte[0] := AVDD | GVDD
    tmp.byte[1] := GVCL
    tmp.byte[2] := mode

    writeReg(core#PWCTR1, 3, @tmp)

PUB PowerControl2(V25, VGH, VGL) | tmp
' Set LCD supply voltages, in millivolts
'   Valid values:
'       V25: 2_100, 2_200, 2_300, 2_400 (default: 2_400)
'       VGH: AVDD_X2_VGH25 (0), AVDD_X3 (1), AVDD_X3_VGH25 (2) (default: AVDD3X)
'       VGL: -13_000, -12_500, -10_000, -7_500 (default: -10_000)
    case V25
        2_100, 2_200, 2_300, 2_400:
            V25 := lookdownz(V25: 2_100, 2_200, 2_300, 2_400) << core#FLD_VGH25
        OTHER:
            return FALSE

    case VGH
        AVDD_X2_VGH25, AVDD_X3, AVDD_X3_VGH25:
            VGH := lookdownz(VGH: AVDD_X2_VGH25, AVDD_X3, AVDD_X3_VGH25) & core#BITS_VGHBT
        OTHER:
            return FALSE

    case VGL
        -13_000, -12_500, -10_000, -7_500:
            VGL := lookdownz(VGL: -7_500, -10_000, -12_500, -13_000) << core#FLD_VGLSEL
        OTHER:
            return FALSE

    tmp := V25 | VGH | VGL

    writeReg(core#PWCTR2, 1, @tmp)

PUB SubpixelOrder(order) | tmp
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    tmp := $00
    tmp := _madctl
    case order
        0, 1:
            order <<= core#FLD_RGB
        OTHER:
            result := (tmp >> core#FLD_RGB) & %1
            return

    _madctl &= core#MASK_RGB
    _madctl := (_madctl | order) & core#MADCTL_MASK
    writeReg(core#MADCTL, 1, @_madctl)

PUB Update | tmp
' Write the draw buffer to the display
    writeReg(core#RAMWR, _buff_sz, _ptr_framebuffer)

{
PRI readReg(reg, nr_bytes, buff_addr) | tmp         ' * Not possible on Adafruit breakout boards, possibly others
' Read nr_bytes from register 'reg' to address 'buf_addr'

' Handle quirky registers on a case-by-case basis
    case reg
        core#RDDID:
            io.Low(_DC)
            io.Low(_CS)
            spi.ShiftOut(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)'d, c, m, b, v)
            io.High(_DC)
            spi.ShiftIn(_SDA, _SCK, core#MISO_BITORDER, 8) ' Dummy read
            repeat tmp from 0 to 2
                byte[buff_addr][tmp] := spi.ShiftIn(_SDA, _SCK, core#MISO_BITORDER, 8)
            io.High(_CS)
        OTHER:

{
    io.Low(_CS)
    spi.SHIFTOUT(_SDA, _SCK, core#SDA_BITORDER, 8, reg)

    repeat i from 0 to nr_bytes-1
        byte[buf_addr][i] := spi.SHIFTIN(_SDA, _SCK, core#SDA_BITORDER, 8)
    io.High(_CS)
}
}

PRI writeReg(reg, nr_bytes, buff_addr)
' Write nr_bytes to register 'reg' stored at buf_addr
    case reg
        $00, $01, $11, $12, $13, $20, $21, $28, $29, $38, $39:         ' One byte command, no params
            io.Low(_DC)                                 ' D/C = Command
            spi.Write(TRUE, @reg, 1, TRUE)              ' Write reg, raise CS after
            return

        core#RAMWR:
            io.Low(_DC)                                 ' D/C = Command
            spi.Write(TRUE, @reg, 1, FALSE)             ' Write reg, leave CS low after
            io.High(_DC)                                ' D/C = Data
            spi.Write(TRUE, buff_addr, nr_bytes, TRUE)  ' Write data, raise CS after
            return

        $2A..$2C, $30, $36, $3A, $B1..$B4, $B6, $C0..$C5, $E0, $E1, $FC:
            io.Low(_DC)                                 ' D/C = Command
            spi.Write(TRUE, @reg, 1, FALSE)             ' Write reg, leave CS low after
            io.High(_DC)                                ' D/C = Data
            spi.Write(TRUE, buff_addr, nr_bytes, TRUE)  ' Write data, raise CS after
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
