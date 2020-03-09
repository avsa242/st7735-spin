{
    --------------------------------------------
    Filename: display.lcd.st7735.spi.spin
    Author: Jesse Burt
    Description: Driver for Sitronix ST7735-based displays (4W SPI)
    Copyright (c) 2020
    Started Mar 07, 2020
    Updated Mar 08, 2020
    See end of file for terms of use.
    --------------------------------------------
}
#define ST7735
#include "lib.gfx.bitmap.spin"

CON

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

VAR

    long _draw_buffer
    word _buff_sz
    byte _CS, _SDA, _SCK, _RESET, _DC
    byte _disp_width, _disp_height, _disp_xmax, _disp_ymax
'   Shadow registers
    byte _colmod, _madctl

OBJ

    spi : "com.spi.4w"                                             'PASM SPI Driver
    core: "core.con.st7735"
    time: "time"
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RESET_PIN, drawbuffer_address): okay
    if okay := spi.start (core#SCK_DELAY, core#CPOL)        'SPI Object Started?
        time.MSleep (1)                                     'Add startup delay appropriate to your device (consult its datasheet)
        _CS := CS_PIN
        _SDA := SDA_PIN
        _SCK := SCK_PIN
        _RESET := RESET_PIN
        _DC := DC_PIN

        io.High(_CS)
        io.Output(_CS)
        io.High(_RESET)
        io.Output(_RESET)
        io.High(_DC)
        io.Output(_DC)

        _disp_width := 128
        _disp_height := 128
        _disp_xmax := _disp_width-1
        _disp_ymax := _disp_height-1
        _buff_sz := (_disp_width * _disp_height)' * 3 ' too big for P1 RAM
'        Reset
        Address(drawbuffer_address)
        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    'Powered(FALSE)
    spi.Stop

PUB Defaults | tmp[4]

'rcmd1
    writeReg(core#SOFT_RESET, 0, 0)
    time.MSleep(150)

    writeReg(core#SLPOUT, 0, 0)
    time.MSleep(500)

    tmp.byte[0] := $01
    tmp.byte[1] := $2c
    tmp.byte[2] := $2d
    writeReg(core#FRMCTR1, 3, @tmp)

    tmp.byte[0] := $01
    tmp.byte[1] := $2c
    tmp.byte[2] := $2d
    writeReg(core#FRMCTR2, 3, @tmp)

    tmp.byte[0] := $01
    tmp.byte[1] := $2c
    tmp.byte[2] := $2d
    tmp.byte[3] := $01
    tmp.byte[4] := $2c
    tmp.byte[5] := $2d
    writeReg(core#FRMCTR3, 6, @tmp)

    tmp := $07
    writeReg(core#INVCTR, 1, @tmp)

    tmp.byte[0] := $a2
    tmp.byte[1] := $02
    tmp.byte[2] := $84
    writeReg(core#PWCTR1, 3, @tmp)

    tmp := $c5
    writeReg(core#PWCTR2, 1, @tmp)

    PowerControl(3, $0A, $00)
    PowerControl(4, $8A, $2A)
    PowerControl(5, $8A, $EE)

    VCOMVoltage(2_850, -0_575)
    DisplayInverted(FALSE)

    MirrorH(TRUE)
    MirrorV(TRUE)
    SubpixelOrder(BGR)

    ColorDepth(16)
    DisplayBounds(2, 3, 129, 129)   '00 02 00 7F+02  00 03 00 9F+01

'part3 red/green tab
    GammaTableP(@gammatable_pos)
    GammaTableN(@gammatable_neg)

    PartialDisplay(FALSE)
    DisplayVisible(TRUE)


PUB Address(addr)

    _draw_buffer := addr

PUB ClearAccel

    return 0

PUB ColorDepth(format) | tmp
' Set color depth/format, in bits per pixel
'   Valid values: 12, 16, 18
'   Any other value returns the current setting
    tmp := $00
    case format
        12, 16, 18:
            format := lookdown(format: 0, 0, 12, 0, 16, 18)
        OTHER:
            return _colmod & core#BITS_IFPF

    writeReg(core#COLMOD, 1, @format)

{
PUB DeviceID

    readReg(core#RDDID, 3, @result)
}

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

PUB DisplayInverted(enabled)
' Invert display colors
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#INVOFF, core#INVON)
        OTHER:
            return FALSE

    writeReg(enabled, 0, 0)

PUB DisplayVisible(enabled)
' Enable display visiblity
'   NOTE: Doesn't affect display RAM contents.
'   NOTE: There is a mandatory 120ms delay imposed by calling this method
    case ||enabled
        0, 1:
            enabled := ||enabled + core#DISPOFF
        OTHER:
            return FALSE

    writeReg(enabled, 0, 0)
    time.MSleep(120)

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

PUB PartialDisplay(enabled)
' Enable partial display
    case ||enabled
        0, 1:
            enabled := (1 - ||enabled) + core#NORON
        OTHER:
            return FALSE

    writeReg(enabled, 0, 0)

{
PUB Powered(enabled) | tmp
'120ms between states
'sleep in $10 when using display off
}

PUB Reset
' Reset the display controller
    io.Low(_RESET)
    time.USleep(10)
    io.High(_RESET)
    time.MSleep(5)

PUB PowerControl(opmode, Isource, boost_clkdiv) | tmp
' Set partial mode/full-colors power control
'   Valid values:
'       opmode: Settings applied to operating mode
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
    case opmode
        3..5:
            opmode -= 3
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
    writeReg(core#PWCTR3 + opmode, 2, @Isource)

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

    writeReg(core#RAMWR, _buff_sz, _draw_buffer)

PUB VCOMVoltage(high_mV, low_mV)
' Set VCOM high and low voltage levels, in millivolts
'   Valid values:
'       high_mV: 2_500..5_000 (in increments of 25mV)   Default: 4_525
'       low_mV: -2_400..0_000 (in increments of 25mV)   Default: -0_575
'   NOTE: Values are rounded to the nearest 25mV
    case high_mV
        2_500..5_000:
            high_mV := (high_mV / 25) - 100
        OTHER:
            return FALSE

    case low_mv
        -2_400..0:
            low_mV := (low_mV / 25) + 100
        OTHER:
            return FALSE

    writeReg(core#VMCTR1, 2, @high_mV)

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

PRI writeReg(reg, nr_bytes, buff_addr) | i
' Write nr_bytes to register 'reg' stored at buf_addr
    case reg
        $00, $01, $11, $13, $20, $21, $28, $29:          ' One byte command, no params
            io.Low(_DC)                             ' D/C = Command
            io.Low(_CS)
            spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)
            io.High(_CS)
            return

        core#RAMWR:
            io.Low(_DC)                             ' D/C = Command
            io.Low(_CS)
            spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)

            io.High(_DC)                            ' D/C = Data
'            repeat i from 0 to (nr_bytes/2)-1
'                spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 16, word[buff_addr][i])
            repeat i from 0 to nr_bytes-1
                spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
            io.High(_CS)
            return

        $2A..$2C, $36, $3A, $B1..$B4, $B6, $C0..$C5, $E0, $E1, $FC:
            io.Low(_DC)                             ' D/C = Command
            io.Low(_CS)
            spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)

            io.High(_DC)                            ' D/C = Data
            repeat i from 0 to nr_bytes-1
                spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
            io.High(_CS)
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
