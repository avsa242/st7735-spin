# st7735-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Sitronix ST7735-based TFT-LCD displays

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 20MHz (P1), 20MHz (P2) (Max spec is 15MHz but this isn't enforced. YMMV). 4-wire SPI: CS, SCL, SDA, DC, w/RESET
* Integration with the generic bitmap graphics library
* Buffered and unbuffered display support (compile-time choice)
* Display mirroring, rotation
* Control display visibility (independent of display RAM contents)
* Set subpixel order
* Set color depth (12, 16, 18-bit can be set; currently only 16-bit supported by driver)

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM SPI engine
* graphics.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | Untested              |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Hardware compatibility

* Developed using ST7735-based (non-R suffix) display (Adafruit 1.44" #2088); _may_ work with other ST7735 variants (unfortunately there seem to be several)

## Limitations

* Reading from display not currently supported

