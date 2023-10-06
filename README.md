# st7735-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Sitronix ST77xx-based TFT-LCD displays

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* 4-wire SPI connection (CS, SCL, SDA, DC) at 20MHz (P1), 20MHz+ (P2).
* Optional RESET hardware pin support
* Integration with the generic bitmap graphics library
* Build-time choice of buffered or unbuffered display (P2 only; P1 is always bufferless)
* Display mirroring, rotation
* Control display visibility (independent of display RAM contents)
* Set subpixel order (RGB, BGR)
* Set color depth (see limitations below)

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM SPI engine
* graphics.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.5.0)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.5.0)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.5.0)       | NuCode       | FTBFS                 |
| P2        | SPIN2    | FlexSpin (6.5.0)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are not supported, and _may or may not_ work)

## Hardware compatibility

Tested with:
* ST7735R: Adafruit 1.44" (#2088), 128x128
* ST7789VW: Adafruit 1.3" (#4313), 240x240

## Limitations

* Reading from display not currently supported
* Buffered display mode isn't supported on the P1 due to memory constraints
* Color depths of 12, 16 or 18-bits can be set, but only 16bpp is currently actually supported

