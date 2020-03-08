{
    --------------------------------------------
    Filename: core.con.st7735.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Mar 07, 2020
    Updated Mar 07, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0
    SCK_DELAY                   = 1
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 0             'MSBPRE

' Register definitions
    NOOP                        = $00
    SOFT_RESET                  = $01
    RDDID                       = $04
    RDDST                       = $09
    RDDPM                       = $0A
    RDD_MADCTL                  = $0B
    RDD_COLMOD                  = $0C
    RDDIM                       = $0D
    RDDSM                       = $0E
    SLPIN                       = $10
    SLPOUT                      = $11
    PTLON                       = $12
    NORON                       = $13
    INVOFF                      = $20
    INVON                       = $21
    GAMSET                      = $26
    DISPOFF                     = $28
    DISPON                      = $29
    CASET                       = $2A
    RASET                       = $2B
    RAMWR                       = $2C
    RAMRD                       = $2E
    PTLAR                       = $30
    TEOFF                       = $34
    TEON                        = $35
    MADCTL                      = $36
    IDMOFF                      = $38
    IDMON                       = $39
    COLMOD                      = $3A
    RDID1                       = $DA
    RDID2                       = $DB
    RDID3                       = $DC

PUB Null
' This is not a top-level object
