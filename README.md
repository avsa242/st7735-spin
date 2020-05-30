# st7735-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Sitronix ST7735-based TFT-LCD displays

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 20MHz (P1), 20MHz (P2) (Max spec is 15MHz but this isn't enforced. YMMV). 4-wire SPI: CS, SCL, SDA, DC, w/RESET
* Integration with the generic bitmap graphics library
* Display mirroring
* Control display visibility (independent of display RAM contents)
* Set subpixel order
* Set color depth (12, 16, 18-bit can be set; currently only 16-bit supported by driver)

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.10-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* P1 has insufficient RAM to buffer the entire display
* Currently developed using ST7735R-based display (Adafruit 1.44" #2088); _may_ work with other ST7735 variants
* Reading from display not currently supported

## TODO

- [x] Port to P2/SPIN2
- [x] Use the 20MHz SPI driver for the P1
- [ ] Add some direct-draw methods to the driver for apps that don't need a full buffered display
- [ ] Add optional backlight pin to enable backlight control (PWM)
- [ ] Test external memory options with driver
