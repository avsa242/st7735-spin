# st7735-spin 
-------------

This is a P8X32A/Propeller driver object for Sitronix ST7735-based TFT-LCD displays

## Salient Features

* SPI connection at up to 1MHz (4W: CS, SCL, SDA, DC, w/RESET))
* Integration with the generic bitmap graphics library

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM I2C driver

## Compiler Compatibility

* OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* P1 has insufficient RAM to buffer the entire display

## TODO

- [ ] Port to P2/SPIN2
- [ ] Use the 20MHz SPI driver for the P1
- [ ] Add some direct-draw methods to the driver for apps that don't need a full buffered display
- [ ] Add optional backlight pin to enable backlight control (PWM)
