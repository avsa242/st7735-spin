{
    --------------------------------------------
    Filename: ST7735-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ST7735 driver
    Copyright (c) 2020
    Started Mar 07, 2020
    Updated Mar 08, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

    CS          = 0
    DC          = 1
    RST         = 2
    SDA         = 3
    SCK         = 4

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    WIDTH       = 128
    HEIGHT      = 128
    BUFFSZ_BYTES= (WIDTH * HEIGHT)' * 3
    BUFFSZ_WORDS= BUFFSZ_BYTES/2

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    st7735  : "display.lcd.st7735.spi"
    fnt     : "font.5x8"

VAR

    word _framebuff[BUFFSZ_WORDS]
    byte _ser_cog

PUB Main | x, y

    Setup
    st7735.BGColor($0000)
    st7735.FGColor($FFFF)
    st7735.Clear
    st7735.Update

    y := 63
    repeat x from 0 to 127
        st7735.Line(x, 0, x, y, x << 3)

    st7735.Line(0, 0, 127, 63, $FFFF)
    st7735.Line(127, 0, 0, 63, $FFFF)
    st7735.Circle(64, 32, 32, $1F00)
    st7735.Box(0, 0, 127, 63, $FF00, FALSE)
    st7735.Position(0, 0)
    st7735.Str(string("Ready."))

    st7735.Update
    FlashLED(LED, 100)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if st7735.Start(CS, SCK, SDA, DC, RST, @_framebuff)
        ser.str(string("ST7735 driver started", ser#CR, ser#LF))
        st7735.FontAddress(fnt.BaseAddr)
        st7735.FontSize(6, 8)
        st7735.Defaults
    else
        ser.str(string("ST7735 driver failed to start - halting", ser#CR, ser#LF))
        st7735.Stop
        time.MSleep(5)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

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
