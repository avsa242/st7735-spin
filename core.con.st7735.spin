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
    SCK_MAX_FREQ                = 15_151_515
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
    MADCTL_MASK                 = $FC
        FLD_MY                  = 7
        FLD_MX                  = 6
        FLD_MV                  = 5
        FLD_ML                  = 4
        FLD_RGB                 = 3
        FLD_MH                  = 2
        MASK_MY                 = MADCTL_MASK ^ (1 << FLD_MY)
        MASK_MX                 = MADCTL_MASK ^ (1 << FLD_MX)
        MASK_MV                 = MADCTL_MASK ^ (1 << FLD_MV)
        MASK_ML                 = MADCTL_MASK ^ (1 << FLD_ML)
        MASK_RGB                = MADCTL_MASK ^ (1 << FLD_RGB)
        MASK_MH                 = MADCTL_MASK ^ (1 << FLD_MH)

    IDMOFF                      = $38
    IDMON                       = $39

    COLMOD                      = $3A
    COLMOD_MASK                 = $07
        FLD_IFPF                = 0
        BITS_IFPF               = %111

    FRMCTR1                     = $B1
        FLD_RTNA                = 0
        FLD_FPA                 = 0
        FLD_BPA                 = 0
        BITS_RTNA               = %1111
        BITS_FPA                = %111111
        BITS_BPA                = %111111

    FRMCTR2                     = $B2

    FRMCTR3                     = $B3

    INVCTR                      = $B4
        FLD_NL                  = 0
        FLD_NLC                 = 0
        FLD_NLB                 = 1
        FLD_NLA                 = 2

    DISSET5                     = $B6
        FLD_EQ                  = 0
        FLD_SDT                 = 2
        FLD_NO                  = 4
        FLD_PT                  = 0
        FLTD_PTG                = 2
        BITS_EQ                 = %11
        BITS_SDT                = %11
        BITS_NO                 = %11
        BITS_PT                 = %11
        BITS_PTG                = %11

    PWCTR1                      = $C0

    PWCTR2                      = $C1

    PWCTR3                      = $C2

    PWCTR4                      = $C3

    PWCTR5                      = $C4

    VMCTR1                      = $C5

    RDID1                       = $DA
    RDID2                       = $DB
    RDID3                       = $DC

    GMCTRP1                     = $E0

    GMCTRN1                     = $E1

    PWCTR6                      = $FC

PUB Null
' This is not a top-level object
