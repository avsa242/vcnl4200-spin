{
    --------------------------------------------
    Filename: core.con.vcnl4200.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2021
    Started Feb 07, 2021
    Updated Feb 09, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ    = 400_000                   ' device max I2C bus freq
    SLAVE_ADDR      = $51 << 1                  ' 7-bit format slave address
    T_POR           = 2_500                     ' startup time (usecs)

    DEVID           = ID
    DEVID_RESP      = $1058                     ' device ID expected response

' Register definitions
    ALS_CONF            = $00
    ALS_CONF_MASK       = $01EF
        ALS_IT          = 6
        ALS_INT_SW      = 5
        ALS_PERS        = 2
        ALS_INT_EN      = 1
        ALS_SD          = 0
        ALS_IT_BITS     = %11
        ALS_PERS_BITS   = %11
        ALS_IT_MASK     = (ALS_IT_BITS << ALS_IT) ^ ALS_CONF_MASK
        ALS_INT_SW_MASK = (1 << ALS_INT_SW) ^ ALS_CONF_MASK
        ALS_PERS_MASK   = (ALS_PERS_BITS << ALS_PERS) ^ ALS_CONF_MASK
        ALS_INT_EN_MASK = (1 << ALS_INT_EN) ^ ALS_CONF_MASK
        ALS_SD_MASK     = 1 ^ ALS_CONF_MASK
        IDD_RSVD        = 1 << 8
        ALS_OFF         = 1

    ALS_THDH            = $01

    ALS_THDL            = $02

    PS_CONF1            = $03
    PS_CONF1_MASK       = $0BFF
        PS_HD           = 11                    ' PS_CONF2
        PS_INT          = 8                     '
        PS_DUTY         = 6
        PS_PERS         = 4
        PS_IT           = 1
        PS_SD           = 0
        PS_INT_BITS     = %11                   ' PS_CONF2
        PS_DUTY_BITS    = %11
        PS_PERS_BITS    = %11
        PS_IT_BITS      = %11
        PS_HD_MASK      = (1 << PS_HD) ^ PS_CONF1_MASK              ' PS_CONF2
        PS_INT_MASK     = (PS_INT_BITS << PS_INT) ^ PS_CONF1_MASK   '
        PS_DUTY_MASK    = (PS_DUTY_BITS << PS_DUTY) ^ PS_CONF1_MASK
        PS_PERS_MASK    = (PS_PERS_BITS << PS_PERS) ^ PS_CONF1_MASK
        PS_IT_MASK      = (PS_IT_BITS << PS_IT) ^ PS_CONF1_MASK
        PS_SD_MASK      = 1 ^ PS_CONF1_MASK
        PS_OFF          = 1

    PS_CONF3            = $04
    PS_CONF3_MASK       = $3F7F
        PS_MS           = 13
        PS_SP           = 12
        PS_SPO          = 11
        LED_I           = 8
        PS_MPS          = 5
        PS_SM_PERS      = 4
        PS_AF           = 3
        PS_TRIG         = 2
        PS_SC_ADV       = 1
        PS_SC_EN        = 0
        LED_I_BITS      = %111
        PS_MPS_BITS     = %11
        PS_SC_BITS      = %11
        PS_MS_MASK      = (1 << PS_MS) ^ PS_CONF3_MASK
        PS_SP_MASK      = (1 << PS_SP) ^ PS_CONF3_MASK
        PS_SPO_MASK     = (1 << PS_SPO) ^ PS_CONF3_MASK
        LED_I_MASK      = (LED_I_BITS << LED_I) ^ PS_CONF3_MASK
        PS_MPS_MASK     = (PS_MPS_BITS << PS_MPS) ^ PS_CONF3_MASK
        PS_SM_PERS_MASK = (1 << PS_SM_PERS) ^ PS_CONF3_MASK
        PS_AF_MASK      = (1 << PS_AF) ^ PS_CONF3_MASK
        PS_TRIG_MASK    = (1 << PS_TRIG) ^ PS_CONF3_MASK
        PS_SC_ADV_MASK  = (1 << PS_SC_ADV) ^ PS_CONF3_MASK
        PS_SC_EN_MASK   = (1 << PS_SC_EN) ^ PS_CONF3_MASK
        PS_SC_MASK      = PS_SC_BITS ^ PS_CONF3_MASK

    PS_CANC         = $05

    PS_THDL         = $06
    PS_THDH         = $07

    PS_DATA         = $08
    ALS_DATA        = $09
    WHITE_DATA      = $0A

' $0B..$0D_LSB: RESERVED

    INT_FLAG        = $0D
        PS_UPFLAG   = 7
        PS_SPFLAG   = 6
        ALS_IF_L    = 5
        ALS_IF_H    = 4
        PS_IF_CLOSE = 1
        PS_IF_AWAY  = 0

    ID              = $0E

PUB Null{}
' This is not a top-level object

