{
    --------------------------------------------
    Filename: display.lcd.st7735.spi.spin
    Author:
    Description:
    Copyright (c) 2020
    Started Mar 07, 2020
    Updated Mar 07, 2020
    See end of file for terms of use.
    --------------------------------------------
}
#define ST7735
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR           = 65535

VAR

    long _draw_buffer
    word _buff_sz
    byte _CS, _SDA, _SCK, _RESET, _DC
    byte _disp_width, _disp_height
    word _fb[8192]

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
        _buff_sz := (_disp_width * _disp_height) * 3
        Reset
        Address(drawbuffer_address)
        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    'Powered(FALSE)
    spi.Stop

PUB Address(addr)

    _draw_buffer := addr

PUB ClearAccel

PUB DeviceID

    readReg(core#RDDID, 3, @result)

PUB Powered(enabled) | tmp
'120ms between states
'sleep in $10 when using display off
PUB Reset
' Reset the display controller
    io.Low(_RESET)
    time.USleep(10)
    io.High(_RESET)
    time.MSleep(5)

PUB testp | xs, xe, ys, ye, l1, xc, yc, black, i

    xs := ys := 0
    xe := ye := 127
    writeReg(core#SLPOUT, 0, 0)
    time.MSleep(500)
    writeReg(core#NORON, 0, 0)
    writeReg(core#DISPON, 0, 0)
    xc.byte[0] := xs.byte[1]
    xc.byte[1] := xs.byte[0]
    xc.byte[2] := xe.byte[1]
    xc.byte[3] := xs.byte[0]
    yc.byte[0] := ys.byte[1]
    yc.byte[1] := ys.byte[0]
    yc.byte[2] := ye.byte[1]
    yc.byte[3] := ye.byte[0]
    black := $00
    l1 := $1111

    bytefill(@_fb, $00, 16384)
    _fb[2] := l1.word[0]
    writeReg(core#CASET, 4, @xc)
    writeReg(core#RASET, 4, @yc)
    writeReg(core#RAMWR, 16384, @_fb)
    
PUB Update

PRI readReg(reg, nr_bytes, buff_addr) | tmp         ' * Not possible on Adafruit breakout boards
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
PRI writeReg(reg, nr_bytes, buff_addr) | i
' Write nr_bytes to register 'reg' stored at buf_addr
    case reg
        $00, $11, $13, $20, $21, $28, $29:
            io.Low(_DC)                             ' D/C = Command
            io.Low(_CS)
            spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)
            io.High(_CS)
            return

        $2A..$2C:
            io.Low(_DC)                             ' D/C = Command
            io.Low(_CS)
            spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, reg)

            io.High(_DC)                            ' D/C = Data
            repeat i from 0 to nr_bytes-1
                spi.SHIFTOUT(_SDA, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
            io.High(_CS)
            return

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
