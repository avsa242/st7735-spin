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

* Presence of bitmap graphics library (lib.gfx.bitmap)

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.7-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.7-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Hardware compatibility

* Developed using ST7735-based (non-R suffix) display (Adafruit 1.44" #2088); _may_ work with other ST7735 variants (unfortunately there seem to be several)

## Limitations

* Reading from display not currently supported

